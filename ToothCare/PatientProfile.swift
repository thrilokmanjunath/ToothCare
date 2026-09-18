import Foundation

struct PatientProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var age: String
    var lastVisit: Date = Date()
    var markers: [PainMarkerModel] = []
}
