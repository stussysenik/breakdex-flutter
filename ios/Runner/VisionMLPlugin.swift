import Flutter
import UIKit
import Vision
import CoreML
import AVFoundation

/// Native Apple Vision + CoreML plugin for on-device ML inference.
///
/// **Capabilities:**
/// - **Pose detection**: Apple Vision's built-in VNDetectHumanBodyPose3DRequest
///   returns 17 joints with 3D coordinates — free, no model download needed.
/// - **Person segmentation**: CoreML + DeepLabV3 (8.6MB) produces alpha masks
///   for background removal.
/// - **Live pose streaming**: Camera feed → pose data at ~30fps via EventChannel.
///
/// All inference runs on-device using the Neural Engine (ANE) when available,
/// falling back to GPU → CPU automatically.
class VisionMLPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, NativeCapability {
    static var channelName: String { "vision_ml" }
    static var eventChannelName: String? { "vision_ml/stream" }

    private var eventSink: FlutterEventSink?
    private var captureSession: AVCaptureSession?
    private var isStreamingPose = false

    /// Last known good joint positions — used as fallback when a joint drops
    /// below confidence threshold on a single frame (common with low-res video).
    private var lastKnownJoints: [String: [String: Any]] = [:]

    /// Minimum dimension (px) below which we upscale before pose detection.
    /// Breakdance videos are often compressed to very small resolutions.
    private static let minDimensionForPose: CGFloat = 480
    private static let targetUpscaleSize: CGFloat = 640

