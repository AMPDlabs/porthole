import Foundation
import Combine

@MainActor
final class PortScanner: ObservableObject {
    @Published var servers: [ServerProcess] = []
    private var timer: Timer?

    init() {
        start()
        // Also refresh when app becomes active
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        Task.detached(priority: .background) {
            let results = Self.scan()
            await MainActor.run {
                self.servers = results
            }
        }
    }

    static func scan() -> [ServerProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // suppress stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return parse(output: output)
    }

    static func parse(output: String) -> [ServerProcess] {
        // lsof output format:
        // COMMAND   PID  USER  FD  TYPE  DEVICE  SIZE/OFF  NODE  NAME
        // node     1234  max  24u  IPv4  ...      TCP *:3000 (LISTEN)
        var results: [ServerProcess] = []
        var seen = Set<Int>() // deduplicate by port

        let lines = output.components(separatedBy: "\n").dropFirst() // skip header
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }

            let name = String(parts[0])
            guard let pid = Int(parts[1]) else { continue }

            // NAME column is last — format: "*:3000" or "127.0.0.1:3000"
            let nameField = String(parts[parts.count - 1])
            guard let colonIdx = nameField.lastIndex(of: ":") else { continue }
            let portStr = String(nameField[nameField.index(after: colonIdx)...])
            guard let port = Int(portStr) else { continue }

            if seen.contains(port) { continue }
            seen.insert(port)

            results.append(ServerProcess(id: pid, pid: pid, name: name, port: port))
        }

        return results.sorted { $0.port < $1.port }
    }
}
