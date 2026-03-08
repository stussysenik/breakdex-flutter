import AVFoundation
import Flutter
import UIKit

final class VideoPreviewPlugin: NSObject, FlutterPlugin, NativeCapability {
    static var channelName: String { "video_preview" }

    private let queue = DispatchQueue(
        label: "com.breakdex.video_preview",
        qos: .userInitiated
    )
    private let cache = NSCache<NSString, NSData>()

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.breakdex/video_preview",
            binaryMessenger: registrar.messenger()
        )
        let instance = VideoPreviewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "generateThumbnails":
            guard let args = call.arguments as? [String: Any] else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Missing arguments",
                        details: nil
                    )
                )
                return
            }
            generateThumbnails(args: args, completion: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func generateThumbnails(
        args: [String: Any],
        completion: @escaping FlutterResult
    ) {
        guard let videoPath = args["videoPath"] as? String,
              let timesMs = args["timesMs"] as? [Int] else {
            completion(
                FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing required fields",
                    details: nil
                )
            )
            return
        }

        guard FileManager.default.fileExists(atPath: videoPath) else {
            completion(
                FlutterError(
                    code: "MISSING_FILE",
                    message: "Video file is unavailable",
                    details: nil
                )
            )
            return
        }

        let maxWidth = max(2, args["maxWidth"] as? Int ?? 80)
        let quality = min(100, max(1, args["quality"] as? Int ?? 50))
        let exact = args["exact"] as? Bool ?? false
        let toleranceMs = max(0, args["toleranceMs"] as? Int ?? 200)

        var payload = Array<Any>(repeating: NSNull(), count: timesMs.count)
        var pendingIndicesByTime = [Int: [Int]]()

        for (index, timeMs) in timesMs.enumerated() {
            let key = cacheKey(
                videoPath: videoPath,
                timeMs: timeMs,
                maxWidth: maxWidth,
                quality: quality,
                exact: exact
            )
            if let cached = cache.object(forKey: key as NSString) {
                payload[index] = FlutterStandardTypedData(bytes: cached as Data)
            } else {
                pendingIndicesByTime[timeMs, default: []].append(index)
            }
        }

        if pendingIndicesByTime.isEmpty {
            completion(payload)
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            let asset = AVURLAsset(url: URL(fileURLWithPath: videoPath))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(
                width: CGFloat(maxWidth),
                height: CGFloat(maxWidth) * 4
            )

            let tolerance = exact
                ? CMTime.zero
                : CMTime(value: Int64(toleranceMs), timescale: 1000)
            generator.requestedTimeToleranceBefore = tolerance
            generator.requestedTimeToleranceAfter = tolerance

            let requestedTimes = pendingIndicesByTime.keys.sorted().map {
                NSValue(time: CMTime(value: Int64($0), timescale: 1000))
            }

            let dispatchGroup = DispatchGroup()
            for _ in requestedTimes {
                dispatchGroup.enter()
            }

            generator.generateCGImagesAsynchronously(forTimes: requestedTimes) {
                [weak self] requestedTime,
                image,
                _,
                result,
                _ in
                defer { dispatchGroup.leave() }

                guard let self = self else { return }
                guard result == .succeeded, let image else { return }

                let requestedMs = requestedTime.timescale == 1000
                    ? Int(requestedTime.value)
                    : Int(round(requestedTime.seconds * 1000))
                guard let indices = pendingIndicesByTime[requestedMs] else {
                    return
                }

                guard let data = UIImage(cgImage: image).jpegData(
                    compressionQuality: CGFloat(quality) / 100.0
                ) else {
                    return
                }

                for index in indices {
                    let timeMs = timesMs[index]
                    let key = self.cacheKey(
                        videoPath: videoPath,
                        timeMs: timeMs,
                        maxWidth: maxWidth,
                        quality: quality,
                        exact: exact
                    )
                    self.cache.setObject(data as NSData, forKey: key as NSString)
                    payload[index] = FlutterStandardTypedData(bytes: data)
                }
            }

            dispatchGroup.notify(queue: self.queue) {
                DispatchQueue.main.async {
                    completion(payload)
                }
            }
        }
    }

    private func cacheKey(
        videoPath: String,
        timeMs: Int,
        maxWidth: Int,
        quality: Int,
        exact: Bool
    ) -> String {
        "\(videoPath)|\(timeMs)|\(maxWidth)|\(quality)|\(exact ? 1 : 0)"
    }
}
