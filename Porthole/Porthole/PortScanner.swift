import Foundation
import AppKit
import Combine

@MainActor
final class PortScanner: ObservableObject {
    @Published var servers: [ServerProcess] = []
    private var timer: Timer?

    init() {
        start()
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        Task {
            let results = await Task.detached(priority: .background) {
                PortScanner.scan()
            }.value
            self.servers = results
        }
    }

    // MARK: - lsof (primary)

    nonisolated static func scan() -> [ServerProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-n", "-P"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return netstatScan()
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return netstatScan() }

        let results = parseLsof(output: output)
        return results.isEmpty ? netstatScan() : results
    }

    nonisolated static func parseLsof(output: String) -> [ServerProcess] {
        var results: [ServerProcess] = []
        var seen = Set<Int>()

        for line in output.components(separatedBy: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }
            let procName = String(parts[0])
            guard let pid = Int(parts[1]) else { continue }
            let nameField = String(parts[parts.count - 2])
            guard let colonIdx = nameField.lastIndex(of: ":") else { continue }
            let portStr = String(nameField[nameField.index(after: colonIdx)...])
            guard let port = Int(portStr) else { continue }
            guard port >= 1024, port <= 49151 else { continue }
            if seen.contains(port) { continue }
            seen.insert(port)

            let entry = PortRegistry.lookup(port)
            results.append(ServerProcess(
                id: pid, pid: pid, name: procName, port: port,
                serviceName: entry?.name,
                category: entry?.category ?? .devServer
            ))
        }
        return results.sorted { $0.port < $1.port }
    }

    // MARK: - netstat fallback

    nonisolated static func netstatScan() -> [ServerProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
        process.arguments = ["-anp", "tcp"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var ports = Set<Int>()
        for line in output.components(separatedBy: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 6, parts[parts.count - 1] == "LISTEN" else { continue }
            let localAddr = String(parts[3])
            guard let lastDot = localAddr.lastIndex(of: ".") else { continue }
            let portStr = String(localAddr[localAddr.index(after: lastDot)...])
            guard let port = Int(portStr), port >= 1024, port <= 49151 else { continue }
            ports.insert(port)
        }

        // Enrich with libproc process names
        let processMap = ProcessScanner.buildPortProcessMap()

        return ports.compactMap { port -> ServerProcess? in
            let entry = PortRegistry.lookup(port)

            if let info = processMap[port] {
                // Skip known macOS system daemons when we have their name
                guard !isAppleSystemProcess(info.name) else { return nil }
                return ServerProcess(
                    id: info.pid, pid: info.pid, name: info.name, port: port,
                    serviceName: entry?.name,
                    category: entry?.category ?? .devServer
                )
            }

            // No process name — use registry category or unknown
            return ServerProcess(
                id: port, pid: 0, name: "?", port: port,
                serviceName: entry?.name,
                category: entry?.category ?? .unknown
            )
        }.sorted { $0.port < $1.port }
    }

    // MARK: - Filters

    nonisolated static func isAppleSystemProcess(_ name: String) -> Bool {
        let names: Set<String> = [
            "rapportd", "ControlCenter", "mDNSResponder", "launchd",
            "configd", "bluetoothd", "airportd", "sharingd",
            "AirPlayXPCHelper", "RemoteManagement", "screensharingd", "ARDAgent",
        ]
        return names.contains(name)
    }
}
