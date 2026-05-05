import Flutter
import AVFoundation
import Photos
import UIKit

private struct TrackedManagedAsset {
    let moveId: String
    let assetLocalIdentifier: String
    let albumName: String

    init?(_ payload: [String: Any]) {
        guard let moveId = payload["moveId"] as? String,
              let assetLocalIdentifier = payload["assetLocalIdentifier"] as? String,
              let albumName = payload["albumName"] as? String else {
            return nil
        }

        let trimmedMoveId = moveId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAssetId = assetLocalIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAlbumName = albumName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMoveId.isEmpty,
              !trimmedAssetId.isEmpty,
              !trimmedAlbumName.isEmpty else {
            return nil
        }

        self.moveId = trimmedMoveId
        self.assetLocalIdentifier = trimmedAssetId
        self.albumName = trimmedAlbumName
    }
}

/// Saves exported video clips to a dated Photos album (e.g. "Breakdex 03-07-2026").
///
/// This plugin uses the write-only `PHPhotoLibrary.authorizationStatus(for: .addOnly)`
/// permission, which only requires `NSPhotoLibraryAddUsageDescription` — no full
/// library read access needed. The user sees a one-time "Allow Breakdex to add
/// photos to your library?" prompt.
///
/// **Dart channel:** `com.breakdex/video_album`
/// **Methods:** `saveToAlbum(videoPath:, albumName:)`
final class VideoAlbumPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, PHPhotoLibraryChangeObserver, NativeCapability {
    static var channelName: String { "video_album" }
    static var eventChannelName: String? { "video_album/stream" }

