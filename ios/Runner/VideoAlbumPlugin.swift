import Flutter
import AVFoundation
import Photos
import UIKit

/// Saves exported video clips to a dated Photos album (e.g. "Breakdex 03-07-2026").
///
/// This plugin uses the write-only `PHPhotoLibrary.authorizationStatus(for: .addOnly)`
/// permission, which only requires `NSPhotoLibraryAddUsageDescription` — no full
/// library read access needed. The user sees a one-time "Allow Breakdex to add
/// photos to your library?" prompt.
///
/// **Dart channel:** `com.breakdex/video_album`
/// **Methods:** `saveToAlbum(videoPath:, albumName:)`
final class VideoAlbumPlugin: NSObject, FlutterPlugin, NativeCapability {
    static var channelName: String { "video_album" }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/video_album",
            binaryMessenger: registrar.messenger()
        )
        let instance = VideoAlbumPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveToAlbum":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let albumName = args["albumName"] as? String else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing videoPath or albumName",
                        details: nil
                    )
                )
                return
            }
            let assetTitle = args["assetTitle"] as? String
            let category = args["category"] as? String
            saveToAlbum(
                videoPath: videoPath,
                albumName: albumName,
                assetTitle: assetTitle,
                category: category,
                result: result
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Photos Library

    private func saveToAlbum(
        videoPath: String,
        albumName: String,
        assetTitle: String?,
        category: String?,
        result: @escaping FlutterResult
    ) {
        let fileURL = URL(fileURLWithPath: videoPath)
        guard FileManager.default.fileExists(atPath: videoPath) else {
            result(
                FlutterError(
                    code: "MISSING_FILE",
                    message: "Video file not found at \(videoPath)",
                    details: nil
                )
            )
            return
        }

        let assetFilename = semanticFilename(
            title: assetTitle,
            category: category,
            fileExtension: fileURL.pathExtension
        )

        // Request write-only authorization — no full library read needed.
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "PERMISSION_DENIED",
                            message: "Photo library write access denied",
                            details: nil
                        )
                    )
                }
                return
            }
            // Move the export + save chain to a background queue so the
            // passthrough re-mux doesn't block the main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                self?.prepareTaggedCopy(
                    fileURL: fileURL,
                    assetTitle: assetTitle,
                    category: category,
                    albumName: albumName
                ) { preparedURL, shouldCleanup in
                    self?.performSave(
                        fileURL: preparedURL,
                        originalFilename: assetFilename,
                        albumName: albumName,
                        shouldCleanup: shouldCleanup,
                        result: result
                    )
                }
            }
        }
    }

    private func prepareTaggedCopy(
        fileURL: URL,
        assetTitle: String?,
        category: String?,
        albumName: String,
        completion: @escaping (URL, Bool) -> Void
    ) {
        let caption = referenceCaption(
            title: assetTitle,
            category: category,
            albumName: albumName
        )
        let hasMetadata = !caption.isEmpty

        guard hasMetadata else {
            completion(fileURL, false)
            return
        }

        let asset = AVURLAsset(url: fileURL)
        guard let export = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            completion(fileURL, false)
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BreakdexAlbumCopies", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: tempDir,
                withIntermediateDirectories: true
            )
        } catch {
            completion(fileURL, false)
            return
        }

        let fileExtension = fileURL.pathExtension.isEmpty ? "mp4" : fileURL.pathExtension
        let outputURL = tempDir
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)

        let preferredTypes = [AVFileType.mp4, .mov]
        guard let outputType = preferredTypes.first(where: export.supportedFileTypes.contains) ??
                export.supportedFileTypes.first else {
            completion(fileURL, false)
            return
        }

        export.outputURL = outputURL
        export.outputFileType = outputType
        export.metadata = metadataItems(
            title: assetTitle,
            category: category,
            albumName: albumName
        )
        export.shouldOptimizeForNetworkUse = true

        // 15-second timeout: if the export stalls, cancel and fall back to
        // saving the original file without metadata tags.
        let timeoutWork = DispatchWorkItem { [weak export] in
            guard let export, export.status == .exporting || export.status == .waiting else { return }
            print("[VideoAlbumPlugin] Export timed out after 15s — cancelling and falling back to original file")
            export.cancelExport()
        }
        DispatchQueue.global(qos: .userInitiated).asyncAfter(
            deadline: .now() + 15,
            execute: timeoutWork
        )

        export.exportAsynchronously {
            timeoutWork.cancel()
            if export.status == .completed {
                completion(outputURL, true)
            } else {
                // Clean up the partial temp file on failure/cancellation.
                try? FileManager.default.removeItem(at: outputURL)
                completion(fileURL, false)
            }
        }
    }

    private func performSave(
        fileURL: URL,
        originalFilename: String,
        albumName: String,
        shouldCleanup: Bool,
        result: @escaping FlutterResult
    ) {
        var assetPlaceholder: PHObjectPlaceholder?

        PHPhotoLibrary.shared().performChanges({
            // 1. Create the video asset with a semantic filename.
            let assetRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = originalFilename
            assetRequest.addResource(with: .video, fileURL: fileURL, options: options)
            assetPlaceholder = assetRequest.placeholderForCreatedAsset

            // 2. Find or create the target album
            let albumCollection = self.fetchAlbum(named: albumName)
            let albumChangeRequest: PHAssetCollectionChangeRequest

            if let existing = albumCollection,
               let changeReq = PHAssetCollectionChangeRequest(for: existing) {
                albumChangeRequest = changeReq
            } else {
                if albumCollection != nil {
                    print("[VideoAlbumPlugin] Warning: could not create change request for existing album \"\(albumName)\" — falling back to creating a new album")
                }
                albumChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
                    withTitle: albumName
                )
            }

            // 3. Add the new asset to the album
            if let placeholder = assetPlaceholder {
                albumChangeRequest.addAssets([placeholder] as NSFastEnumeration)
            }
        }) { success, error in
            DispatchQueue.main.async {
                if shouldCleanup {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                if success {
                    result(nil)
                } else {
                    result(
                        FlutterError(
                            code: "SAVE_FAILED",
                            message: error?.localizedDescription ?? "Unknown error saving to album",
                            details: nil
                        )
                    )
                }
            }
        }
    }

    private func metadataItems(
        title: String?,
        category: String?,
        albumName: String
    ) -> [AVMetadataItem] {
        var items: [AVMetadataItem] = []
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category?.trimmingCharacters(in: .whitespacesAndNewlines)
        let referenceCaption = referenceCaption(
            title: trimmedTitle,
            category: trimmedCategory,
            albumName: albumName
        )

        if let trimmedTitle, !trimmedTitle.isEmpty {
            let commonTitle = AVMutableMetadataItem()
            commonTitle.identifier = .commonIdentifierTitle
            commonTitle.locale = .current
            commonTitle.value = trimmedTitle as NSString
            items.append(commonTitle)

            let quickTimeTitle = AVMutableMetadataItem()
            quickTimeTitle.identifier = .quickTimeMetadataDisplayName
            quickTimeTitle.locale = .current
            quickTimeTitle.value = trimmedTitle as NSString
            items.append(quickTimeTitle)
        }

        let description = [
            trimmedCategory,
            trimmedTitle == nil ? "Breakdex" : nil,
            "Saved from Breakdex",
        ]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")

        if !description.isEmpty {
            let commonDescription = AVMutableMetadataItem()
            commonDescription.identifier = .commonIdentifierDescription
            commonDescription.locale = .current
            commonDescription.value = description as NSString
            items.append(commonDescription)

            let quickTimeDescription = AVMutableMetadataItem()
            quickTimeDescription.identifier = .quickTimeMetadataDescription
            quickTimeDescription.locale = .current
            quickTimeDescription.value = description as NSString
            items.append(quickTimeDescription)
        }

        if !referenceCaption.isEmpty {
            let quickTimeComment = AVMutableMetadataItem()
            quickTimeComment.identifier = .quickTimeUserDataComment
            quickTimeComment.locale = .current
            quickTimeComment.value = referenceCaption as NSString
            items.append(quickTimeComment)

            let accessibilityDescription = AVMutableMetadataItem()
            accessibilityDescription.identifier = .quickTimeUserDataAccessibilityDescription
            accessibilityDescription.locale = .current
            accessibilityDescription.value = referenceCaption as NSString
            items.append(accessibilityDescription)
        }

        let author = AVMutableMetadataItem()
        author.identifier = .quickTimeUserDataAuthor
        author.locale = .current
        author.value = "Breakdex" as NSString
        items.append(author)

        return items
    }

    private func referenceCaption(
        title: String?,
        category: String?,
        albumName: String
    ) -> String {
        [
            labeledSegment("Move", value: title),
            labeledSegment("Category", value: category),
            labeledSegment("Album", value: albumName),
            "Source: Breakdex",
        ]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func labeledSegment(_ label: String, value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return "\(label): \(value)"
    }

    private func semanticFilename(
        title: String?,
        category: String?,
        fileExtension: String
    ) -> String {
        let parts = [title, category]
            .compactMap { value in
                value?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        let base = parts.isEmpty ? "Breakdex Clip" : parts.joined(separator: " - ")
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: " -_")
        )
        let sanitizedCharacters: [Character] = base.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(String(scalar)) : Character("-")
        }
        let sanitized = String(sanitizedCharacters)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -_"))
        let finalBase = sanitized.isEmpty ? "Breakdex Clip" : sanitized
        let ext = fileExtension.isEmpty ? "mp4" : fileExtension
        return "\(finalBase).\(ext)"
    }

    /// Fetch an existing user-created album by title, or nil if not found.
    private func fetchAlbum(named title: String) -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title == %@", title)
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: options
        ).firstObject
    }
}

