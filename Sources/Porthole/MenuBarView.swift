import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var scanner: PortScanner

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "network")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                Text("Porthole")
                    .font(.headline)
                Spacer()
                Button {
                    scanner.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if scanner.servers.isEmpty {
                emptyState
            } else {
                serverList
            }

            Divider()

            // Quit
            Button("Quit Porthole") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .glassEffect()
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .foregroundStyle(.tertiary)
            Text("No local servers running")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var serverList: some View {
        ForEach(scanner.servers) { server in
            ServerRowView(server: server)
        }
    }
}
