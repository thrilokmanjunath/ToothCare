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
    
    // New properties
    var currentPainLevel: Double = 5.0
    var currentDiagnosis: DiagnosisType = .pain
    var currentNote: String = ""
    var isXRayMode: Bool = false {
        didSet {
            // Re-apply material on selected node if needed, or notify the view.
            // X-Ray material changes are handled directly in DentalModelView.updateUIView.
        }
    }

    var chartSummaries: [ChartSummary] {
        savedMarkers.reduce(into: [ChartSummary]()) { summaries, marker in
            if !summaries.contains(where: { $0.tooth == marker.tooth && $0.diagnosis == marker.diagnosis }) {
                summaries.append(ChartSummary(
                    tooth: marker.tooth, 
                    painLevel: marker.painLevel,
                    diagnosis: marker.diagnosis,
                    note: marker.note
                ))
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

    private func applyDiagnosisMaterial(to node: SCNNode, diagnosis: DiagnosisType, painLevel: Double) {
        if diagnosis == .missing {
            // Handled separately by hiding the parent node
            return
        }
        
        node.geometry?.firstMaterial?.diffuse.contents = diagnosis == .pain 
            ? UIColor(red: 1.0, green: 1.0 - (CGFloat(painLevel) / 10.0), blue: 0.0, alpha: 1.0)
            : diagnosis.uiColor
    }

    private func placeMarker(on node: SCNNode, at location: SCNVector3) {
        let rawName = node.name ?? "Unknown"
        let toothName = toothMapping[rawName] ?? rawName
        
        let newMarker = PainMarkerModel(
            rawNodeName: rawName,
            tooth: toothName,
            codableLocation: CodableVector3(location),
            painLevel: Int(currentPainLevel),
            diagnosis: currentDiagnosis,
            note: currentNote
        )

        if currentDiagnosis == .missing {
            // Hide the tooth and don't place a sphere
            node.opacity = 0.0
        } else {
            let shape: SCNGeometry = currentDiagnosis == .cavity ? SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0) : SCNSphere(radius: 0.05)
            let markerNode = SCNNode(geometry: shape)
            applyDiagnosisMaterial(to: markerNode, diagnosis: currentDiagnosis, painLevel: currentPainLevel)
            markerNode.position = location
            node.addChildNode(markerNode)
            markerNodes.append(markerNode)
        }
        
        savedMarkers.append(newMarker)
        saveData()
    }

    private func selectTooth(_ node: SCNNode) {
        // Reset previous selection unless it's missing or in X-Ray mode (which overrides materials later)
        selectedNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        
        if node.opacity > 0 {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemBlue
        }
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
        
        // Restore missing teeth
        for marker in savedMarkers where marker.diagnosis == .missing {
            if let root = selectedNode?.parent?.parent { // Approximate root access
                root.childNode(withName: marker.rawNodeName, recursively: true)?.opacity = 1.0
            }
        }
        
        savedMarkers.removeAll()
        saveData()
    }

    func deleteSummary(at offsets: IndexSet) {
        for index in offsets {
            let target = chartSummaries[index]
            let matchingIndices = savedMarkers.indices.filter {
                savedMarkers[$0].tooth == target.tooth && savedMarkers[$0].diagnosis == target.diagnosis
            }
            
            for i in matchingIndices.reversed() {
                let marker = savedMarkers[i]
                if marker.diagnosis == .missing {
                    // We need to restore opacity. The nodes aren't in markerNodes.
                    // We will rely on restore3DMarkers or a full refresh, 
                    // but for now, this simple app just needs the data removed.
                } else {
                    markerNodes[i].removeFromParentNode()
                    markerNodes.remove(at: i)
                }
                savedMarkers.remove(at: i)
            }
        }
        saveData()
    }

    // MARK: - Scene Restoration

    func restore3DMarkers(to rootNode: SCNNode) {
        markerNodes.removeAll()
        for marker in savedMarkers {
            guard let toothNode = rootNode.childNode(withName: marker.rawNodeName, recursively: true) else { continue }
            
            if marker.diagnosis == .missing {
                toothNode.opacity = 0.0
            } else {
                let shape: SCNGeometry = marker.diagnosis == .cavity ? SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0) : SCNSphere(radius: 0.05)
                let markerNode = SCNNode(geometry: shape)
                applyDiagnosisMaterial(to: markerNode, diagnosis: marker.diagnosis, painLevel: Double(marker.painLevel))
                markerNode.position = marker.location
                toothNode.addChildNode(markerNode)
                markerNodes.append(markerNode)
            }
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(marker.tooth).font(.headline)
                        if !marker.note.isEmpty {
                            Text("Note: \(marker.note)").font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(marker.diagnosis.rawValue)
                            .fontWeight(.bold)
                            .foregroundColor(marker.diagnosis.color)
                        if marker.diagnosis == .pain {
                            Text("Level: \(marker.painLevel)")
                                .foregroundColor(marker.painLevel > 5 ? .red : .orange)
                        }
                    }
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
        UserDefaults.standard.set(encoded, forKey: "ToothCare_SavedChart_v2")
    }

    func loadData() {
        guard let data = UserDefaults.standard.data(forKey: "ToothCare_SavedChart_v2"),
              let decoded = try? JSONDecoder().decode([PainMarkerModel].self, from: data) else { return }
        savedMarkers = decoded
    }
}

// MARK: - ChartSummary

struct ChartSummary: Identifiable {
    let id = UUID()
    let tooth: String
    let painLevel: Int
    let diagnosis: DiagnosisType
    let note: String
}
