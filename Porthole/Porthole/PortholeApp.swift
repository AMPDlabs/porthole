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
                Image("MenuBarIcon")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 18, height: 18)
                if !scanner.servers.isEmpty {
                    Text("\(scanner.servers.count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

