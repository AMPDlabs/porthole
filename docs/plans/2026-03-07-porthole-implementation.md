# Porthole Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS menubar app that shows running localhost dev servers (process name + port) detected via `lsof`, with click-to-open-in-browser.

**Architecture:** SwiftUI `MenuBarExtra` app with no Dock icon. A `PortScanner` `ObservableObject` polls `lsof -iTCP -sTCP:LISTEN -n -P` every 3 seconds and publishes parsed results. The UI uses Liquid Glass (`.glassEffect()`) for the macOS 26 native look.

**Tech Stack:** Swift 6, SwiftUI, `MenuBarExtra`, `Process` (for shell calls), Liquid Glass / `.glassEffect()` (macOS 26+), GitHub Actions for CI/release.

---

### Task 1: Scaffold the Xcode project

**Files:**
- Create: `Sources/Porthole/PortholeApp.swift`
- Create: `Porthole.xcodeproj/` (via Xcode UI)
- Create: `Sources/Porthole/Info.plist`

**Step 1: Create project in Xcode**

Open Xcode 26. File → New → Project → macOS → App.
- Product Name: `Porthole`
- Bundle ID: `com.maxzurlino.porthole`
- Interface: SwiftUI
- Language: Swift
- Uncheck "Include Tests" for now (we add them manually)
- Save to: `projects/porthole/`

**Step 2: Set deployment target**

In project settings → General → Minimum Deployments: set to **macOS 26.0**.

**Step 3: Set app to menubar-only (no Dock icon)**

Open `Info.plist`, add key:
```xml
<key>LSUIElement</key>
<true/>
```

**Step 4: Replace default `ContentView.swift` entry point**

Replace the generated `PortholeApp.swift` with:
```swift
import SwiftUI

@main
struct PortholeApp: App {
    @StateObject private var scanner = PortScanner()

    var body: some Scene {
        MenuBarExtra("Porthole", systemImage: "network") {
            MenuBarView()
                .environmentObject(scanner)
        }
        .menuBarExtraStyle(.window)
    }
}
```

**Step 5: Build to verify it compiles**

Cmd+B. Expected: build succeeds (ContentView errors will appear — that's fine, we're replacing it next).

**Step 6: Commit**

```bash
cd projects/porthole
git init
git add .
git commit -m "chore: scaffold Xcode project with menubar-only config"
```

---

### Task 2: `ServerProcess` model

**Files:**
- Create: `Sources/Porthole/ServerProcess.swift`

**Step 1: Create the file in Xcode**

File → New → Swift File → `ServerProcess.swift`

**Step 2: Write the struct**

```swift
import Foundation

struct ServerProcess: Identifiable, Equatable {
    let id: Int         // pid
    let pid: Int
    let name: String
    let port: Int
}
```

**Step 3: Build to verify**

Cmd+B. Expected: build succeeds.

**Step 4: Commit**

```bash
git add Sources/Porthole/ServerProcess.swift
git commit -m "feat: add ServerProcess model"
```

---

### Task 3: `PortScanner` — lsof shell call + parser

**Files:**
- Create: `Sources/Porthole/PortScanner.swift`

**Step 1: Create the file**

File → New → Swift File → `PortScanner.swift`

**Step 2: Write the shell helper first**

```swift
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
```

**Step 3: Build to verify**

Cmd+B. Expected: build succeeds.

**Step 4: Quick manual test — run in a Playground or add a debug print**

In `PortholeApp.swift` temporarily add after `@StateObject private var scanner = PortScanner()`:
```swift
// DEBUG — remove before shipping
init() { print(PortScanner.scan()) }
```
Run the app (Cmd+R), check the Xcode console. You should see `ServerProcess` entries for any servers you have running. Remove the debug line after verifying.

**Step 5: Commit**

```bash
git add Sources/Porthole/PortScanner.swift
git commit -m "feat: add PortScanner with lsof polling and parser"
```

---

### Task 4: `MenuBarView` — main dropdown UI

**Files:**
- Create: `Sources/Porthole/MenuBarView.swift`
- Delete: `Sources/Porthole/ContentView.swift` (no longer needed)

**Step 1: Create `MenuBarView.swift`**

File → New → Swift File → `MenuBarView.swift`

**Step 2: Write the view**

```swift
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
```

**Step 3: Delete `ContentView.swift`**

