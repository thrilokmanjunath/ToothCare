import Foundation
import SceneKit
import SwiftUI

/// Types of dental conditions that can be logged.
enum DiagnosisType: String, Codable, Sendable, CaseIterable {
    case pain = "Pain"
    case cavity = "Cavity"
    case plaque = "Plaque"
    case fracture = "Fracture"
    case missing = "Missing Tooth"

    var color: Color {
        switch self {
        case .pain: return .red
        case .cavity: return .black
        case .plaque: return .yellow
        case .fracture: return .blue
        case .missing: return .clear
        }
    }
    
    var uiColor: UIColor {
        UIColor(color)
    }
}

/// A `Codable` bridge for `SCNVector3`, which does not conform to `Codable` natively.
struct CodableVector3: Codable, Sendable {
    let x: Float
    let y: Float
    let z: Float

    init(_ vector: SCNVector3) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }

    var scnVector: SCNVector3 {
        SCNVector3(x, y, z)
    }
}

struct PainMarkerModel: Identifiable, Codable, Sendable {
    var id = UUID()
    let rawNodeName: String
    let tooth: String
    let codableLocation: CodableVector3
    var painLevel: Int // Kept for backwards compatibility if needed, or used just for 'Pain' type
    var diagnosis: DiagnosisType
    var note: String
    
    var location: SCNVector3 {
        codableLocation.scnVector
    }
}
