import SwiftUI

@main
struct PortholeApp: App {
    @StateObject private var scanner = PortScanner()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(scanner)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .symbolRenderingMode(.hierarchical)
                if !scanner.servers.isEmpty {
                    Text("\(scanner.servers.count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
