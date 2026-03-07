import SwiftUI

struct ServerRowView: View {
    let server: ServerProcess
    @State private var isHovered = false

    var body: some View {
        Button {
            openInBrowser()
        } label: {
            HStack(spacing: 10) {
                // Live indicator dot
                Circle()
                    .fill(.green)
                    .frame(width: 7, height: 7)

                // Process name
                Text(server.name)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)

                Spacer()

                // Port number
                Text(":\(server.port)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Arrow on hover
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isHovered
                ? AnyView(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                : AnyView(Color.clear)
        )
        .padding(.horizontal, 6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func openInBrowser() {
        guard let url = URL(string: "http://localhost:\(server.port)") else { return }
        NSWorkspace.shared.open(url)
    }
}
