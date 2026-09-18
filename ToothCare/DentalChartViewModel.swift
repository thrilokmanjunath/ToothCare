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
    
    var patients: [PatientProfile] = []
    var currentPatientId: UUID?
    
    var activePatient: PatientProfile? {
        patients.first { $0.id == currentPatientId }
    }
    
    // New properties
    var currentPainLevel: Double = 5.0
    var currentDiagnosis: DiagnosisType = .pain
    var currentNote: String = ""
    var isXRayMode: Bool = false
    var resetCameraTrigger: Int = 0
    var refreshTrigger: Int = 0

    func resetCamera() {
        resetCameraTrigger += 1
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
        "Xander_file_UpperJaw": "Upper Jaw (Gums)",
        "Xander_file_LowerJaw": "Lower Jaw (Gums)",
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

    private var toothMappingReversed: [String: String] {
        var reversed: [String: String] = [:]
        for (key, value) in toothMapping {
            reversed[value] = key
        }
        return reversed
    }

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
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        
        switch diagnosis {
        case .pain:
            let intensity = CGFloat(painLevel / 10.0)
            material.diffuse.contents = UIColor(red: 1.0, green: 1.0 - intensity, blue: 0.0, alpha: 1.0)
            material.emission.contents = UIColor(red: 0.5 * intensity, green: 0, blue: 0, alpha: 1.0)
        case .cavity:
            material.diffuse.contents = UIColor(white: 0.1, alpha: 1.0)
            material.roughness.contents = NSNumber(value: 0.9)
        case .plaque:
            material.diffuse.contents = UIColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 0.8)
            material.roughness.contents = NSNumber(value: 0.6)
        case .fracture:
            material.diffuse.contents = UIColor.darkGray
            material.metalness.contents = NSNumber(value: 0.8)
            material.roughness.contents = NSNumber(value: 0.2)
        case .missing:
            break
        case .gumDisease:
            material.diffuse.contents = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 0.8)
            material.emission.contents = UIColor(red: 0.2, green: 0.0, blue: 0.0, alpha: 1.0)
        case .abscess:
            material.diffuse.contents = UIColor.green
            material.emission.contents = UIColor(red: 0.0, green: 0.8, blue: 0.2, alpha: 1.0)
        case .impacted:
            material.diffuse.contents = UIColor.purple
            material.transparent.contents = UIColor(white: 1.0, alpha: 0.4)
            material.blendMode = .add
            material.isDoubleSided = true
        case .crown:
            material.diffuse.contents = UIColor.white
            material.metalness.contents = NSNumber(value: 1.0)
            material.roughness.contents = NSNumber(value: 0.1)
        }
        
        node.geometry?.materials = [material]
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
            node.opacity = 0.0
        } else if currentDiagnosis == .gumDisease || currentDiagnosis == .impacted || currentDiagnosis == .crown {
            if currentDiagnosis == .impacted {
                node.eulerAngles = SCNVector3(x: .pi / 2, y: 0, z: 0)
            }
            applyDiagnosisMaterial(to: node, diagnosis: currentDiagnosis, painLevel: currentPainLevel)
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

    // MARK: - NLP Processing
    
    func processClinicalSummary(text: String) {
        let results = NLPParser.parse(summary: text)
        
        for result in results {
            guard let rawNodeName = toothMappingReversed[result.toothName] else { continue }
            
            // To place the marker, we need its 3D location. We will set it to (0,0,0) initially,
            // and the `restore3DMarkers` function will calculate the true bounding box center.
            let newMarker = PainMarkerModel(
                rawNodeName: rawNodeName,
                tooth: result.toothName,
                codableLocation: CodableVector3(SCNVector3Zero),
                painLevel: 5,
                diagnosis: result.diagnosis,
                note: "AI Extracted: \"\(result.originalSentence)\""
            )
            savedMarkers.append(newMarker)
        }
        
        saveData()
        
        // Trigger a full scene rebuild so the new markers are visually placed
        refreshTrigger += 1
    }

    // MARK: - Marker Management

    func clearAllMarkers() {
        markerNodes.forEach { $0.removeFromParentNode() }
        markerNodes.removeAll()
        
        if let root = selectedNode?.parent?.parent { // Approximate root access
            for rawName in toothMapping.keys {
                if let toothNode = root.childNode(withName: rawName, recursively: true) {
                    toothNode.opacity = 1.0
                    let material = SCNMaterial()
                    material.lightingModel = .physicallyBased
                    if rawName == "Xander_file_UpperJaw" || rawName == "Xander_file_LowerJaw" {
                        material.diffuse.contents = UIColor(red: 0.9, green: 0.6, blue: 0.6, alpha: 1.0)
                        material.roughness.contents = NSNumber(value: 0.4)
                    } else {
                        material.diffuse.contents = UIColor.white
                    }
                    toothNode.geometry?.materials = [material]
                    toothNode.eulerAngles = SCNVector3Zero
                }
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
        markerNodes.forEach { $0.removeFromParentNode() }
        markerNodes.removeAll()
        
        // Reset all base teeth and jaws to default state
        for rawName in toothMapping.keys {
            if let toothNode = rootNode.childNode(withName: rawName, recursively: true) {
                toothNode.opacity = 1.0
                toothNode.eulerAngles = SCNVector3Zero
                let material = SCNMaterial()
                material.lightingModel = .physicallyBased
                if rawName == "Xander_file_UpperJaw" || rawName == "Xander_file_LowerJaw" {
                    material.diffuse.contents = UIColor(red: 0.9, green: 0.6, blue: 0.6, alpha: 1.0) // Gum Pink
                    material.roughness.contents = NSNumber(value: 0.4)
                } else {
                    material.diffuse.contents = UIColor.white
                }
                toothNode.geometry?.materials = [material]
            }
        }
        
        // Hide missing teeth, then add spheres for others
        for marker in savedMarkers {
            guard let toothNode = rootNode.childNode(withName: marker.rawNodeName, recursively: true) else { continue }
            
            if marker.diagnosis == .missing {
                toothNode.opacity = 0.0
            } else if marker.diagnosis == .gumDisease || marker.diagnosis == .impacted || marker.diagnosis == .crown {
                if marker.diagnosis == .impacted {
                    toothNode.eulerAngles = SCNVector3(x: .pi / 2, y: 0, z: 0)
                }
                applyDiagnosisMaterial(to: toothNode, diagnosis: marker.diagnosis, painLevel: Double(marker.painLevel))
            } else {
                let shape: SCNGeometry = marker.diagnosis == .cavity ? SCNBox(width: 0.08, height: 0.08, length: 0.08, chamferRadius: 0) : SCNSphere(radius: 0.05)
                let markerNode = SCNNode(geometry: shape)
                applyDiagnosisMaterial(to: markerNode, diagnosis: marker.diagnosis, painLevel: Double(marker.painLevel))
                
                // If it's an AI generated marker, its location is (0,0,0). We need to center it on the tooth.
                if marker.location.x == 0 && marker.location.y == 0 && marker.location.z == 0 {
                    let (min, max) = toothNode.boundingBox
                    let center = SCNVector3(
                        x: (max.x + min.x) / 2,
                        y: (max.y + min.y) / 2,
                        z: (max.z + min.z) / 2
                    )
                    markerNode.position = center
                } else {
                    markerNode.position = marker.location
                }
                
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
            
            if let patient = activePatient {
                Text("Patient: \(patient.name) (Age: \(patient.age))")
                    .font(.title2)
            }
            
            Text("Date: \(Date().formatted(date: .abbreviated, time: .shortened))")
                .padding(.bottom, 20)
            
            ForEach(savedMarkers) { marker in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(marker.tooth).font(.headline)
                        if !marker.note.isEmpty {
                            Text("Note: \(marker.note)").font(.subheadline).foregroundColor(.secondary)
                        }
                        Text("Treatment: \(marker.diagnosis.suggestedTreatment)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
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
        if let id = currentPatientId, let idx = patients.firstIndex(where: { $0.id == id }) {
            patients[idx].markers = savedMarkers
            patients[idx].lastVisit = Date()
        }
        
        guard let encoded = try? JSONEncoder().encode(patients) else { return }
        UserDefaults.standard.set(encoded, forKey: "ToothCare_Patients_v2")
        
        if let id = currentPatientId {
            UserDefaults.standard.set(id.uuidString, forKey: "ToothCare_CurrentPatient_v2")
        }
    }

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "ToothCare_Patients_v2"),
           let decoded = try? JSONDecoder().decode([PatientProfile].self, from: data) {
            patients = decoded
        }
        
        if let idString = UserDefaults.standard.string(forKey: "ToothCare_CurrentPatient_v2"),
           let id = UUID(uuidString: idString) {
            currentPatientId = id
        } else {
            if patients.isEmpty {
                let defaultPatient = PatientProfile(name: "John Doe", age: "45")
                patients.append(defaultPatient)
                currentPatientId = defaultPatient.id
            } else {
                currentPatientId = patients.first?.id
            }
        }
        
        if let active = patients.first(where: { $0.id == currentPatientId }) {
            savedMarkers = active.markers
        }
    }
    
    // MARK: - Patient Management
    
    func addPatient(name: String, age: String) {
        let new = PatientProfile(name: name, age: age)
        patients.append(new)
        switchPatient(to: new.id)
    }
    
    func switchPatient(to id: UUID) {
        currentPatientId = id
        if let active = patients.first(where: { $0.id == id }) {
            savedMarkers = active.markers
            refreshTrigger += 1
        }
        saveData()
    }
    
    func deletePatient(id: UUID) {
        patients.removeAll { $0.id == id }
        if currentPatientId == id {
            if let first = patients.first {
                switchPatient(to: first.id)
            } else {
                addPatient(name: "New Patient", age: "30")
            }
        } else {
            saveData()
        }
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
