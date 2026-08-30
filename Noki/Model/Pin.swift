import Foundation

struct Pin: Codable, Identifiable, Equatable {
    var id: String { uri }
    let name: String
    let uri: String
}

