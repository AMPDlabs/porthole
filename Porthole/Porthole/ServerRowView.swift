import SwiftUI

// MARK: - Kill button design constants
// Change these values to adjust every aspect of the kill button in one place.

enum KillButtonConstants {
    /// Seconds the user must hold the button before the process is killed.
    static let countdownDuration: Double = 2.0

    // ── Idle state (button visible on row-hover, before any click) ──────────
    /// SF Symbol shown in the idle state.
    static let idleIcon: String         = "power.circle"
    /// Point size of the idle icon.
    static let idleIconSize: CGFloat    = 13
    /// Opacity of the idle icon relative to the category accent colour.
    static let idleIconOpacity: Double  = 0.85
    /// Opacity of the pill background behind the idle icon.
    static let idlePillOpacity: Double  = 0.07
    /// Opacity of the pill stroke in idle state.
    static let idleStrokeOpacity: Double = 0.12
    /// Corner radius of the idle pill.
    static let idlePillCornerRadius: CGFloat = 6
    /// Horizontal padding inside the idle pill.
    static let idlePillPaddingH: CGFloat = 5
    /// Vertical padding inside the idle pill.
    static let idlePillPaddingV: CGFloat = 4

    // ── Countdown / armed state (after click, counting down to kill) ─────────
    /// SF Symbol shown inside the progress ring during countdown.
    static let stopIcon: String         = "stop.fill"
    /// Point size of the stop icon inside the ring.
    static let stopIconSize: CGFloat    = 7
    /// Outer diameter of the circular progress track.
    static let ringDiameter: CGFloat    = 20
    /// Line width of the progress ring track.
    static let ringTrackWidth: CGFloat  = 1.5
    /// Opacity of the ring track (unfilled portion).
    static let ringTrackOpacity: Double = 0.18
    /// Opacity of the filled portion of the ring.
    static let ringFillOpacity: Double  = 0.75
    /// Opacity of the stop icon inside the ring.
    static let stopIconOpacity: Double  = 0.70

    // ── Category visibility ───────────────────────────────────────────────────
    /// Which categories show the kill button. Currently enabled for Dev Servers,
    /// Tools, and Unknown only — Databases and System are excluded to prevent
    /// accidental data loss. To enable for other categories, simply add them
    /// to this set (e.g. `.database`).
    static let killableCategories: Set<PortCategory> = [.devServer, .tool, .unknown]

    // ── Shared ───────────────────────────────────────────────────────────────
    /// The accent colour used for the kill button across all states.
    /// Warm rose — sits close to the UI neutrals and reads as "stop" without
    /// screaming hard red. It has just enough chromatic distance from the
    /// category colours (teal, blue, amber, gray, coral) to be legible.
    static let accentColor: Color = Color(red: 1.0, green: 0.38, blue: 0.48)

    /// Duration of the appear / disappear animation.
    static let transitionDuration: Double = 0.15
    /// Spring used when switching between idle and armed states.
    static let stateSpring: Animation = .spring(response: 0.28, dampingFraction: 0.78)
}

// MARK: - Kill button view

private struct KillButtonView: View {
    let server: ServerProcess
    @EnvironmentObject var scanner: PortScanner

    /// Whether the countdown is currently running — bound from parent so hover
    /// logic can keep the button visible while armed.
    @Binding var isArmed: Bool
    /// Progress from 0 → 1 over `KillButtonConstants.countdownDuration` seconds.
    @State private var progress     = 0.0
    /// Timer that drives the progress ring.
    @State private var countdownTimer: Timer? = nil

    private let accent = KillButtonConstants.accentColor

    var body: some View {
        Button {
            if isArmed {
                cancelCountdown()
            } else {
                startCountdown()
            }
        } label: {
            ZStack {
                if isArmed {
                    armedLabel
                        .transition(
                            .scale(scale: 0.75)
                            .combined(with: .opacity)
                        )
                } else {
                    idleLabel
                        .transition(
                            .scale(scale: 0.75)
                            .combined(with: .opacity)
                        )
                }
            }
            // Fixed frame prevents the HStack from jumping between states.
            .frame(
                width: KillButtonConstants.ringDiameter,
                height: KillButtonConstants.ringDiameter
            )
        }
        .buttonStyle(.plain)
        .help(isArmed
              ? "Click to cancel — killing process on port \(server.port)"
              : "Stop process on port \(server.port)")
        .onDisappear { cancelCountdown() }
    }

    // MARK: Idle label

