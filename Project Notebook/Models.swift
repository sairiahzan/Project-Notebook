import Foundation

struct Project: Identifiable, Hashable {
    var id: URL { url }
    let name: String
    let url: URL
    var versions: [Version] = []
}

struct Version: Identifiable, Hashable {
    var id: URL { url }
    let name: String
    let url: URL
    var features: [Feature] = []
}

struct Feature: Identifiable, Hashable {
    var id: URL { url }
    let name: String
    let url: URL
    var content: String = ""
}
