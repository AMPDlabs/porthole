import Foundation

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

    /// Best available display name: process name > registry name > "?"
    var displayName: String {
        name != "?" ? name : (serviceName ?? "?")
    }
}
