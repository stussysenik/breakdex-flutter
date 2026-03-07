import Flutter
import SceneKit

/// Metal-backed SceneKit view embedded in Flutter via PlatformView.
///
/// This wraps an `SCNView` and provides methods to:
/// - Load USDZ/glTF 3D models (e.g. skeleton for pose visualization)
/// - Update joint positions from Vision ML pose data
/// - Control camera position, lighting, and animations
///
/// **Metal rendering:**
/// `SCNView.preferredRenderingAPI` defaults to Metal on modern devices,
/// giving hardware-accelerated 3D rendering with minimal CPU overhead.
///
/// **Touch gestures:**
/// `allowsCameraControl = true` enables built-in rotate/zoom/pan gestures.
class SceneKit3DView: NSObject, FlutterPlatformView {
    private let scnView: SCNView
    private let scene: SCNScene
    private var skeletonNode: SCNNode?
    private var jointNodes: [String: SCNNode] = [:]
    private var boneNodes: [String: SCNNode] = [:]

    // Temporal smoothing: exponential moving average over recent frames
    // to reduce jitter from low-res / fast-motion breakdance video.
    private var smoothedPositions: [String: SCNVector3] = [:]
    private let smoothingFactor: Float = 0.4  // 0 = no smoothing, 1 = freeze

    init(
        frame: CGRect,
        viewId: Int64,
        creationParams: [String: Any]?,
        messenger: FlutterBinaryMessenger
    ) {
        scnView = SCNView(frame: frame)
        scene = SCNScene()

        super.init()

        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X

        setupDefaultCamera()
        setupDefaultLighting()

        // Register as the active view for MethodChannel commands
        SceneKit3DPlugin.setActiveView(self)
    }

    func view() -> UIView {
        return scnView
    }

    deinit {
        SceneKit3DPlugin.setActiveView(nil)
    }

    // MARK: - Scene Setup

