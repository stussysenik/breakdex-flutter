import Flutter
import UIKit
import AVFoundation

/// Native iOS video export using AVFoundation — hardware-accelerated, works on both
/// simulator and device. Reports real-time progress via EventChannel.
class VideoExportPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
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
        let aspectRatio = args["aspectRatio"] as? String

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

            self.sendProgress(phase: "composing", progress: 0.05)

            // Geometry
            let orientedSize = self.orientedSize(naturalSize: naturalSize, transform: preferredTransform)
            let (renderSize, finalTransform) = self.computeTransformAndSize(
                orientedSize: orientedSize,
                naturalSize: naturalSize,
                preferredTransform: preferredTransform,
                userRotation: rotation,
                aspectRatio: aspectRatio,
                cropLeft: cropLeft,
                cropTop: cropTop,
                cropWidth: cropWidth,
                cropHeight: cropHeight
            )

            let videoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
            videoComposition.renderSize = renderSize

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            layerInstruction.setTransform(finalTransform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]

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
                    self.sendProgress(phase: "done", progress: 1.0)
                    DispatchQueue.main.async {
                        result(outputPath)
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

                self.exportSession = nil
            }
        }
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

    // MARK: - Geometry

    private func orientedSize(naturalSize: CGSize, transform: CGAffineTransform) -> CGSize {
        let rect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(rect.width), height: abs(rect.height))
    }

    private func computeTransformAndSize(
        orientedSize: CGSize,
        naturalSize: CGSize,
        preferredTransform: CGAffineTransform,
        userRotation: Int,
        aspectRatio: String?,
        cropLeft: Double?,
        cropTop: Double?,
        cropWidth: Double?,
        cropHeight: Double?
    ) -> (CGSize, CGAffineTransform) {
        var transform = preferredTransform
        var currentSize = orientedSize

        // User rotation
        let normalizedRotation = ((userRotation % 360) + 360) % 360
        if normalizedRotation != 0 {
            let radians = CGFloat(normalizedRotation) * .pi / 180.0

            // Build rotation around center of oriented space
            transform = preferredTransform
                .concatenating(CGAffineTransform(translationX: -orientedSize.width / 2, y: -orientedSize.height / 2))
                .concatenating(CGAffineTransform(rotationAngle: radians))

            if normalizedRotation == 90 || normalizedRotation == 270 {
                currentSize = CGSize(width: orientedSize.height, height: orientedSize.width)
            }

            transform = transform.concatenating(
                CGAffineTransform(translationX: currentSize.width / 2, y: currentSize.height / 2)
            )
        }

        // Crop
        var renderSize = currentSize
        if let cl = cropLeft, let ct = cropTop, let cw = cropWidth, let ch = cropHeight {
            let pixelLeft = CGFloat(cl) * currentSize.width
            let pixelTop = CGFloat(ct) * currentSize.height
            let pixelWidth = CGFloat(cw) * currentSize.width
            let pixelHeight = CGFloat(ch) * currentSize.height

            renderSize = CGSize(width: pixelWidth, height: pixelHeight)
            transform = transform.concatenating(CGAffineTransform(translationX: -pixelLeft, y: -pixelTop))
        }

        // H.264 requires even dimensions
        renderSize.width = CGFloat(Int(renderSize.width / 2) * 2)
        renderSize.height = CGFloat(Int(renderSize.height / 2) * 2)

        return (renderSize, transform)
    }
}
