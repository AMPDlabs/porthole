import Foundation

enum ServerState {
    case active
    case new
    case departing
}

enum PortCategory: String, CaseIterable {
    case devServer = "Dev Servers"
    case database  = "Databases"
    case tool      = "Tools"
    case system    = "System"
    case unknown   = "Unknown"

}

struct ServerProcess: Identifiable, Equatable {
    let id: Int
    let pid: Int
    let name: String
    let port: Int
    var serviceName: String? = nil
    var category: PortCategory = .unknown
    var state: ServerState = .active

    /// Best available display name: process name > registry name > "?"
    var displayName: String {
        name != "?" ? name : (serviceName ?? "?")
    }

    static func == (lhs: ServerProcess, rhs: ServerProcess) -> Bool {
        lhs.id == rhs.id && lhs.pid == rhs.pid && lhs.name == rhs.name &&
        lhs.port == rhs.port && lhs.serviceName == rhs.serviceName &&
        lhs.category == rhs.category
    }
}
