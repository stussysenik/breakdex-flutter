import Flutter

/// Native iCloud file coordination plugin.
///
/// Uses `NSFileCoordinator` and `FileManager.url(forUbiquityContainerIdentifier:)`
/// for safe cloud file access. iCloud handles network optimization natively
/// (WiFi vs cellular is managed by iOS).
///
/// Registered via CapabilityRegistry — no manual wiring needed.
final class iCloudSyncPlugin: NSObject, FlutterPlugin, NativeCapability {
    static let channelName = "com.breakdex/icloud_sync"

    private var channel: FlutterMethodChannel?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = iCloudSyncPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAvailability":
            checkAvailability(result: result)
        case "upload":
            guard let args = call.arguments as? [String: Any],
                  let localPath = args["localPath"] as? String,
                  let remotePath = args["remotePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing localPath or remotePath", details: nil))
                return
            }
            upload(localPath: localPath, remotePath: remotePath, result: result)
        case "download":
            guard let args = call.arguments as? [String: Any],
                  let remotePath = args["remotePath"] as? String,
                  let localPath = args["localPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing remotePath or localPath", details: nil))
                return
            }
            download(remotePath: remotePath, localPath: localPath, result: result)
        case "verify":
            guard let args = call.arguments as? [String: Any],
                  let remotePath = args["remotePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing remotePath", details: nil))
                return
            }
            let expectedSize = args["expectedSize"] as? Int
            verify(remotePath: remotePath, expectedSize: expectedSize, result: result)
        case "list":
            guard let args = call.arguments as? [String: Any],
                  let directory = args["directory"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing directory", details: nil))
                return
            }
            listFiles(directory: directory, result: result)
        case "delete":
            guard let args = call.arguments as? [String: Any],
                  let remotePath = args["remotePath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing remotePath", details: nil))
                return
            }
            deleteFile(remotePath: remotePath, result: result)
        case "quota":
            getQuota(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - iCloud Operations

    private func checkAvailability(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            let available = FileManager.default.ubiquityIdentityToken != nil
            DispatchQueue.main.async {
                result(available)
            }
        }
    }

    private func containerURL() -> URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }

    private func upload(localPath: String, remotePath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let containerURL = self?.containerURL() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_ICLOUD", message: "iCloud container not available", details: nil))
                }
                return
            }

            let sourceURL = URL(fileURLWithPath: localPath)
            let destDir = containerURL.appendingPathComponent("Documents/Breakdex", isDirectory: true)
            let destURL = destDir.appendingPathComponent(remotePath)

            do {
                // Ensure directory exists
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

                // Use NSFileCoordinator for safe iCloud access
                let coordinator = NSFileCoordinator()
                var coordError: NSError?

                coordinator.coordinate(
                    writingItemAt: destURL,
                    options: .forReplacing,
                    error: &coordError
                ) { coordURL in
                    do {
                        if FileManager.default.fileExists(atPath: coordURL.path) {
                            try FileManager.default.removeItem(at: coordURL)
                        }
                        try FileManager.default.copyItem(at: sourceURL, to: coordURL)
                    } catch {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "UPLOAD_FAILED", message: error.localizedDescription, details: nil))
                        }
                        return
                    }
                }

                if let error = coordError {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "COORD_ERROR", message: error.localizedDescription, details: nil))
                    }
                    return
                }

                let attrs = try FileManager.default.attributesOfItem(atPath: destURL.path)
                let size = attrs[.size] as? Int ?? 0

                DispatchQueue.main.async {
                    result([
                        "remotePath": destURL.path,
                        "sizeBytes": size,
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "UPLOAD_FAILED", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func download(remotePath: String, localPath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let containerURL = self?.containerURL() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_ICLOUD", message: "iCloud container not available", details: nil))
                }
                return
            }

            let sourceURL = containerURL.appendingPathComponent("Documents/Breakdex/\(remotePath)")
            let destURL = URL(fileURLWithPath: localPath)

            let coordinator = NSFileCoordinator()
            var coordError: NSError?

            coordinator.coordinate(
                readingItemAt: sourceURL,
                options: [],
                error: &coordError
            ) { coordURL in
                do {
                    // Ensure the file is downloaded from iCloud
                    try FileManager.default.startDownloadingUbiquitousItem(at: coordURL)

                    // Wait for download to complete (poll with timeout)
                    var downloaded = false
                    for _ in 0..<60 { // 60 second timeout
                        let resourceValues = try coordURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                        if resourceValues.ubiquitousItemDownloadingStatus == .current {
                            downloaded = true
                            break
                        }
                        Thread.sleep(forTimeInterval: 1.0)
                    }

                    guard downloaded else {
                        DispatchQueue.main.async {
                            result(FlutterError(code: "DOWNLOAD_TIMEOUT", message: "iCloud download timed out", details: nil))
                        }
                        return
                    }

                    if FileManager.default.fileExists(atPath: destURL.path) {
                        try FileManager.default.removeItem(at: destURL)
                    }
                    try FileManager.default.copyItem(at: coordURL, to: destURL)

                    DispatchQueue.main.async {
                        result(nil) // Success
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "DOWNLOAD_FAILED", message: error.localizedDescription, details: nil))
                    }
                }
            }

            if let error = coordError {
                DispatchQueue.main.async {
                    result(FlutterError(code: "COORD_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func verify(remotePath: String, expectedSize: Int?, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let containerURL = self?.containerURL() else {
                DispatchQueue.main.async { result(["exists": false]) }
                return
            }

            let fileURL = containerURL.appendingPathComponent("Documents/Breakdex/\(remotePath)")
            let exists = FileManager.default.fileExists(atPath: fileURL.path)

            var sizeMatch = true
            if exists, let expected = expectedSize {
                let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                let actualSize = attrs?[.size] as? Int ?? 0
                sizeMatch = actualSize == expected
            }

            DispatchQueue.main.async {
                result([
                    "exists": exists && sizeMatch,
                    "path": fileURL.path,
                ])
            }
        }
    }

    private func listFiles(directory: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let containerURL = self?.containerURL() else {
                DispatchQueue.main.async { result([]) }
                return
            }

            let dirURL = containerURL.appendingPathComponent("Documents/Breakdex/\(directory)")
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dirURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            ) else {
                DispatchQueue.main.async { result([]) }
                return
            }

            let items: [[String: Any]] = contents.compactMap { url in
                let attrs = try? url.resourceValues(forKeys: [.fileSizeKey])
                return [
                    "path": url.lastPathComponent,
                    "size": attrs?.fileSize ?? 0,
                ]
            }

            DispatchQueue.main.async {
                result(items)
            }
        }
    }

    private func deleteFile(remotePath: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let containerURL = self?.containerURL() else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_ICLOUD", message: "iCloud container not available", details: nil))
                }
                return
            }

            let fileURL = containerURL.appendingPathComponent("Documents/Breakdex/\(remotePath)")

            let coordinator = NSFileCoordinator()
            var coordError: NSError?

            coordinator.coordinate(
                writingItemAt: fileURL,
                options: .forDeleting,
                error: &coordError
            ) { coordURL in
                try? FileManager.default.removeItem(at: coordURL)
            }

            DispatchQueue.main.async {
                if let error = coordError {
                    result(FlutterError(code: "DELETE_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    result(nil)
                }
            }
        }
    }

    private func getQuota(result: @escaping FlutterResult) {
        // iCloud doesn't expose quota directly via API.
        // We could check device storage as a proxy.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let systemAttrs = try FileManager.default.attributesOfFileSystem(
                    forPath: NSHomeDirectory()
                )
                let totalBytes = systemAttrs[.systemSize] as? Int ?? 0
                let freeBytes = systemAttrs[.systemFreeSize] as? Int ?? 0
                let usedBytes = totalBytes - freeBytes

                DispatchQueue.main.async {
                    result([
                        "totalBytes": totalBytes,
                        "usedBytes": usedBytes,
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    result(nil)
                }
            }
        }
    }
}
