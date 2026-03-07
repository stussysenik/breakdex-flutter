import Flutter
import UIKit
import AVFoundation

struct VideoExportGeometryResult {
    let renderSize: CGSize
    let transform: CGAffineTransform
}

enum VideoExportGeometryError: LocalizedError {
    case invalidCanvas
    case invalidCrop

    var errorDescription: String? {
        switch self {
        case .invalidCanvas:
            return "Invalid video canvas size"
        case .invalidCrop:
            return "Invalid crop rectangle"
        }
    }
}

struct VideoExportGeometry {
    static func orientedBounds(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform
    ) -> CGRect {
        CGRect(origin: .zero, size: naturalSize)
            .applying(preferredTransform)
            .standardized
    }

    static func compute(
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        userRotation: Int,
        cropRect: CGRect?
    ) throws -> VideoExportGeometryResult {
        let orientedBounds = orientedBounds(
            naturalSize: naturalSize,
            preferredTransform: preferredTransform
        )
        guard orientedBounds.width > 0, orientedBounds.height > 0 else {
            throw VideoExportGeometryError.invalidCanvas
        }

        var transform = preferredTransform.concatenating(
            CGAffineTransform(
                translationX: -orientedBounds.minX,
                y: -orientedBounds.minY
            )
        )
        var canvasBounds = CGRect(origin: .zero, size: orientedBounds.size)

        let normalizedRotation = ((userRotation % 360) + 360) % 360
        if normalizedRotation != 0 {
            let radians = CGFloat(normalizedRotation) * .pi / 180.0
            let rotationResult = rotationTransform(
                canvasBounds: canvasBounds,
                angle: radians
            )
            transform = transform.concatenating(rotationResult.transform)
            canvasBounds = CGRect(origin: .zero, size: rotationResult.size)
        }

        if let cropRect {
            let clampedCrop = clampedCropRect(cropRect, canvasSize: canvasBounds.size)
            guard clampedCrop.width > 0, clampedCrop.height > 0 else {
                throw VideoExportGeometryError.invalidCrop
            }
            transform = transform.concatenating(
                CGAffineTransform(
                    translationX: -clampedCrop.minX,
                    y: -clampedCrop.minY
                )
            )
            canvasBounds = CGRect(origin: .zero, size: clampedCrop.size)
        }

        let renderSize = evenRenderSize(from: canvasBounds.size)
        return VideoExportGeometryResult(
            renderSize: renderSize,
            transform: transform
        )
    }

    private static func rotationTransform(
        canvasBounds: CGRect,
        angle: CGFloat
    ) -> (transform: CGAffineTransform, size: CGSize) {
        let rotation = CGAffineTransform(
            translationX: -canvasBounds.midX,
            y: -canvasBounds.midY
        ).rotated(by: angle)
        let rotatedBounds = canvasBounds.applying(rotation).standardized
        let normalize = CGAffineTransform(
            translationX: -rotatedBounds.minX,
            y: -rotatedBounds.minY
        )
        return (
            rotation.concatenating(normalize),
            rotatedBounds.size
        )
    }

    private static func clampedCropRect(
        _ normalizedCrop: CGRect,
        canvasSize: CGSize
    ) -> CGRect {
        let width = canvasSize.width
        let height = canvasSize.height

        guard width > 0, height > 0 else { return .zero }

        let leftNormalized = max(0, min(1, normalizedCrop.minX))
        let topNormalized = max(0, min(1, normalizedCrop.minY))
        let rightNormalized = max(leftNormalized, min(1, normalizedCrop.maxX))
        let bottomNormalized = max(topNormalized, min(1, normalizedCrop.maxY))

        let left = leftNormalized * width
        let top = topNormalized * height
        let right = rightNormalized * width
        let bottom = bottomNormalized * height

        let cropWidth = max(2, right - left)
        let cropHeight = max(2, bottom - top)
        let clampedWidth = min(cropWidth, width - left)
        let clampedHeight = min(cropHeight, height - top)

        return CGRect(
            x: left,
            y: top,
            width: max(2, clampedWidth),
            height: max(2, clampedHeight)
        )
    }

    private static func evenRenderSize(from size: CGSize) -> CGSize {
        let width = max(2, Int(floor(size.width / 2)) * 2)
        let height = max(2, Int(floor(size.height / 2)) * 2)
        return CGSize(width: width, height: height)
    }
}

