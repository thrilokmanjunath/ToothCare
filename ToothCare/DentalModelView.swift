import SwiftUI
import SceneKit

struct DentalModelView: UIViewRepresentable {

    // MARK: - Properties

    var viewModel: DentalChartViewModel

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        guard let scene = SCNScene(named: "Teeth.usdz") else {
            return scnView
        }

        // Apply basic materials
        scene.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.geometry?.firstMaterial?.lightingModel = .physicallyBased
        }

        // 1. Auto-Framing and Centering
        let (min, max) = scene.rootNode.boundingBox
        let center = SCNVector3(
            x: (max.x + min.x) / 2,
            y: (max.y + min.y) / 2,
            z: (max.z + min.z) / 2
        )
        // Set pivot so the node rotates around its true center
        scene.rootNode.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        
        // Find maximum dimension to scale it nicely into view
        let maxDim = Swift.max(max.x - min.x, max.y - min.y, max.z - min.z)
        let desiredSize: Float = 2.0 // Fits well in the camera view
        let scale = desiredSize / maxDim
        scene.rootNode.scale = SCNVector3(scale, scale, scale)
        
        // Save base scale in coordinator for pinch gesture
        context.coordinator.baseScale = scale

        // 2. Studio Lighting
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 500
        scene.rootNode.addChildNode(ambientLightNode)

        let directionalLightNode = SCNNode()
        directionalLightNode.light = SCNLight()
        directionalLightNode.light?.type = .directional
        directionalLightNode.light?.castsShadow = true
        directionalLightNode.light?.shadowSampleCount = 8
        directionalLightNode.light?.shadowMode = .deferred
        directionalLightNode.position = SCNVector3(x: 5, y: 10, z: 10)
        directionalLightNode.eulerAngles = SCNVector3(x: -.pi / 4, y: .pi / 4, z: 0)
        scene.rootNode.addChildNode(directionalLightNode)

        // 3. Camera Setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3.5)
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode

        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false // Using our custom lighting
        scnView.scene = scene
        
        viewModel.restore3DMarkers(to: scene.rootNode)

        // 4. Gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        context.coordinator.drawGesture = panGesture
        scnView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        // Allow pinch to work simultaneously with pan/rotation
        pinchGesture.delegate = context.coordinator
        scnView.addGestureRecognizer(pinchGesture)

        // 5. Idle Rotation Animation
        let spin = CABasicAnimation(keyPath: "rotation")
        // Rotate around Y axis
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi * 2))
        spin.duration = 20.0
        spin.repeatCount = .infinity
        scene.rootNode.addAnimation(spin, forKey: "idleSpin")
        context.coordinator.idleSpinAnimation = spin
        context.coordinator.rootNode = scene.rootNode

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Disable built-in camera control (rotation) if we are in marker mode,
        // but keep pinch gesture enabled via our custom handler.
        uiView.allowsCameraControl = !viewModel.markerModeActive
        context.coordinator.drawGesture?.isEnabled = viewModel.markerModeActive
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        
        // Handle X-Ray Mode
        if let scene = uiView.scene {
            scene.rootNode.enumerateChildNodes { node, _ in
                if let name = node.name, name.contains("Xander") {
                    if let material = node.geometry?.firstMaterial {
                        if viewModel.isXRayMode {
                            material.diffuse.contents = UIColor(white: 0.8, alpha: 0.3)
                            material.transparent.contents = UIColor(white: 1.0, alpha: 0.3)
                            material.blendMode = .add
                            material.isDoubleSided = true
                            material.writesToDepthBuffer = false
                        } else {
                            if node == viewModel.selectedNode {
                                material.diffuse.contents = UIColor.systemBlue
                            } else {
                                material.diffuse.contents = UIColor.white
                            }
                            material.transparent.contents = UIColor.white
                            material.blendMode = .alpha
                            material.isDoubleSided = false
                            material.writesToDepthBuffer = true
                        }
                    }
                }
            }
        }
        // Handle Reset Camera
        if context.coordinator.lastResetTrigger != viewModel.resetCameraTrigger {
            context.coordinator.lastResetTrigger = viewModel.resetCameraTrigger
            
            // Reset rotation/translation handled by SceneKit's camera controller
            uiView.defaultCameraController.clearRoll()
            uiView.pointOfView?.transform = SCNMatrix4Identity
            uiView.pointOfView?.position = SCNVector3(0, 0, 3.5)
            
            // Reset our custom pinch scale
            let base = context.coordinator.baseScale
            context.coordinator.currentScale = base
            uiView.scene?.rootNode.scale = SCNVector3(base, base, base)
            
            // Also reset pivot/rotation if they somehow messed it up
            uiView.scene?.rootNode.transform = SCNMatrix4Identity
            // Need to re-apply pivot centering
            if let root = uiView.scene?.rootNode {
                let (min, max) = root.boundingBox
                let center = SCNVector3(
                    x: (max.x + min.x) / 2,
                    y: (max.y + min.y) / 2,
                    z: (max.z + min.z) / 2
                )
                root.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
                root.scale = SCNVector3(base, base, base)
            }
        }
        
        // Handle external marker updates (like NLP AI)
        if context.coordinator.lastRefreshTrigger != viewModel.refreshTrigger {
            context.coordinator.lastRefreshTrigger = viewModel.refreshTrigger
            if let root = uiView.scene?.rootNode {
                viewModel.restore3DMarkers(to: root)
            }
        }
        
        SCNTransaction.commit()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: DentalModelView
        var drawGesture: UIPanGestureRecognizer?
        var baseScale: Float = 1.0
        var currentScale: Float = 1.0
        var lastResetTrigger: Int = 0
        var lastRefreshTrigger: Int = 0
        var idleSpinAnimation: CABasicAnimation?
        var rootNode: SCNNode?

        init(_ parent: DentalModelView) {
            self.parent = parent
        }
        
        private func stopIdleAnimation() {
            if rootNode?.animation(forKey: "idleSpin") != nil {
                // Remove the animation so the user takes over
                let currentTransform = rootNode?.presentation.transform
                rootNode?.removeAnimation(forKey: "idleSpin", blendOutDuration: 0.5)
                if let transform = currentTransform {
                    rootNode?.transform = transform
                }
            }
        }

        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            stopIdleAnimation()
            guard let scnView = gestureRecognize.view as? SCNView else { return }
            let location = gestureRecognize.location(in: scnView)
            
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            if let hit = hitResults.first(where: { $0.node.name?.contains("Xander") == true }) {
                Task { @MainActor in
                    self.parent.viewModel.handleNodeTapped(hit.node, at: hit.localCoordinates)
                }
            }
        }

        @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
            stopIdleAnimation()
            guard let scnView = gestureRecognize.view as? SCNView,
                  parent.viewModel.markerModeActive else { return }
            let location = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            if let hit = hitResults.first(where: { $0.node.name?.contains("Xander") == true }) {
                Task { @MainActor in
                    self.parent.viewModel.handleNodeTapped(hit.node, at: hit.localCoordinates)
                }
            }
        }
        
        @objc func handlePinch(_ gestureRecognize: UIPinchGestureRecognizer) {
            stopIdleAnimation()
            guard let scnView = gestureRecognize.view as? SCNView, let node = rootNode else { return }
            
            if gestureRecognize.state == .changed {
                let pinchScale = Float(gestureRecognize.scale)
                let newScale = currentScale * pinchScale
                // Clamp scale to reasonable bounds
                let clampedScale = max(baseScale * 0.5, min(newScale, baseScale * 5.0))
                node.scale = SCNVector3(clampedScale, clampedScale, clampedScale)
            } else if gestureRecognize.state == .ended {
                currentScale = node.scale.x
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