Right-click `ContentView.swift` in Xcode → Delete → Move to Trash.

**Step 4: Build**

Cmd+B. Expected: build succeeds.

**Step 5: Commit**

```bash
git add Sources/Porthole/MenuBarView.swift
git rm Sources/Porthole/ContentView.swift
git commit -m "feat: add MenuBarView with header, server list, empty state, and quit"
```

---

### Task 5: `ServerRowView` — individual server row

**Files:**
- Create: `Sources/Porthole/ServerRowView.swift`

**Step 1: Create the file**

File → New → Swift File → `ServerRowView.swift`

**Step 2: Write the row view**

```swift
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
```

**Step 3: Build and run**

Cmd+R. Click the menubar icon. You should see server rows. Click one — it should open your browser. Hover over a row — arrow should appear.

**Step 4: Commit**

```bash
git add Sources/Porthole/ServerRowView.swift
git commit -m "feat: add ServerRowView with hover state and browser open"
```

---

### Task 6: Polish — menubar icon badge + animation

**Files:**
- Modify: `Sources/Porthole/PortholeApp.swift`

**Step 1: Update menubar icon to show server count**

Replace the `MenuBarExtra` label in `PortholeApp.swift`:

```swift
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
```

This shows a count badge next to the icon when servers are running — e.g. `network 3`.

**Step 2: Build and run**

Cmd+R. Start a local dev server (`npx vite` or similar). The menubar icon should update within 3 seconds showing the count.

**Step 3: Commit**

```bash
git add Sources/Porthole/PortholeApp.swift
git commit -m "feat: show server count badge in menubar icon"
```

---

### Task 7: README + project structure cleanup

**Files:**
- Create: `README.md`
- Create: `.gitignore`

**Step 1: Write `.gitignore`**

```
.DS_Store
*.xcuserdata/
xcuserdata/
DerivedData/
.build/
*.o
*.d
```

**Step 2: Write `README.md`**

```markdown
# Porthole

A native macOS menubar app that shows all running localhost dev servers at a glance.

## What it does

Porthole scans active TCP listeners every 3 seconds using `lsof` and displays them in your menubar. Click any row to open it in your browser.

```
● vite          :5173
● node          :3000
● python        :8000
```

## Requirements

- macOS 26 (Tahoe) or later

## Install

Download `Porthole.zip` from [GitHub Releases](../../releases), unzip, drag `Porthole.app` to `/Applications`.

## Build from source

1. Clone the repo
2. Open `Porthole.xcodeproj` in Xcode 26
3. Cmd+R to run

## Contributing

PRs welcome. Open an issue first for significant changes.
```

**Step 3: Commit**

```bash
git add README.md .gitignore
git commit -m "chore: add README and gitignore"
```

---

### Task 8: GitHub Actions release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Create the workflow file**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_26.0.app

      - name: Build
        run: |
          xcodebuild \
            -project Porthole.xcodeproj \
            -scheme Porthole \
            -configuration Release \
            -derivedDataPath build/ \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO

      - name: Zip app
        run: |
          cd build/Build/Products/Release
          zip -r Porthole.zip Porthole.app

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: build/Build/Products/Release/Porthole.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Note:** This builds unsigned. For Gatekeeper-clean installs (no "unidentified developer" warning), code signing and notarization are required — that's a post-v1 task requiring an Apple Developer account.

**Step 2: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add GitHub Actions release workflow"
```

---

### Task 9: Push to GitHub and cut v0.1.0

**Step 1: Create repo on GitHub**

Go to github.com → New repository → name: `porthole` → public → no README (we have one).

**Step 2: Push**

```bash
git remote add origin git@github.com:YOUR_USERNAME/porthole.git
git branch -M main
git push -u origin main
```

**Step 3: Tag and release**

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions will pick up the tag, build, and attach `Porthole.zip` to the release automatically. Check the Actions tab to monitor progress.

**Step 4: Share the release link with your team**

They go to `github.com/YOUR_USERNAME/porthole/releases/latest`, download `Porthole.zip`, drag to Applications.

---

## Post-v1 Backlog

- Code signing + notarization (removes Gatekeeper warning)
- Port labeling — let users name ports ("3000 = my-saas")
- Notification when a new server appears or disappears
- Auto-update via Sparkle framework
- Support for IPv6 listeners
