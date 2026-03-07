import SwiftUI

struct ServerRowView: View {
    let server: ServerProcess
    @State private var isHovered = false
    var dotColor: Color {
        server.category == .devServer ? server.category.color : server.category.color.opacity(0.7)
    }

    var body: some View {
        Button { openInBrowser() } label: {
            HStack(spacing: 10) {
                // Live indicator dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)

                // Service / process name
                Text(server.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                // Port readout
                Text(verbatim: ":\(server.port)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isHovered ? server.category.color : .secondary)
                    .animation(.easeInOut(duration: 0.15), value: isHovered)

                // Arrow
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(server.category.color.opacity(0.8))
                    .opacity(isHovered ? 1 : 0)
                    .offset(x: isHovered ? 0 : -4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered
                          ? server.category.color.opacity(0.08)
                          : Color.clear)
                    .overlay {
                        if isHovered {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(server.category.color.opacity(0.15), lineWidth: 0.5)
                        }
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
