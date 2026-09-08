import Foundation
import SceneKit

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
    var painLevel: Int

    var location: SCNVector3 {
        codableLocation.scnVector
    }
}
