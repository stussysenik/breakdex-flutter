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

        export.exportAsynchronously {
            DispatchQueue.main.async {
                if export.status == .completed {
                    completion(outputURL, true)
                } else {
                    completion(fileURL, false)
                }
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

            if let existing = albumCollection {
                guard let changeReq = PHAssetCollectionChangeRequest(for: existing) else { return }
                albumChangeRequest = changeReq
            } else {
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
