import SwiftUI
import SceneKit

@Observable
@MainActor
final class DentalChartViewModel {

    // MARK: - Properties

    var selectedToothName: String = "No Tooth Selected"
    var markerModeActive: Bool = false
    var selectedNode: SCNNode?
    var savedMarkers: [PainMarkerModel] = []
    var markerNodes: [SCNNode] = []
    var currentPainLevel: Double = 5.0

    var chartSummaries: [ChartSummary] {
        savedMarkers.reduce(into: [ChartSummary]()) { summaries, marker in
            if !summaries.contains(where: { $0.tooth == marker.tooth && $0.painLevel == marker.painLevel }) {
                summaries.append(ChartSummary(tooth: marker.tooth, painLevel: marker.painLevel))
            }
        }
    }

    private let toothMapping: [String: String] = [
        "Xander_file_UpperJaw_001": "Tooth 18",
        "Xander_file_UpperJaw_002": "Tooth 19",
        "Xander_file_UpperJaw_004": "Tooth 20",
        "Xander_file_UpperJaw_006": "Tooth 21",
        "Xander_file_UpperJaw_007": "Tooth 22",
        "Xander_file_UpperJaw_008": "Tooth 23",
        "Xander_file_UpperJaw_009": "Tooth 24",
        "Xander_file_UpperJaw_010": "Tooth 25",
        "Xander_file_UpperJaw_011": "Tooth 26",
        "Xander_file_UpperJaw_012": "Tooth 27",
        "Xander_file_UpperJaw_013": "Tooth 28",
        "Xander_file_UpperJaw_014": "Tooth 29",
        "Xander_file_UpperJaw_015": "Tooth 30",
        "Xander_file_UpperJaw_016": "Tooth 31",
        "Xander_file_LowerJaw_001": "Tooth 2",
        "Xander_file_LowerJaw_002": "Tooth 3",
        "Xander_file_LowerJaw_003": "Tooth 4",
        "Xander_file_LowerJaw_004": "Tooth 5",
        "Xander_file_LowerJaw_005": "Tooth 6",
        "Xander_file_LowerJaw_006": "Tooth 7",
        "Xander_file_LowerJaw_007": "Tooth 8",
        "Xander_file_LowerJaw_008": "Tooth 9",
        "Xander_file_LowerJaw_009": "Tooth 10",
        "Xander_file_LowerJaw_010": "Tooth 11",
        "Xander_file_LowerJaw_011": "Tooth 12",
        "Xander_file_LowerJaw_012": "Tooth 13",
        "Xander_file_LowerJaw_013": "Tooth 14",
        "Xander_file_LowerJaw_014": "Tooth 15"
    ]

    // MARK: - Lifecycle

    init() {
        loadData()
    }

    // MARK: - Interaction Handling

    func handleNodeTapped(_ tappedNode: SCNNode, at location: SCNVector3) {
        if markerModeActive {
            placeMarker(on: tappedNode, at: location)
        } else {
            selectTooth(tappedNode)
        }
    }

    private func placeMarker(on node: SCNNode, at location: SCNVector3) {
        let painFraction = CGFloat(currentPainLevel) / 10.0
        let sphere = SCNSphere(radius: 0.05)
        sphere.firstMaterial?.diffuse.contents = UIColor(
            red: 1.0,
            green: 1.0 - painFraction,
            blue: 0.0,
            alpha: 1.0
        )
        let markerNode = SCNNode(geometry: sphere)
        markerNode.position = location
        node.addChildNode(markerNode)
        markerNodes.append(markerNode)

        let rawName = node.name ?? "Unknown"
        let newMarker = PainMarkerModel(
            rawNodeName: rawName,
            tooth: toothMapping[rawName] ?? rawName,
            codableLocation: CodableVector3(location),
            painLevel: Int(currentPainLevel)
        )
        savedMarkers.append(newMarker)
        saveData()
    }

    private func selectTooth(_ node: SCNNode) {
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        selectedNode = node

        if let nodeName = node.name, let medicalName = toothMapping[nodeName] {
            selectedToothName = medicalName
        } else {
            selectedToothName = "Unknown Tooth: \(node.name ?? "No Name")"
        }
    }

    // MARK: - Marker Management

    func clearAllMarkers() {
        markerNodes.forEach { $0.removeFromParentNode() }
        markerNodes.removeAll()
        savedMarkers.removeAll()
        saveData()
    }

    func deleteSummary(at offsets: IndexSet) {
        for index in offsets {
            let target = chartSummaries[index]
            let matchingIndices = savedMarkers.indices.filter {
                savedMarkers[$0].tooth == target.tooth && savedMarkers[$0].painLevel == target.painLevel
            }
            // Reverse deletion preserves index validity as the array shrinks.
            for i in matchingIndices.reversed() {
                markerNodes[i].removeFromParentNode()
                markerNodes.remove(at: i)
                savedMarkers.remove(at: i)
            }
        }
        saveData()
    }

    // MARK: - Scene Restoration

    /// Rebuilds pain marker nodes from persisted data after the SceneKit scene is initialized.
    func restore3DMarkers(to rootNode: SCNNode) {
        markerNodes.removeAll()
        for marker in savedMarkers {
            guard let toothNode = rootNode.childNode(withName: marker.rawNodeName, recursively: true) else { continue }
            let painFraction = CGFloat(marker.painLevel) / 10.0
            let sphere = SCNSphere(radius: 0.05)
            sphere.firstMaterial?.diffuse.contents = UIColor(
                red: 1.0,
                green: 1.0 - painFraction,
                blue: 0.0,
                alpha: 1.0
            )
            let markerNode = SCNNode(geometry: sphere)
            markerNode.position = marker.location
            toothNode.addChildNode(markerNode)
            markerNodes.append(markerNode)
        }
    }

    // MARK: - PDF Export

    func generatePDF() -> URL? {
        let content = VStack(alignment: .leading, spacing: 10) {
            Text("ToothCare Patient Chart")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 20)
            Text("Date: \(Date().formatted(date: .abbreviated, time: .shortened))")
                .padding(.bottom, 20)
            ForEach(savedMarkers) { marker in
                HStack {
                    Text(marker.tooth).font(.headline)
                    Spacer()
                    Text("Pain Level: \(marker.painLevel)")
                        .foregroundColor(marker.painLevel > 5 ? .red : .orange)
                }
                Divider()
            }
        }
        .padding(40)
        .frame(width: 612, height: 792)

        let renderer = ImageRenderer(content: content)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PatientChart.pdf")

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }
        return url
    }

    // MARK: - Persistence

    func saveData() {
        guard let encoded = try? JSONEncoder().encode(savedMarkers) else { return }
        UserDefaults.standard.set(encoded, forKey: "ToothCare_SavedChart")
    }

    func loadData() {
        guard let data = UserDefaults.standard.data(forKey: "ToothCare_SavedChart"),
              let decoded = try? JSONDecoder().decode([PainMarkerModel].self, from: data) else { return }
        savedMarkers = decoded
    }
}

// MARK: - ChartSummary

struct ChartSummary: Identifiable {
    let id = UUID()
    let tooth: String
    let painLevel: Int
}
