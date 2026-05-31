import Flutter
import Foundation
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

private struct ImportedVideo {
    let localPath: String
    let originalFileName: String
    let creationDate: Date?
    let fileSize: Int64
    let duration: Double
}

final class NativeVideoImportPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, NativeCapability {
    static var channelName: String { "native_video_import" }
    static var eventChannelName: String? { "native_video_import_progress" }

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

    private func fetchPhotoLibraryVideos(result: @escaping FlutterResult) {
        // Run on background queue to avoid blocking main thread
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            // Only fetch strictly videos
            let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
            
            var assets: [[String: Any]] = []
            let df = ISO8601DateFormatter()
            
            fetchResult.enumerateObjects { (asset, index, stop) in
                // originalFilename can be slow. 
                // We'll use a placeholder if it's not prefetched, or just accept the cost on background thread.
                let resources = PHAssetResource.assetResources(for: asset)
                let preferredResource = resources.first {
                    $0.type == .video || $0.type == .fullSizeVideo || $0.type == .pairedVideo
                } ?? resources.first
                
                let originalFilename = preferredResource?.originalFilename ?? "Unknown"
                
                assets.append([
                    "localIdentifier": asset.localIdentifier,
                    "creationDate": asset.creationDate != nil ? df.string(from: asset.creationDate!) : nil,
                    "duration": asset.duration,
                    "originalFileName": originalFilename,
                    "width": asset.pixelWidth,
                    "height": asset.pixelHeight
                ])
                
                // Limit to 1000 most recent for performance
                if assets.count >= 1000 {
                    stop.pointee = true
                }
            }
            
            DispatchQueue.main.async {
                result(assets)
            }
        }
    }

    private func getAssetThumbnail(assetIdentifier: String, width: Int, height: Int, result: @escaping FlutterResult) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            result(FlutterError(code: "NOT_FOUND", message: "Asset not found", details: nil))
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        // Use opportunistic but ensure high quality is eventually delivered
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current
        
        // Use exact size to avoid unnecessary scaling
        let targetSize = CGSize(width: width, height: height)
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            if let image = image {
                // Fix for 'AlphaLast' opaque image warning:
                // Ensure the image is rendered without alpha if it's opaque.
                // Actually, jpegData already removes alpha, but the warning happens during internal save steps.
                // We'll use a lower compression quality for better speed/memory.
                if let data = image.jpegData(compressionQuality: 0.6) {
                    result(FlutterStandardTypedData(bytes: data))
                } else {
                    result(FlutterError(code: "DATA_FAILED", message: "JPEG conversion failed", details: nil))
                }
            } else {
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if !isDegraded {
                    result(FlutterError(code: "THUMB_FAILED", message: "Failed to load thumbnail", details: nil))
                }
            }
        }
    }

    private func importSpecificAsset(assetIdentifier: String, result: @escaping FlutterResult) {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            result(FlutterError(code: "NOT_FOUND", message: "Asset not found", details: nil))
            return
        }
        
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
            guard let urlAsset = avAsset as? AVURLAsset else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "IMPORT_FAILED", message: "Could not get URL for asset", details: nil))
                }
                return
            }
            
            do {
                let resources = PHAssetResource.assetResources(for: asset)
                let filename = resources.first?.originalFilename
                
                let imported = try self.copyToMovesDir(
                    url: urlAsset.url,
                    preferredOriginalFileName: filename,
                    creationDate: asset.creationDate
                )
                
                let df = ISO8601DateFormatter()
                DispatchQueue.main.async {
                    result([
                        "localPath": imported.localPath,
                        "originalFileName": imported.originalFileName,
                        "creationDate": imported.creationDate != nil ? df.string(from: imported.creationDate!) : nil,
                        "fileSize": imported.fileSize,
                        "duration": imported.duration
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "IMPORT_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickFromPhotos":
            runImport(result: result) {
                try await self.importFromPhotos()
            }
        case "fetchPhotoLibraryVideos":
            self.fetchPhotoLibraryVideos(result: result)
        case "getAssetThumbnail":
            guard let args = call.arguments as? [String: Any],
                  let id = args["identifier"] as? String,
                  let w = args["width"] as? Int,
                  let h = args["height"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing args", details: nil))
                return
            }
            self.getAssetThumbnail(assetIdentifier: id, width: w, height: h, result: result)
        case "importSpecificAsset":
            guard let args = call.arguments as? [String: Any],
                  let id = args["identifier"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
                return
            }
            self.importSpecificAsset(assetIdentifier: id, result: result)
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
                
                let df = ISO8601DateFormatter()
                result([
                    "localPath": imported.localPath,
                    "originalFileName": imported.originalFileName,
                    "creationDate": imported.creationDate != nil ? df.string(from: imported.creationDate!) : nil,
                    "fileSize": imported.fileSize,
                    "duration": imported.duration
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

    private func copyToMovesDir(
        url: URL,
        preferredOriginalFileName: String? = nil,
        creationDate: Date? = nil
    ) throws -> ImportedVideo {
        let filename = normalizedOriginalFilename(
            preferredOriginalFileName,
            fallbackURL: url
        )
        let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let movesDir = docs.appendingPathComponent("Moves", isDirectory: true)
        try FileManager.default.createDirectory(at: movesDir, withIntermediateDirectories: true)

        let destination = movesDir.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: url, to: destination)
        
        let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        let asset = AVURLAsset(url: destination)
        let duration = asset.duration.seconds
        
        print("[NativeVideoImport] Deterministic copy completed: \(filename), size=\(fileSize), duration=\(duration)")

        return ImportedVideo(
            localPath: destination.path,
            originalFileName: filename,
            creationDate: creationDate,
            fileSize: fileSize,
            duration: duration
        )
    }

    private func normalizedOriginalFilename(_ preferred: String?, fallbackURL: URL) -> String {
        let trimmedPreferred = preferred?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedPreferred, !trimmedPreferred.isEmpty {
            return trimmedPreferred
        }
        return fallbackURL.lastPathComponent
    }

    private struct ExtendedMetadata {
        let filename: String?
        let creationDate: Date?
    }

    private func extendedMetadata(for assetIdentifier: String?) -> ExtendedMetadata {
        guard let assetIdentifier else { return ExtendedMetadata(filename: nil, creationDate: nil) }
        let trimmedIdentifier = assetIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIdentifier.isEmpty else { return ExtendedMetadata(filename: nil, creationDate: nil) }

        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [trimmedIdentifier],
            options: nil
        )
        guard let asset = fetchResult.firstObject else {
            return ExtendedMetadata(filename: nil, creationDate: nil)
        }

        let resources = PHAssetResource.assetResources(for: asset)
        let preferredResource = resources.first {
            $0.type == .video || $0.type == .fullSizeVideo || $0.type == .pairedVideo
        } ?? resources.first

        let originalFilename = preferredResource?.originalFilename
        let trimmedFilename = originalFilename?.trimmingCharacters(in: .whitespacesAndNewlines)
        let filename = (trimmedFilename?.isEmpty == false) ? trimmedFilename : nil
        
        return ExtendedMetadata(filename: filename, creationDate: asset.creationDate)
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

            do {
                let meta = self.extendedMetadata(for: item.assetIdentifier)
                let imported = try self.copyToMovesDir(
                    url: url,
                    preferredOriginalFileName: meta.filename,
                    creationDate: meta.creationDate
                )
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

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes[.creationDate] as? Date
                let imported = try self.copyToMovesDir(
                    url: url,
                    creationDate: creationDate
                )
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