/// Native iOS video export using AVFoundation — hardware-accelerated, works on both
/// simulator and device. Reports real-time progress via EventChannel.
class VideoExportPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, NativeCapability {
    static var channelName: String { "video_export" }
    static var eventChannelName: String? { "video_export_progress" }

    private var progressSink: FlutterEventSink?
    private var exportSession: AVAssetExportSession?
    private var progressTimer: Timer?
    private var encoderInitialized = false
    private var encoderStartTime: Date?

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = VideoExportPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "com.breakdex/video_export",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let eventChannel = FlutterEventChannel(
            name: "com.breakdex/video_export_progress",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        progressSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        progressSink = nil
        return nil
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "exportVideo":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
                return
            }
            exportVideo(args: args, result: result)

        case "cancelExport":
            exportSession?.cancelExport()
            stopProgressTimer()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Export

    private func exportVideo(args: [String: Any], result: @escaping FlutterResult) {
        guard let inputPath = args["inputPath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let trimStartMs = args["trimStartMs"] as? Int,
              let trimEndMs = args["trimEndMs"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required fields", details: nil))
            return
        }

        let speed = args["speed"] as? Double ?? 1.0
        let rotation = args["rotation"] as? Int ?? 0

        // Free-form crop params (normalized 0.0-1.0)
        let cropLeft = args["cropLeft"] as? Double
        let cropTop = args["cropTop"] as? Double
        let cropWidth = args["cropWidth"] as? Double
        let cropHeight = args["cropHeight"] as? Double

        let inputURL = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)

        try? FileManager.default.removeItem(at: outputURL)

        let asset = AVURLAsset(url: inputURL)

        encoderInitialized = false
        encoderStartTime = nil
        sendProgress(phase: "preparing", progress: 0.02)

        Task { [weak self] in
            guard let self = self else { return }

            guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_VIDEO", message: "No video track found", details: nil))
                }
                return
            }

