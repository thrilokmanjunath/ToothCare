import SwiftUI
import SceneKit

struct DentalModelView: UIViewRepresentable {

    // MARK: - Properties

    @Binding var zoomMultiplier: Float
    var viewModel: DentalChartViewModel
    let baseScale: Float = 0.01

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        guard let scene = SCNScene(named: "Teeth.usdz") else {
            return scnView
        }

        scene.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            node.geometry?.firstMaterial?.lightingModel = .physicallyBased
        }

        scene.rootNode.scale = SCNVector3(baseScale, baseScale, baseScale)
        viewModel.restore3DMarkers(to: scene.rootNode)

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 1.5)
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode

        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.scene = scene

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePan(_:))
        )
        context.coordinator.drawGesture = panGesture
        scnView.addGestureRecognizer(panGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let currentScale = baseScale * zoomMultiplier
        uiView.allowsCameraControl = !viewModel.markerModeActive
        context.coordinator.drawGesture?.isEnabled = viewModel.markerModeActive
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        
        // Handle Scale
        uiView.scene?.rootNode.scale = SCNVector3(currentScale, currentScale, currentScale)
        
        // Handle X-Ray Mode
        if let scene = uiView.scene {
            // Apply X-Ray or default materials specifically to the root nodes (avoiding our custom markers which are child nodes)
            // The USDZ structure typically has the main mesh nodes one level deep, so we enumerate those.
            scene.rootNode.enumerateChildNodes { node, _ in
                // Only modify the base teeth nodes, not the markers (which don't have "Xander" in name or have spheres)
                if let name = node.name, name.contains("Xander") {
                    if let material = node.geometry?.firstMaterial {
                        if viewModel.isXRayMode {
                            material.diffuse.contents = UIColor(white: 0.8, alpha: 0.3)
                            material.transparent.contents = UIColor(white: 1.0, alpha: 0.3)
                            material.blendMode = .add
                            material.isDoubleSided = true
                            material.writesToDepthBuffer = false
                        } else {
                            // Restore defaults, or blue if selected
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
        
        SCNTransaction.commit()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: DentalModelView
        var drawGesture: UIPanGestureRecognizer?

        init(_ parent: DentalModelView) {
            self.parent = parent
        }

        /// Performs a SceneKit hit-test at the tap location and forwards the result to the view model.
        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            guard let scnView = gestureRecognize.view as? SCNView else { return }
            let location = gestureRecognize.location(in: scnView)
            
            // In X-Ray mode, hit testing transparent objects might need specific options.
            // Search back to front
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            // Find the first hit that is an actual tooth mesh (ignoring markers or background)
            if let hit = hitResults.first(where: { $0.node.name?.contains("Xander") == true }) {
                Task { @MainActor in
                    self.parent.viewModel.handleNodeTapped(hit.node, at: hit.localCoordinates)
                }
            }
        }

        /// Continuously hit-tests during a pan gesture to support drag-to-paint marker placement.
        @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
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
    }
}
