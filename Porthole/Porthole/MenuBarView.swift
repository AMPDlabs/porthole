import SwiftUI

// MARK: - Category color palette

extension PortCategory {
    var color: Color {
        switch self {
        case .devServer: return Color(red: 0.00, green: 0.85, blue: 0.65) // teal-green
        case .database:  return Color(red: 0.29, green: 0.62, blue: 1.00) // electric blue
        case .tool:      return Color(red: 1.00, green: 0.62, blue: 0.04) // amber
        case .system:    return Color(red: 0.56, green: 0.56, blue: 0.58) // gray
        case .unknown:   return Color(red: 1.00, green: 0.42, blue: 0.42) // coral
        }
    }

    var icon: String {
        switch self {
        case .devServer: return "hammer.fill"
        case .database:  return "cylinder.fill"
        case .tool:      return "wrench.and.screwdriver.fill"
        case .system:    return "apple.logo"
        case .unknown:   return "questionmark.circle.fill"
        }
    }
}

// MARK: - MenuBarView

struct MenuBarView: View {
    @EnvironmentObject var scanner: PortScanner

    @State private var expanded: [PortCategory: Bool] = [
        .devServer: true,
        .tool:      false,
        .database:  false,
        .system:    false,
        .unknown:   false,
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if scanner.servers.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(PortCategory.allCases, id: \.self) { category in
                            let servers = scanner.servers.filter { $0.category == category }
                            if !servers.isEmpty {
                                CategorySection(
                                    category: category,
                                    servers: servers,
                                    isExpanded: Binding(
                                        get: { expanded[category] ?? false },
                                        set: { expanded[category] = $0 }
                                    )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 400)
            }

            Divider()
                .opacity(0.15)

            Button("Quit Porthole") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .glassEffect()
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            // Wordmark
            HStack(spacing: 6) {
                Image(systemName: "network")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Porthole")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(0.3)
            }

            Spacer()

            // Refresh button
            Button { scanner.refresh() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.12)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No servers detected")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: PortCategory
    let servers: [ServerProcess]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 0) {
                    // Color accent bar
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(category.color)
                        .frame(width: 3, height: 16)
                        .padding(.trailing, 9)

                    // Icon
                    Image(systemName: category.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(category.color.opacity(0.85))
                        .frame(width: 14)
                        .padding(.trailing, 5)

                    // Label
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)

                    // Count pill (exclude departing servers)
                    Text("\(servers.filter { $0.state != .departing }.count)")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(category.color.opacity(0.12), in: Capsule())
                        .padding(.leading, 6)

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isExpanded
                              ? category.color.opacity(0.06)
                              : Color.clear)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Rows
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(servers) { server in
                        ServerRowView(server: server)
                    }
                }
                .padding(.top, 2)
                .animation(.easeInOut(duration: 0.3), value: servers.map(\.port))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, 2)
    }
}