    private var idleLabel: some View {
        let c = KillButtonConstants.self
        return Image(systemName: c.idleIcon)
            .font(.system(size: c.idleIconSize, weight: .light))
            .foregroundStyle(accent.opacity(c.idleIconOpacity))
            .padding(.horizontal, c.idlePillPaddingH)
            .padding(.vertical, c.idlePillPaddingV)
            .background {
                RoundedRectangle(cornerRadius: c.idlePillCornerRadius)
                    .fill(accent.opacity(c.idlePillOpacity))
                    .overlay {
                        RoundedRectangle(cornerRadius: c.idlePillCornerRadius)
                            .strokeBorder(
                                accent.opacity(c.idleStrokeOpacity),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: accent.opacity(0.15), radius: 3, y: 1)
    }

    // MARK: Armed / countdown label

    private var armedLabel: some View {
        let c = KillButtonConstants.self
        return ZStack {
            // Track (unfilled background ring)
            Circle()
                .stroke(accent.opacity(c.ringTrackOpacity), lineWidth: c.ringTrackWidth)
                .frame(width: c.ringDiameter, height: c.ringDiameter)

            // Animated fill arc — grows clockwise as countdown advances
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accent.opacity(c.ringFillOpacity),
                    style: StrokeStyle(
                        lineWidth: c.ringTrackWidth,
                        lineCap: .round
                    )
                )
                .frame(width: c.ringDiameter, height: c.ringDiameter)
                // Trim starts at the top (12 o'clock)
                .rotationEffect(.degrees(-90))

            // Stop icon centred inside the ring
            Image(systemName: c.stopIcon)
                .font(.system(size: c.stopIconSize, weight: .semibold))
                .foregroundStyle(accent.opacity(c.stopIconOpacity))
        }
    }

    // MARK: Countdown mechanics

    private func startCountdown() {
        // Guard against double invocation — invalidate any existing timer first
        countdownTimer?.invalidate()
        countdownTimer = nil

        progress = 0
        isArmed  = true
        let interval   = 1.0 / 60.0                          // 60 fps
        let totalTicks = KillButtonConstants.countdownDuration / interval

        var tick = 0.0
        countdownTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { @MainActor timer in
            tick += 1
            let raw = tick / totalTicks
            withAnimation(.linear(duration: interval)) {
                progress = min(raw, 1.0)
            }
            if raw >= 1.0 {
                timer.invalidate()
                countdownTimer = nil
                commitKill()
            }
        }
    }

    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        withAnimation(KillButtonConstants.stateSpring) {
            isArmed  = false
            progress = 0
        }
    }

    private func commitKill() {
        scanner.kill(server: server)
        // State resets because the row disappears from the list;
        // reset locally as a safety net for any edge case where it stays visible.
        isArmed  = false
        progress = 0
    }
}

// MARK: - Server row

struct ServerRowView: View {
    let server: ServerProcess
    @EnvironmentObject var scanner: PortScanner
    @State private var isHovered = false
    @State private var isArmed = false

    var dotColor: Color {
        server.category == .devServer
            ? server.category.color
            : server.category.color.opacity(0.7)
    }

    var body: some View {
        HStack(spacing: 6) {
            // ── Main tap target: open in browser ──────────────────────────────
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
                        .animation(
                            .easeInOut(duration: KillButtonConstants.transitionDuration),
                            value: isHovered
                        )

                    // Arrow — styled as pill to match kill button
                    if isHovered {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(server.category.color.opacity(0.85))
                            .frame(width: KillButtonConstants.ringDiameter, height: KillButtonConstants.ringDiameter)
                            .background {
                                RoundedRectangle(cornerRadius: KillButtonConstants.idlePillCornerRadius)
                                    .fill(server.category.color.opacity(0.07))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: KillButtonConstants.idlePillCornerRadius)
                                            .strokeBorder(
                                                server.category.color.opacity(0.12),
                                                lineWidth: 0.5
                                            )
                                    }
                            }
                            .shadow(color: server.category.color.opacity(0.15), radius: 3, y: 1)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .buttonStyle(.plain)

            // ── Kill button — visible on hover (or while armed), only for killable categories ──
            if (isHovered || isArmed) && KillButtonConstants.killableCategories.contains(server.category) {
                KillButtonView(server: server, isArmed: $isArmed)
                    .transition(
                        .opacity.combined(with: .scale(scale: 0.8))
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isHovered
                        ? server.category.color.opacity(0.08)
                        : Color.clear
                )
                .overlay {
                    if isHovered {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                server.category.color.opacity(0.15),
                                lineWidth: 0.5
                            )
                    }
                }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: KillButtonConstants.transitionDuration)) {
                isHovered = hovering
            }
        }
    }

    private func openInBrowser() {
        guard let url = URL(string: "http://localhost:\(server.port)") else { return }
        NSWorkspace.shared.open(url)
    }
}
