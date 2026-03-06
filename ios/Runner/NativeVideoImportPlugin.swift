import Flutter
import Foundation
import PhotosUI
import UIKit
import UniformTypeIdentifiers

private struct ImportedVideo {
    let localPath: String
    let originalFileName: String
}

final class NativeVideoImportPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var activeResult: FlutterResult?
    private var filesContinuation: CheckedContinuation<ImportedVideo?, Error>?
    private var photosContinuation: CheckedContinuation<ImportedVideo?, Error>?
    private var eventSink: FlutterEventSink?
    private var progressObservation: NSKeyValueObservation?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/native_video_import",
            binaryMessenger: registrar.messenger()
        )
        let instance = NativeVideoImportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(
            name: "com.breakdex/native_video_import_progress",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        progressObservation?.invalidate()
        progressObservation = nil
        return nil
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickFromPhotos":
            runImport(result: result) {
                try await self.importFromPhotos()
            }
        case "pickFromFiles":
            runImport(result: result) {
                try await self.importFromFiles()
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func runImport(
        result: @escaping FlutterResult,
        operation: @escaping () async throws -> ImportedVideo?
    ) {
        Task { @MainActor in
            guard self.activeResult == nil else {
                result(FlutterError(
                    code: "BUSY",
                    message: "Another import is already in progress",
                    details: nil
                ))
                return
            }

            self.activeResult = result
            defer { self.activeResult = nil }

            do {
                let imported = try await operation()
                guard let imported else {
                    // User cancelled — return nil to Dart (no error)
                    result(nil)
                    return
                }
                result([
                    "localPath": imported.localPath,
                    "originalFileName": imported.originalFileName,
                ])
            } catch {
                let nsError = error as NSError
                result(FlutterError(
                    code: "IMPORT_FAILED",
                    message: nsError.localizedDescription,
                    details: ["domain": nsError.domain, "code": nsError.code]
                ))
            }
        }
    }

    @MainActor
    private func importFromPhotos() async throws -> ImportedVideo? {
        guard #available(iOS 14.0, *) else {
            throw NSError(
                domain: "NativeVideoImport",
                code: -100,
                userInfo: [NSLocalizedDescriptionKey: "Photo picker requires iOS 14 or newer"]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.photosContinuation = continuation

            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.selectionLimit = 1
            config.filter = .videos
            config.preferredAssetRepresentationMode = .current

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self

            guard let presenter = topViewController() else {
                self.photosContinuation = nil
                continuation.resume(throwing: NSError(
                    domain: "NativeVideoImport",
                    code: -101,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to find top view controller"]
                ))
                return
            }

            presenter.present(picker, animated: true)
        }
    }

    @MainActor
    private func importFromFiles() async throws -> ImportedVideo? {
        return try await withCheckedThrowingContinuation { continuation in
            self.filesContinuation = continuation

            // asCopy: true — iOS copies the file into our app's inbox and
            // returns a plain URL (no security-scoped access needed).
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.movie, .video],
                asCopy: true
            )
            picker.delegate = self
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true

            guard let presenter = topViewController() else {
                self.filesContinuation = nil
                continuation.resume(throwing: NSError(
                    domain: "NativeVideoImport",
                    code: -102,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to find top view controller"]
                ))
                return
            }

            presenter.present(picker, animated: true)
        }
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }

    /// Copies a video file into Documents/Moves/ with a unique UUID filename.
    /// Works with any readable URL — temp files from PHPicker, inbox copies
    /// from UIDocumentPicker(asCopy: true), etc.
    private func copyToMovesDir(url: URL) throws -> ImportedVideo {
        let filename = url.lastPathComponent
        let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let movesDir = docs.appendingPathComponent("Moves", isDirectory: true)
        try FileManager.default.createDirectory(at: movesDir, withIntermediateDirectories: true)

        let destination = movesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: url, to: destination)

        return ImportedVideo(localPath: destination.path, originalFileName: filename)
    }
}

@available(iOS 14.0, *)
extension NativeVideoImportPlugin: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let continuation = photosContinuation else { return }

        guard let item = results.first else {
            photosContinuation = nil
            continuation.resume(returning: nil)
            return
        }

        let provider = item.itemProvider
        let type = UTType.movie.identifier

        // loadFileRepresentation gives us a TEMPORARY URL that is deleted
        // the moment this closure returns. We must copy synchronously here.
        // The closure already runs on a background thread, so no dispatch needed.
        let progress = provider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.progressObservation?.invalidate()
                    self.progressObservation = nil
                    self.photosContinuation = nil
                    continuation.resume(throwing: error)
                }
                return
            }

            guard let url else {
                DispatchQueue.main.async {
                    self.progressObservation?.invalidate()
                    self.progressObservation = nil
                    self.photosContinuation = nil
                    continuation.resume(throwing: NSError(
                        domain: "NativeVideoImport",
                        code: -105,
                        userInfo: [NSLocalizedDescriptionKey: "No video URL returned from photo picker"]
                    ))
                }
                return
            }

            // CRITICAL: Copy inside this closure — url is invalidated when we return
            do {
                let imported = try self.copyToMovesDir(url: url)
                DispatchQueue.main.async {
                    self.progressObservation?.invalidate()
                    self.progressObservation = nil
                    self.photosContinuation = nil
                    continuation.resume(returning: imported)
                }
            } catch {
                DispatchQueue.main.async {
                    self.progressObservation?.invalidate()
                    self.progressObservation = nil
                    self.photosContinuation = nil
                    continuation.resume(throwing: error)
                }
            }
        }

        // KVO observe progress — send fraction through eventSink for Dart progress bar
        self.progressObservation?.invalidate()
        self.progressObservation = progress.observe(\.fractionCompleted, options: [.new]) { [weak self] _, change in
            guard let fraction = change.newValue else { return }
            DispatchQueue.main.async {
                self?.eventSink?(fraction)
            }
        }
    }
}

extension NativeVideoImportPlugin: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)

        guard let continuation = filesContinuation else { return }
        guard let url = urls.first else {
            filesContinuation = nil
            continuation.resume(throwing: NSError(
                domain: "NativeVideoImport",
                code: -106,
                userInfo: [NSLocalizedDescriptionKey: "No file selected"]
            ))
            return
        }

        // With asCopy: true the URL points to our inbox — safe to copy on any thread.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let imported = try self.copyToMovesDir(url: url)
                DispatchQueue.main.async {
                    self.filesContinuation = nil
                    continuation.resume(returning: imported)
                }
            } catch {
                DispatchQueue.main.async {
                    self.filesContinuation = nil
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        guard let continuation = filesContinuation else { return }
        filesContinuation = nil
        continuation.resume(returning: nil)
    }
}