    private var eventSink: FlutterEventSink?
    private var observingPhotoLibrary = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/video_album",
            binaryMessenger: registrar.messenger()
        )
        let instance = VideoAlbumPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(
            name: "com.breakdex/video_album/stream",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    deinit {
        stopObservingPhotoLibrary()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        startObservingPhotoLibraryIfAuthorized()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopObservingPhotoLibrary()
        return nil
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard eventSink != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(["type": "libraryChanged"])
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestReadAccess":
            requestReadAccess(result: result)
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
        case "deleteManagedCopies":
            guard let args = call.arguments as? [String: Any],
                  let assetTitle = args["assetTitle"] as? String else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing assetTitle",
                        details: nil
                    )
                )
                return
            }
            let category = args["category"] as? String
            let fileExtension = args["fileExtension"] as? String
            let assetLocalIdentifier = args["assetLocalIdentifier"] as? String
            deleteManagedCopies(
                assetTitle: assetTitle,
                category: category,
                fileExtension: fileExtension,
                assetLocalIdentifier: assetLocalIdentifier,
                result: result
            )
        case "findMissingManagedAssets":
            guard let args = call.arguments as? [String: Any],
                  let identifiers = args["assetLocalIdentifiers"] as? [String] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing assetLocalIdentifiers",
                        details: nil
                    )
                )
                return
            }
            findMissingManagedAssets(
                assetLocalIdentifiers: identifiers,
                result: result
            )
        case "reconcileManagedAssets":
            guard let args = call.arguments as? [String: Any],
                  let payloads = args["trackedAssets"] as? [[String: Any]] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing trackedAssets",
                        details: nil
                    )
                )
                return
            }
            let source = (args["source"] as? String) ?? "manual"
            let trackedAssets = payloads.compactMap(TrackedManagedAsset.init)
            reconcileManagedAssets(
                trackedAssets: trackedAssets,
                source: source,
                result: result
            )
        case "discoverRecoverableManagedAssets":
            let args = call.arguments as? [String: Any]
            let albumPatterns = args?["albumPatterns"] as? [String] ?? []
            discoverRecoverableManagedAssets(
                albumPatterns: albumPatterns,
                result: result
            )
        case "restoreManagedAsset":
            guard let args = call.arguments as? [String: Any],
                  let assetLocalIdentifier = args["assetLocalIdentifier"] as? String else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing assetLocalIdentifier",
                        details: nil
                    )
                )
                return
            }
            restoreManagedAsset(
                assetLocalIdentifier: assetLocalIdentifier,
                result: result
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Photos Library

    private func requestReadAccess(result: @escaping FlutterResult) {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard currentStatus == .notDetermined else {
            startObservingPhotoLibraryIfAuthorized()
            DispatchQueue.main.async {
                result(self.authorizationStatusValue(currentStatus))
            }
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            self?.startObservingPhotoLibraryIfAuthorized()
            DispatchQueue.main.async {
                result(self?.authorizationStatusValue(status) ?? "unknown")
            }
        }
    }

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
                    result([
                        "assetLocalIdentifier": assetPlaceholder?.localIdentifier ?? "",
                        "filename": originalFilename,
                        "albumName": albumName,
                    ])
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

    private func deleteManagedCopies(
        assetTitle: String,
        category: String?,
        fileExtension: String?,
        assetLocalIdentifier: String?,
        result: @escaping FlutterResult
    ) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "PERMISSION_DENIED",
                            message: "Photo library read/write access denied",
                            details: nil
                        )
                    )
                }
                return
            }

            guard let self else {
                DispatchQueue.main.async { result(nil) }
                return
            }

            let trimmedTitle = assetTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCategory = category?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedExt = self.normalizedFileExtension(fileExtension)
            let candidateFilenames = Set([
                self.semanticFilename(
                    title: trimmedTitle,
                    category: trimmedCategory,
                    fileExtension: normalizedExt
                ),
                self.semanticFilename(
                    title: trimmedTitle,
                    category: trimmedCategory,
                    fileExtension: "mp4"
                ),
                self.semanticFilename(
                    title: trimmedTitle,
                    category: trimmedCategory,
                    fileExtension: "mov"
                ),
            ])

            let albums = self.fetchBreakdexAlbums()
            var matchingAssets = self.findAssets(
                in: albums,
                matchingLocalIdentifier: assetLocalIdentifier
            )
            if matchingAssets.isEmpty {
                matchingAssets = self.findAssets(
                    in: albums,
                    matchingFilenames: candidateFilenames
                )
            }

            guard !matchingAssets.isEmpty else {
                DispatchQueue.main.async { result(nil) }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(matchingAssets as NSFastEnumeration)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        result(nil)
                    } else {
                        result(
                            FlutterError(
                                code: "DELETE_FAILED",
                                message: error?.localizedDescription ?? "Unknown error deleting album copies",
                                details: nil
                            )
                        )
                    }
                }
            }
        }
    }

    private func findMissingManagedAssets(
        assetLocalIdentifiers: [String],
        result: @escaping FlutterResult
    ) {
        let normalizedIdentifiers = Array(
            Set(
                assetLocalIdentifiers
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        if normalizedIdentifiers.isEmpty {
            DispatchQueue.main.async {
                result([
                    "accessStatus": self.authorizationStatusValue(
                        PHPhotoLibrary.authorizationStatus(for: .readWrite)
                    ),
                    "missingAssetLocalIdentifiers": [],
                ])
            }
            return
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            DispatchQueue.main.async {
                result([
                    "accessStatus": self.authorizationStatusValue(status),
                    "missingAssetLocalIdentifiers": [],
                ])
            }
            return
        }

        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: normalizedIdentifiers,
            options: nil
        )
        var foundIdentifiers = Set<String>()
        fetchResult.enumerateObjects { asset, _, _ in
            foundIdentifiers.insert(asset.localIdentifier)
        }
        let missingIdentifiers = normalizedIdentifiers.filter {
            !foundIdentifiers.contains($0)
        }

        DispatchQueue.main.async {
            result([
                "accessStatus": self.authorizationStatusValue(status),
                "missingAssetLocalIdentifiers": missingIdentifiers,
            ])
        }
    }

    private func discoverRecoverableManagedAssets(
        albumPatterns: [String],
        result: @escaping FlutterResult
    ) {
        let regexMatchers = albumMatchers(albumPatterns)
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            DispatchQueue.main.async {
                result([
                    "accessStatus": self.authorizationStatusValue(status),
                    "assets": [],
                ])
            }
            return
        }

        // Combine NSPredicate fast-path albums + regex-based full-enumeration albums
        let predicateAlbums = fetchBreakdexAlbums()
        let regexAlbums = fetchHistoricalManagedAlbums(matching: regexMatchers)
        var seenAlbumIds = Set<String>()
        var albums: [PHAssetCollection] = []
        for album in predicateAlbums + regexAlbums {
            if seenAlbumIds.insert(album.localIdentifier).inserted {
                albums.append(album)
            }
        }

        var seenAssetIds = Set<String>()
        var assets: [[String: String]] = []
        var videoAssetCount = 0
        var skippedMissingFilenameCount = 0

        for album in albums {
            let albumTitle = album.localizedTitle?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""
            guard !albumTitle.isEmpty else { continue }

            let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
            fetchResult.enumerateObjects { asset, _, _ in
                guard asset.mediaType == .video else { return }
                videoAssetCount += 1
                guard seenAssetIds.insert(asset.localIdentifier).inserted else {
                    return
                }
                guard let filename = self.originalFilename(for: asset) else {
                    skippedMissingFilenameCount += 1
                    return
                }
                assets.append([
                    "assetLocalIdentifier": asset.localIdentifier,
                    "filename": filename,
                    "albumName": albumTitle,
                ])
            }
        }

        DispatchQueue.main.async {
            result([
                "accessStatus": self.authorizationStatusValue(status),
                "assets": assets,
                "matchingAlbumCount": albums.count,
                "videoAssetCount": videoAssetCount,
                "skippedMissingFilenameCount": skippedMissingFilenameCount,
            ])
        }
    }

    private func reconcileManagedAssets(
        trackedAssets: [TrackedManagedAsset],
        source: String,
        result: @escaping FlutterResult
    ) {
        guard !trackedAssets.isEmpty else {
            DispatchQueue.main.async {
                result([
                    "accessStatus": self.authorizationStatusValue(
                        PHPhotoLibrary.authorizationStatus(for: .readWrite)
                    ),
                    "events": [],
                ])
            }
            return
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            DispatchQueue.main.async {
                result([
                    "accessStatus": self.authorizationStatusValue(status),
                    "events": [],
                ])
            }
            return
        }

        let identifiers = trackedAssets.map(\.assetLocalIdentifier)
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )
        var assetsById: [String: PHAsset] = [:]
        fetchResult.enumerateObjects { asset, _, _ in
            assetsById[asset.localIdentifier] = asset
        }

        var albumAssetIdCache: [String: Set<String>] = [:]
        func albumAssetIds(named albumName: String) -> Set<String> {
            if let cached = albumAssetIdCache[albumName] {
                return cached
            }

            guard let album = fetchAlbum(named: albumName) else {
                albumAssetIdCache[albumName] = []
                return []
            }

            let albumAssets = PHAsset.fetchAssets(in: album, options: nil)
            var ids = Set<String>()
            albumAssets.enumerateObjects { asset, _, _ in
                ids.insert(asset.localIdentifier)
            }
            albumAssetIdCache[albumName] = ids
            return ids
        }

        var events: [[String: String]] = []
        for trackedAsset in trackedAssets {
            guard let asset = assetsById[trackedAsset.assetLocalIdentifier] else {
                events.append([
                    "type": "assetDeletedFromLibrary",
                    "assetLocalIdentifier": trackedAsset.assetLocalIdentifier,
                    "moveId": trackedAsset.moveId,
                    "albumName": trackedAsset.albumName,
                    "source": source,
                ])
                continue
            }

            guard status == .authorized else { continue }
            let albumIds = albumAssetIds(named: trackedAsset.albumName)
            if !albumIds.contains(asset.localIdentifier) {
                events.append([
                    "type": "assetRemovedFromManagedAlbum",
                    "assetLocalIdentifier": trackedAsset.assetLocalIdentifier,
                    "moveId": trackedAsset.moveId,
                    "albumName": trackedAsset.albumName,
                    "source": source,
                ])
            }
        }

        DispatchQueue.main.async {
            result([
                "accessStatus": self.authorizationStatusValue(status),
                "events": events,
            ])
        }
    }

    private func restoreManagedAsset(
        assetLocalIdentifier: String,
        result: @escaping FlutterResult
    ) {
        let normalizedIdentifier = assetLocalIdentifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedIdentifier.isEmpty else {
            DispatchQueue.main.async { result(nil) }
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            self?.startObservingPhotoLibraryIfAuthorized()
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "PERMISSION_DENIED",
                            message: "Photo library read/write access denied",
                            details: nil
                        )
                    )
                }
                return
            }

            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [normalizedIdentifier],
                options: nil
            )
            guard let asset = fetchResult.firstObject else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "ASSET_NOT_FOUND",
                            message: "Managed Photos asset not found",
                            details: nil
                        )
                    )
                }
                return
            }

            let resources = PHAssetResource.assetResources(for: asset)
            let resource = resources.first(where: { $0.type == .fullSizeVideo }) ??
                resources.first(where: { $0.type == .video }) ??
                resources.first
            guard let resource else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "RESOURCE_NOT_FOUND",
                            message: "No video resource available for managed asset",
                            details: nil
                        )
                    )
                }
                return
            }

            let originalFilename = resource.originalFilename.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let fileExtension = URL(fileURLWithPath: originalFilename)
                .pathExtension
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedExtension = fileExtension.isEmpty ? "mp4" : fileExtension

            let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            let movesDir = documents.appendingPathComponent("Moves", isDirectory: true)

            do {
                try FileManager.default.createDirectory(
                    at: movesDir,
                    withIntermediateDirectories: true
                )
            } catch {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "RESTORE_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )
                }
                return
            }

            let destinationURL = movesDir
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(normalizedExtension)
            let requestOptions = PHAssetResourceRequestOptions()
            requestOptions.isNetworkAccessAllowed = true

            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: destinationURL,
                options: requestOptions
            ) { error in
                DispatchQueue.main.async {
                    if let error {
                        result(
                            FlutterError(
                                code: "RESTORE_FAILED",
                                message: error.localizedDescription,
                                details: nil
                            )
                        )
                        return
                    }

                    result([
                        "localPath": destinationURL.path,
                        "originalFileName": originalFilename.isEmpty
                            ? destinationURL.lastPathComponent
                            : originalFilename,
                    ])
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

    private func normalizedFileExtension(_ fileExtension: String?) -> String {
        guard let fileExtension else { return "mp4" }
        let trimmed = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "mp4" }
        return trimmed.hasPrefix(".") ? String(trimmed.dropFirst()) : trimmed
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

    private static let breakdexAlbumPatterns: [String] = [
        "breakdex", "break dex", "break dex", "breaking",
        "breakin", "bboy", "bgirl", "breakdance", "break dance",
    ]

    private func fetchBreakdexAlbums() -> [PHAssetCollection] {
        var seenIds = Set<String>()
        var collections: [PHAssetCollection] = []

        // Fast path: NSPredicate case-insensitive contains search
        for pattern in Self.breakdexAlbumPatterns {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "title CONTAINS[c] %@", pattern)
            let result = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: options
            )
            result.enumerateObjects { collection, _, _ in
                if seenIds.insert(collection.localIdentifier).inserted {
                    collections.append(collection)
                }
            }
        }

        // Full-enumeration fallback: scan all user albums
        let allAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        allAlbums.enumerateObjects { collection, _, _ in
            guard seenIds.insert(collection.localIdentifier).inserted else { return }
            guard let title = collection.localizedTitle?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ), !title.isEmpty else { return }
            let matches = Self.breakdexAlbumPatterns.contains { pattern in
                title.range(of: pattern, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
            if matches {
                collections.append(collection)
            }
        }

        return collections
    }

    private func fetchHistoricalManagedAlbums(
        matching patterns: [NSRegularExpression]
    ) -> [PHAssetCollection] {
        guard !patterns.isEmpty else { return [] }

        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        var seenAlbumIds = Set<String>()
        var collections: [PHAssetCollection] = []
        fetchResult.enumerateObjects { collection, _, _ in
            guard seenAlbumIds.insert(collection.localIdentifier).inserted else {
                return
            }
            guard let title = collection.localizedTitle?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ), !title.isEmpty else {
                return
            }
            let normalizedTitle = title.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
            let titleRange = NSRange(
                normalizedTitle.startIndex..<normalizedTitle.endIndex,
                in: normalizedTitle
            )
            let matchesPattern = patterns.contains { pattern in
                pattern.firstMatch(
                    in: normalizedTitle,
                    options: [],
                    range: titleRange
                ) != nil
            }
            guard matchesPattern else { return }
            collections.append(collection)
        }
        return collections
    }

    private func findAssets(
        in albums: [PHAssetCollection],
        matchingLocalIdentifier assetLocalIdentifier: String?
    ) -> [PHAsset] {
        guard let assetLocalIdentifier = assetLocalIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
              !assetLocalIdentifier.isEmpty else {
            return []
        }

        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [assetLocalIdentifier],
            options: nil
        )
        guard let asset = fetchResult.firstObject else { return [] }

        for album in albums {
            let assets = PHAsset.fetchAssets(in: album, options: nil)
            var found = false
            assets.enumerateObjects { candidate, _, stop in
                if candidate.localIdentifier == asset.localIdentifier {
                    found = true
                    stop.pointee = true
                }
            }
            if found {
                return [asset]
            }
        }

        return []
    }

    private func findAssets(
        in albums: [PHAssetCollection],
        matchingFilenames candidateFilenames: Set<String>
    ) -> [PHAsset] {
        guard !candidateFilenames.isEmpty else { return [] }

        var assetsById: [String: PHAsset] = [:]

        for album in albums {
            let fetchResult = PHAsset.fetchAssets(in: album, options: nil)
            fetchResult.enumerateObjects { asset, _, _ in
                let resources = PHAssetResource.assetResources(for: asset)
                let matches = resources.contains { resource in
                    candidateFilenames.contains(resource.originalFilename)
                }
                if matches {
                    assetsById[asset.localIdentifier] = asset
                }
            }
        }

        return Array(assetsById.values)
    }

    private func albumMatchers(_ albumPatterns: [String]) -> [NSRegularExpression] {
        Array(
            Set(
                albumPatterns
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        ).compactMap { pattern in
            try? NSRegularExpression(
                pattern: pattern,
                options: [.caseInsensitive]
            )
        }
    }

    private func originalFilename(for asset: PHAsset) -> String? {
        let resources = PHAssetResource.assetResources(for: asset)
        let resource = resources.first(where: { $0.type == .fullSizeVideo }) ??
            resources.first(where: { $0.type == .video }) ??
            resources.first
        let filename = resource?.originalFilename.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard let filename, !filename.isEmpty else { return nil }
        return filename
    }

    private func authorizationStatusValue(_ status: PHAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "not_determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        @unknown default:
            return "unknown"
        }
    }

    private func startObservingPhotoLibraryIfAuthorized() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return }
        guard !observingPhotoLibrary else { return }
        PHPhotoLibrary.shared().register(self)
        observingPhotoLibrary = true
    }

    private func stopObservingPhotoLibrary() {
        guard observingPhotoLibrary else { return }
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        observingPhotoLibrary = false
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

            for path in paths {
                let exists = FileManager.default.fileExists(atPath: path)
                let size =
                    (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?
                    .int64Value ?? -1
                print("[ShareSheetPlugin] shareFiles path=\(path) exists=\(exists) size=\(size)")
                guard exists else {
                    result(
                        FlutterError(
                            code: "FILE_NOT_FOUND",
                            message: "Share file does not exist at path: \(path)",
                            details: nil
                        )
                    )
                    return
                }
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

            print(
                "[ShareSheetPlugin] Presenting share sheet with \(items.count) item(s) from \(type(of: controller))"
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