final class ShareSheetPlugin: NSObject, FlutterPlugin, NativeCapability {
    static var channelName: String { "share_sheet" }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/share_sheet",
            binaryMessenger: registrar.messenger()
        )
        let instance = ShareSheetPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(
                FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing share sheet arguments",
                    details: nil
                )
            )
            return
        }

        switch call.method {
        case "shareText":
            guard let text = args["text"] as? String else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing text payload",
                        details: nil
                    )
                )
                return
            }

            presentShareSheet(
                items: [text],
                subject: args["subject"] as? String,
                args: args,
                result: result
            )

        case "shareFiles":
            guard let paths = args["paths"] as? [String], !paths.isEmpty else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing file paths",
                        details: nil
                    )
                )
                return
            }

            let urls = paths.map(URL.init(fileURLWithPath:))
            presentShareSheet(
                items: urls,
                subject: args["subject"] as? String,
                args: args,
                result: result
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func presentShareSheet(
        items: [Any],
        subject: String?,
        args: [String: Any],
        result: @escaping FlutterResult
    ) {
        DispatchQueue.main.async {
            guard let controller = Self.topViewController() else {
                result(
                    FlutterError(
                        code: "NO_CONTROLLER",
                        message: "Unable to find a view controller for share sheet presentation",
                        details: nil
                    )
                )
                return
            }

            let activityController = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )

            if let subject, !subject.isEmpty {
                activityController.setValue(subject, forKey: "subject")
            }

            if let popover = activityController.popoverPresentationController {
                popover.sourceView = controller.view
                popover.sourceRect = self.sourceRect(from: args, in: controller.view)
            }

            controller.present(activityController, animated: true) {
                result(nil)
            }
        }
    }

    private func sourceRect(from args: [String: Any], in view: UIView) -> CGRect {
        let fallback = CGRect(
            x: view.bounds.midX,
            y: view.bounds.midY,
            width: 1,
            height: 1
        )

        guard let x = args["originX"] as? Double,
              let y = args["originY"] as? Double,
              let width = args["originWidth"] as? Double,
              let height = args["originHeight"] as? Double else {
            return fallback
        }

        let candidate = CGRect(
            x: x,
            y: y,
            width: max(width, 1),
            height: max(height, 1)
        )

        let intersection = candidate.intersection(view.bounds)
        return intersection.isNull || intersection.isEmpty ? fallback : intersection
    }

    private static func topViewController(
        from controller: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = controller as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        if let presentedViewController = controller?.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return controller
    }
}