    private func setupDefaultCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.01
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 1.0, 3.0)
        cameraNode.look(at: SCNVector3(0, 0.8, 0))
        cameraNode.name = "defaultCamera"
        scene.rootNode.addChildNode(cameraNode)
    }

    private func setupDefaultLighting() {
        // Ambient light for base illumination
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        ambientLight.light?.color = UIColor.white
        ambientLight.name = "ambientLight"
        scene.rootNode.addChildNode(ambientLight)

        // Directional key light
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.color = UIColor.white
        keyLight.position = SCNVector3(2, 3, 2)
        keyLight.look(at: SCNVector3.init(0, 0, 0))
        keyLight.name = "keyLight"
        scene.rootNode.addChildNode(keyLight)
    }

    // MARK: - Model Loading

    /// Load a 3D model from a bundle asset path (USDZ or SCN).
    func loadModel(path: String, result: @escaping FlutterResult) {
        // Try loading from bundle first
        if let url = Bundle.main.url(forResource: path, withExtension: nil, subdirectory: "Assets") {
            loadModelFromURL(url, result: result)
            return
        }

        // Try as a direct bundle resource (without subdirectory)
        if let url = Bundle.main.url(forResource: path, withExtension: nil) {
            loadModelFromURL(url, result: result)
            return
        }

        // Try as a file system path
        let fileURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            loadModelFromURL(fileURL, result: result)
            return
        }

        result(FlutterError(code: "MODEL_NOT_FOUND", message: "Cannot find model at: \(path)", details: nil))
    }

    private func loadModelFromURL(_ url: URL, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let loadedScene = try SCNScene(url: url, options: [
                    .checkConsistency: true,
                ])

                DispatchQueue.main.async {
                    guard let self else { return }

                    // Remove previous skeleton
                    self.skeletonNode?.removeFromParentNode()
                    self.jointNodes.removeAll()
                    self.boneNodes.removeAll()

                    // Add loaded model to scene
                    let modelNode = SCNNode()
                    for child in loadedScene.rootNode.childNodes {
                        modelNode.addChildNode(child)
                    }
                    modelNode.name = "loadedModel"
                    self.skeletonNode = modelNode
                    self.scene.rootNode.addChildNode(modelNode)

                    result(true)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "MODEL_LOAD_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    // MARK: - Skeleton Update

    /// Update the 3D skeleton visualization with new joint positions from VisionML.
    ///
    /// Creates sphere nodes for each joint and cylinder bones connecting them.
    /// Subsequent calls update positions without recreating geometry.
    ///
    /// **Low-resolution video handling:**
    /// - Positions are smoothed with an exponential moving average (EMA) to reduce
    ///   jitter from noisy detections on compressed/low-res breakdance videos.
    /// - Joint sphere size and opacity scale with confidence — high-confidence joints
    ///   get full-size spheres, low-confidence joints shrink and fade.
    func updateSkeleton(joints: [[String: Any]]) {
        for jointData in joints {
            guard let name = jointData["name"] as? String,
                  let x = jointData["x"] as? Double,
                  let y = jointData["y"] as? Double,
                  let z = jointData["z"] as? Double else { continue }

            let confidence = jointData["confidence"] as? Double ?? 0.0
            let rawPosition = SCNVector3(Float(x), Float(y), Float(z))

            // Apply temporal smoothing (EMA) to reduce jitter on low-res video.
            // smoothed = lerp(rawPosition, previousSmoothed, smoothingFactor)
            let position: SCNVector3
            if let prev = smoothedPositions[name] {
                position = SCNVector3(
                    prev.x * smoothingFactor + rawPosition.x * (1 - smoothingFactor),
                    prev.y * smoothingFactor + rawPosition.y * (1 - smoothingFactor),
                    prev.z * smoothingFactor + rawPosition.z * (1 - smoothingFactor)
                )
            } else {
                position = rawPosition
            }
            smoothedPositions[name] = position

            // Scale sphere radius and opacity by confidence tier:
            //   High  (>0.7): full size (0.02), full opacity
            //   Medium (0.3-0.7): 75% size (0.015), 60% opacity
            //   Low   (<0.3): hidden (opacity 0.3, 50% size)
            let (radius, opacity): (CGFloat, CGFloat) = {
                if confidence > 0.7 { return (0.02, 1.0) }
                if confidence > 0.3 { return (0.015, 0.6) }
                return (0.01, 0.3)
            }()

            if let existingNode = jointNodes[name] {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.05
                existingNode.position = position
                existingNode.opacity = opacity
                if let sphere = existingNode.geometry as? SCNSphere {
                    sphere.radius = radius
                }
                SCNTransaction.commit()
            } else {
                let sphere = SCNSphere(radius: radius)
                sphere.firstMaterial?.diffuse.contents = jointColor(for: name)
                sphere.firstMaterial?.lightingModel = .physicallyBased

                let node = SCNNode(geometry: sphere)
                node.position = position
                node.name = "joint_\(name)"
                node.opacity = opacity

                scene.rootNode.addChildNode(node)
                jointNodes[name] = node
            }
        }

        updateBones()
    }

    /// Bone connections — pairs of joint names that should be connected by a line.
    private static let boneConnections: [(String, String)] = [
        ("root", "left_hip_joint"),
        ("root", "right_hip_joint"),
        ("root", "spine_7_joint"),
        ("spine_7_joint", "center_shoulder_joint"),
        ("center_shoulder_joint", "left_shoulder_1_joint"),
        ("center_shoulder_joint", "right_shoulder_1_joint"),
        ("left_shoulder_1_joint", "left_elbow_joint"),
        ("right_shoulder_1_joint", "right_elbow_joint"),
        ("left_elbow_joint", "left_wrist_joint"),
        ("right_elbow_joint", "right_wrist_joint"),
        ("left_hip_joint", "left_knee_joint"),
        ("right_hip_joint", "right_knee_joint"),
        ("left_knee_joint", "left_ankle_joint"),
        ("right_knee_joint", "right_ankle_joint"),
        ("left_ankle_joint", "left_foot_joint"),
        ("right_ankle_joint", "right_foot_joint"),
    ]

    /// Update bone cylinders between connected joints.
    /// Bone width scales with the minimum opacity (confidence) of the two endpoints.
    private func updateBones() {
        for (fromName, toName) in Self.boneConnections {
            guard let fromNode = jointNodes[fromName],
                  let toNode = jointNodes[toName] else { continue }

            let boneKey = "\(fromName)-\(toName)"

            if let existingBone = boneNodes[boneKey] {
                existingBone.removeFromParentNode()
            }

            // Use the lower opacity of the two joints for bone confidence
            let minOpacity = min(fromNode.opacity, toNode.opacity)
            let bone = createBoneNode(
                from: fromNode.position,
                to: toNode.position,
                confidence: Double(minOpacity)
            )
            bone.name = "bone_\(boneKey)"
            scene.rootNode.addChildNode(bone)
            boneNodes[boneKey] = bone
        }
    }

    /// Create a cylinder connecting two 3D points (representing a bone).
    /// Radius scales from 0.004 (low confidence) to 0.008 (high confidence).
    private func createBoneNode(from: SCNVector3, to: SCNVector3, confidence: Double = 1.0) -> SCNNode {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let distance = sqrt(dx * dx + dy * dy + dz * dz)

        // Scale bone thickness: 0.004 at low conf → 0.008 at full conf
        let boneRadius = 0.004 + 0.004 * CGFloat(confidence)
        let cylinder = SCNCylinder(radius: boneRadius, height: CGFloat(distance))
        cylinder.firstMaterial?.diffuse.contents = UIColor(white: 0.8, alpha: CGFloat(confidence * 0.8))
        cylinder.firstMaterial?.lightingModel = .physicallyBased

        let node = SCNNode(geometry: cylinder)

        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )

        node.look(at: SCNVector3(to.x, to.y, to.z), up: scene.rootNode.worldUp, localFront: SCNVector3(0, 1, 0))

        return node
    }

    /// Color-code joints by body region for visual clarity.
    private func jointColor(for name: String) -> UIColor {
        if name.contains("shoulder") || name.contains("elbow") || name.contains("wrist") {
            return UIColor(red: 0.14, green: 0.38, blue: 0.64, alpha: 1.0) // Blue - arms
        } else if name.contains("hip") || name.contains("knee") || name.contains("ankle") || name.contains("foot") {
            return UIColor(red: 0.1, green: 0.5, blue: 0.22, alpha: 1.0)   // Green - legs
        } else if name.contains("spine") || name == "root" || name.contains("center") {
            return UIColor(red: 0.85, green: 0.12, blue: 0.16, alpha: 1.0) // Red - torso
        }
        return UIColor(red: 0.03, green: 0.74, blue: 0.73, alpha: 1.0)     // Teal - other
    }

    // MARK: - Camera Control

    func setCamera(args: [String: Any]) {
        let x = Float(args["x"] as? Double ?? 0)
        let y = Float(args["y"] as? Double ?? 1.0)
        let z = Float(args["z"] as? Double ?? 3.0)

        if let cameraNode = scene.rootNode.childNode(withName: "defaultCamera", recursively: false) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            cameraNode.position = SCNVector3(x, y, z)

            if let pitch = args["pitch"] as? Double,
               let yaw = args["yaw"] as? Double {
                cameraNode.eulerAngles = SCNVector3(
                    Float(pitch * .pi / 180),
                    Float(yaw * .pi / 180),
                    0
                )
            } else {
                cameraNode.look(at: SCNVector3(0, 0.8, 0))
            }
            SCNTransaction.commit()
        }
    }

    // MARK: - Lighting

    func setLighting(args: [String: Any]) {
        let type = args["type"] as? String ?? "directional"
        let intensity = args["intensity"] as? Double ?? 800

        if let keyLight = scene.rootNode.childNode(withName: "keyLight", recursively: false) {
            keyLight.light?.type = SCNLight.LightType(rawValue: type)
            keyLight.light?.intensity = CGFloat(intensity)

            if let colorHex = args["color"] as? Int {
                keyLight.light?.color = UIColor(
                    red: CGFloat((colorHex >> 16) & 0xFF) / 255,
                    green: CGFloat((colorHex >> 8) & 0xFF) / 255,
                    blue: CGFloat(colorHex & 0xFF) / 255,
                    alpha: 1.0
                )
            }
        }
    }

    // MARK: - Animation

    func animate(name: String) {
        guard let modelNode = skeletonNode else { return }

        // Search for named animations in the loaded scene
        modelNode.enumerateChildNodes { node, _ in
            if let animationKeys = node.animationKeys as? [String] {
                for key in animationKeys where key.localizedCaseInsensitiveContains(name) {
                    if let player = node.animationPlayer(forKey: key) {
                        player.play()
                        return
                    }
                }
            }
        }
    }

    // MARK: - Reset

    func resetScene() {
        // Remove all joints and bones
        for (_, node) in jointNodes { node.removeFromParentNode() }
        for (_, node) in boneNodes { node.removeFromParentNode() }
        jointNodes.removeAll()
        boneNodes.removeAll()
        smoothedPositions.removeAll()

        // Remove loaded model
        skeletonNode?.removeFromParentNode()
        skeletonNode = nil
    }
}