    // Lazy-loaded CoreML model for person segmentation
    private lazy var segmentationModel: VNCoreMLModel? = {
        guard let modelURL = Bundle.main.url(
            forResource: "DeepLabV3",
            withExtension: "mlmodelc",
            subdirectory: "Models"
        ) else {
            print("[VisionML] DeepLabV3.mlmodelc not found in bundle")
            return nil
        }
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            return try VNCoreMLModel(for: mlModel)
        } catch {
            print("[VisionML] Failed to load DeepLabV3: \(error)")
            return nil
        }
    }()

    // MARK: - Registration

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = VisionMLPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "com.breakdex/\(channelName)",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        if let eventName = eventChannelName {
            let eventChannel = FlutterEventChannel(
                name: "com.breakdex/\(eventName)",
                binaryMessenger: registrar.messenger()
            )
            eventChannel.setStreamHandler(instance)
        }
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        stopLivePose()
        return nil
    }

    // MARK: - FlutterPlugin

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "detectPose":
            guard let args = call.arguments as? [String: Any],
                  let imageData = (args["imageData"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing imageData", details: nil))
                return
            }
            detectPose(imageData: imageData, result: result)

        case "startLivePose":
            startLivePose(result: result)

        case "stopLivePose":
            stopLivePose()
            result(nil)

        case "segmentPerson":
            guard let args = call.arguments as? [String: Any],
                  let imageData = (args["imageData"] as? FlutterStandardTypedData)?.data else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing imageData", details: nil))
                return
            }
            segmentPerson(imageData: imageData, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Pose Detection (single frame)

    /// Detect 3D body pose from a single image.
    /// Returns array of joint dictionaries: [{name, x, y, z, confidence}]
    ///
    /// **Low-res handling:** Images smaller than 480px on either dimension
    /// are upscaled to 640px using Lanczos interpolation before pose detection.
    /// This improves Vision's detection accuracy on compressed breakdance video.
    private func detectPose(imageData: Data, result: @escaping FlutterResult) {
        guard #available(iOS 17.0, *) else {
            result(FlutterError(
                code: "UNSUPPORTED_OS",
                message: "3D pose detection requires iOS 17+",
                details: nil
            ))
            return
        }

        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot decode image data", details: nil))
            return
        }

        // Upscale small images for better pose detection quality
        let processedImage = upscaleIfNeeded(cgImage)

        let request = VNDetectHumanBodyPose3DRequest()

        let handler = VNImageRequestHandler(cgImage: processedImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                var joints = self.extractJoints(from: request.results)
                joints = self.applyLastKnownFallback(joints)
                DispatchQueue.main.async {
                    result(joints)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "POSE_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - Low-Resolution Helpers

    /// Upscale a CGImage if either dimension is below the minimum threshold.
    /// Uses Lanczos resampling for sharp upscaling of compressed video frames.
    private func upscaleIfNeeded(_ image: CGImage) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let minDim = min(width, height)

        guard minDim < Self.minDimensionForPose else { return image }

        let scale = Self.targetUpscaleSize / minDim
        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else { return image }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage() ?? image
    }

    /// For joints that dropped below threshold this frame, substitute
    /// the last known good position with reduced confidence (0.35).
    /// Prevents skeleton from "blinking" on noisy low-res frames.
    private func applyLastKnownFallback(_ joints: [[String: Any]]) -> [[String: Any]] {
        var result = joints
        let detectedNames = Set(joints.compactMap { $0["name"] as? String })

        // Cache current good joints
        for joint in joints {
            guard let name = joint["name"] as? String,
                  let conf = joint["confidence"] as? Double,
                  conf > 0.4 else { continue }
            lastKnownJoints[name] = joint
        }

        // Fill in missing joints from last known
        for (name, lastJoint) in lastKnownJoints {
            if !detectedNames.contains(name) {
                var fallback = lastJoint
                fallback["confidence"] = 0.35  // Mark as low-confidence fallback
                result.append(fallback)
            }
        }

        return result
    }

    /// Extract joint data from Vision 3D pose observations.
    /// Maps Apple's 17-joint skeleton to a serializable dictionary array.
    @available(iOS 17.0, *)
    private func extractJoints(from observations: [VNHumanBodyPose3DObservation]?) -> [[String: Any]] {
        guard let observation = observations?.first else { return [] }

        let jointNames: [VNHumanBodyPose3DObservation.JointName] = [
            .root, .leftHip, .rightHip, .spine,
            .leftKnee, .rightKnee, .centerShoulder,
            .leftAnkle, .rightAnkle, .leftShoulder,
            .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist
        ]

        var joints: [[String: Any]] = []
        for jointName in jointNames {
            guard let point = try? observation.recognizedPoint(jointName) else { continue }

            // Position is a simd_float4x4 matrix — extract translation
            let position = point.position
            joints.append([
                "name": jointName.rawValue.rawValue,
                "x": Double(position.columns.3.x),
                "y": Double(position.columns.3.y),
                "z": Double(position.columns.3.z),
                "confidence": 1.0,
            ])
        }
        return joints
    }

    // MARK: - Live Pose Streaming

    /// Start camera capture and stream pose data through the EventChannel at ~30fps.
    private func startLivePose(result: @escaping FlutterResult) {
        guard #available(iOS 17.0, *) else {
            result(FlutterError(
                code: "UNSUPPORTED_OS",
                message: "Live pose streaming requires iOS 17+",
                details: nil
            ))
            return
        }

        guard !isStreamingPose else {
            result(nil)
            return
        }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            result(FlutterError(code: "NO_CAMERA", message: "No camera available", details: nil))
            return
        }

        do {
            let session = AVCaptureSession()
            session.sessionPreset = .high

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                result(FlutterError(code: "CAMERA_ERR", message: "Cannot add camera input", details: nil))
                return
            }
            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.breakdex.pose"))
            output.alwaysDiscardsLateVideoFrames = true

            guard session.canAddOutput(output) else {
                result(FlutterError(code: "CAMERA_ERR", message: "Cannot add video output", details: nil))
                return
            }
            session.addOutput(output)

            captureSession = session
            isStreamingPose = true

            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
            result(nil)
        } catch {
            result(FlutterError(code: "CAMERA_ERR", message: error.localizedDescription, details: nil))
        }
    }

    /// Stop the camera capture session.
    private func stopLivePose() {
        isStreamingPose = false
        captureSession?.stopRunning()
        captureSession = nil
    }

    // MARK: - Person Segmentation

    /// Segment a person from the background using DeepLabV3 CoreML model.
    /// Returns PNG alpha mask bytes.
    private func segmentPerson(imageData: Data, result: @escaping FlutterResult) {
        guard let model = segmentationModel else {
            result(FlutterError(
                code: "MODEL_MISSING",
                message: "DeepLabV3 model not loaded — add DeepLabV3.mlmodelc to ios/Runner/Models/",
                details: nil
            ))
            return
        }

        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot decode image data", details: nil))
            return
        }

        let request = VNCoreMLRequest(model: model) { request, error in
            if let error {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "SEGMENT_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
                return
            }

            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let maskArray = results.first?.featureValue.multiArrayValue else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "SEGMENT_FAILED",
                        message: "No segmentation mask produced",
                        details: nil
                    ))
                }
                return
            }

            // Convert MLMultiArray mask to PNG alpha image
            let maskImage = self.multiArrayToMaskImage(maskArray, size: CGSize(
                width: CGFloat(cgImage.width),
                height: CGFloat(cgImage.height)
            ))

            DispatchQueue.main.async {
                if let pngData = maskImage?.pngData() {
                    result(FlutterStandardTypedData(bytes: pngData))
                } else {
                    result(FlutterError(
                        code: "SEGMENT_FAILED",
                        message: "Failed to encode mask as PNG",
                        details: nil
                    ))
                }
            }
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "SEGMENT_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    /// Convert a DeepLabV3 segmentation MLMultiArray to a grayscale UIImage mask.
    /// Class 15 = person in the DeepLabV3 label map.
    private func multiArrayToMaskImage(_ array: MLMultiArray, size: CGSize) -> UIImage? {
        let width = array.shape[1].intValue   // 513
        let height = array.shape[0].intValue  // 513
        let count = width * height

        var pixels = [UInt8](repeating: 0, count: count)
        let pointer = array.dataPointer.bindMemory(to: Int32.self, capacity: count)

        for i in 0..<count {
            // DeepLabV3: class 15 = person
            pixels[i] = (pointer[i] == 15) ? 255 : 0
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = context.makeImage() else {
            return nil
        }

        // Scale to original image dimensions
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
        let scaled = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaled
    }
}

// MARK: - Camera Delegate for Live Pose

extension VisionMLPlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isStreamingPose, let sink = eventSink else { return }
        guard #available(iOS 17.0, *) else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectHumanBodyPose3DRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([request])
            var joints = extractJoints(from: request.results)
            joints = applyLastKnownFallback(joints)
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds * 1000

            let confidences = joints.compactMap { $0["confidence"] as? Double }
            let avgConfidence = confidences.isEmpty ? 0.0 :
                confidences.reduce(0, +) / Double(confidences.count)

            let event: [String: Any] = [
                "joints": joints,
                "timestamp": timestamp,
                "confidence": avgConfidence,
            ]

            DispatchQueue.main.async {
                sink(event)
            }
        } catch {
            // Drop frame silently — live streaming tolerates occasional misses
        }
    }
}
