import Foundation

struct ServerProcess: Identifiable, Equatable {
    let id: Int         // pid
    let pid: Int
    let name: String
    let port: Int
}