            guard let naturalSize = try? await videoTrack.load(.naturalSize),
                  let preferredTransform = try? await videoTrack.load(.preferredTransform) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "LOAD_ERR", message: "Cannot load track properties", details: nil))
                }
                return
            }

            let startTime = CMTime(value: Int64(trimStartMs), timescale: 1000)
            let endTime = CMTime(value: Int64(trimEndMs), timescale: 1000)
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            let trimmedDuration = CMTimeSubtract(endTime, startTime)

            let composition = AVMutableComposition()

            guard let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "TRACK_ERR", message: "Cannot create video track", details: nil))
                }
                return
            }

            do {
                try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "INSERT_ERR", message: error.localizedDescription, details: nil))
                }
                return
            }

            // Audio
            var compositionAudioTrack: AVMutableCompositionTrack?
            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                compositionAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
                try? compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }

            // Speed
            if speed != 1.0 {
                let scaledDuration = CMTimeMultiplyByFloat64(trimmedDuration, multiplier: 1.0 / speed)
                let insertedRange = CMTimeRange(start: .zero, duration: trimmedDuration)
                compositionVideoTrack.scaleTimeRange(insertedRange, toDuration: scaledDuration)
                compositionAudioTrack?.scaleTimeRange(insertedRange, toDuration: scaledDuration)
            }

            let cropRect = self.normalizedCropRect(
                left: cropLeft,
                top: cropTop,
                width: cropWidth,
                height: cropHeight
            )

            let geometry: VideoExportGeometryResult
            do {
                geometry = try VideoExportGeometry.compute(
                    naturalSize: naturalSize,
                    preferredTransform: preferredTransform,
                    userRotation: rotation,
                    cropRect: cropRect
                )
            } catch {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "GEOMETRY_ERR",
                            message: error.localizedDescription,
                            details: nil
                        )
                    )
                }
                return
            }

            let renderSize = geometry.renderSize
            let finalTransform = geometry.transform

            let videoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = renderSize

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(finalTransform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

            self.sendProgress(phase: "composing", progress: 0.05)

            guard renderSize.width >= 2, renderSize.height >= 2 else {
                DispatchQueue.main.async {
                    result(
                        FlutterError(
                            code: "GEOMETRY_ERR",
                            message: "Export produced an invalid render size",
                            details: nil
                        )
                    )
                }
                return
            }

            self.sendProgress(phase: "initializing", progress: 0.08)

            guard let session = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "SESSION_ERR", message: "Cannot create export session", details: nil))
                }
                return
            }

            session.outputURL = outputURL
            session.outputFileType = .mp4
            session.videoComposition = videoComposition
            session.shouldOptimizeForNetworkUse = true

            self.exportSession = session
            self.encoderStartTime = Date()

            DispatchQueue.main.async {
                self.startProgressTimer()
            }

            session.exportAsynchronously { [weak self] in
                guard let self = self else { return }
                self.stopProgressTimer()

                switch session.status {
                case .completed:
                    Task { [weak self] in
                        guard let self = self else { return }
                        do {
                            try await self.validateExportedVideo(at: outputURL)
                            self.sendProgress(phase: "done", progress: 1.0)
                            DispatchQueue.main.async {
                                result(outputPath)
                            }
                        } catch {
                            try? FileManager.default.removeItem(at: outputURL)
                            DispatchQueue.main.async {
                                result(
                                    FlutterError(
                                        code: "INVALID_EXPORT",
                                        message: error.localizedDescription,
                                        details: nil
                                    )
                                )
                            }
                        }
                        self.exportSession = nil
                    }

                case .cancelled:
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CANCELLED", message: "Export cancelled", details: nil))
                    }

                case .failed:
                    let errorMsg = session.error?.localizedDescription ?? "Unknown error"
                    DispatchQueue.main.async {
                        result(FlutterError(code: "EXPORT_FAILED", message: errorMsg, details: nil))
                    }

                default:
                    DispatchQueue.main.async {
                        result(FlutterError(code: "UNKNOWN", message: "Unexpected status", details: nil))
                    }
                }

                if session.status != .completed {
                    self.exportSession = nil
                }
            }
        }
    }

    private func normalizedCropRect(
        left: Double?,
        top: Double?,
        width: Double?,
        height: Double?
    ) -> CGRect? {
        guard let left, let top, let width, let height else {
            return nil
        }
        return CGRect(x: left, y: top, width: width, height: height)
    }

    private func validateExportedVideo(at url: URL) async throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        guard fileSize > 0 else {
            throw NSError(
                domain: "VideoExportPlugin",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Exported video file is empty"]
            )
        }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        guard duration.isValid, duration.seconds > 0 else {
            throw NSError(
                domain: "VideoExportPlugin",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Exported video has no duration"]
            )
        }

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(
                domain: "VideoExportPlugin",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Exported video track is missing"]
            )
        }

        let exportedSize = try await videoTrack.load(.naturalSize)
        let exportedTransform = try await videoTrack.load(.preferredTransform)
        let bounds = VideoExportGeometry.orientedBounds(
            naturalSize: exportedSize,
            preferredTransform: exportedTransform
        )
        guard bounds.width > 1, bounds.height > 1 else {
            throw NSError(
                domain: "VideoExportPlugin",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Exported video dimensions are invalid"]
            )
        }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 640, height: 640)
        _ = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
    }

    // MARK: - Progress

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.exportSession else { return }

            let sessionProgress = Double(session.progress)

            if sessionProgress > 0.0 && !self.encoderInitialized {
                self.encoderInitialized = true
            }

            if !self.encoderInitialized {
                // Encoder not yet producing frames — show initializing phase
                let waitSeconds = -(self.encoderStartTime ?? Date()).timeIntervalSinceNow
                self.sendProgress(
                    phase: "initializing",
                    progress: 0.08,
                    extra: ["waitSeconds": waitSeconds]
                )
                return
            }

            // Map session.progress (0-1) to our range (0.10 - 1.0)
            let p = 0.10 + sessionProgress * 0.90

            // Detect stall: encoder initialized but progress hasn't moved in >10s
            if let startTime = self.encoderStartTime {
                let elapsed = -startTime.timeIntervalSinceNow
                if elapsed > 10.0 && sessionProgress < 0.05 {
                    self.sendProgress(
                        phase: "encoding_stalled",
                        progress: p,
                        extra: ["stallSeconds": elapsed]
                    )
                    return
                }
            }

            self.sendProgress(phase: "encoding", progress: p)
        }
    }

    private func stopProgressTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.progressTimer?.invalidate()
            self?.progressTimer = nil
        }
    }

    private func sendProgress(phase: String, progress: Double, extra: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            var data: [String: Any] = ["phase": phase, "progress": progress]
            if let extra = extra {
                for (key, value) in extra {
                    data[key] = value
                }
            }
            self?.progressSink?(data)
        }
    }

}
