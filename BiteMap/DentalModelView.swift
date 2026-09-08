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
        uiView.scene?.rootNode.scale = SCNVector3(currentScale, currentScale, currentScale)
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
            let hitResults = scnView.hitTest(location, options: [:])
            guard let firstHit = hitResults.first else { return }

            Task { @MainActor in
                self.parent.viewModel.handleNodeTapped(firstHit.node, at: firstHit.localCoordinates)
            }
        }

        /// Continuously hit-tests during a pan gesture to support drag-to-paint marker placement.
        @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
            guard let scnView = gestureRecognize.view as? SCNView,
                  parent.viewModel.markerModeActive else { return }
            let location = gestureRecognize.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            guard let firstHit = hitResults.first else { return }

            Task { @MainActor in
                self.parent.viewModel.handleNodeTapped(firstHit.node, at: firstHit.localCoordinates)
            }
        }
    }
}
