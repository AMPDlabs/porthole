# Porthole — Design Document
**Date:** 2026-03-07
**Status:** Approved

## Overview

Porthole is a native macOS menubar app that shows all running localhost dev servers at a glance. It scans active TCP listeners using `lsof`, displays process name + port in a dropdown, and opens the server in the browser on click. Built for developers juggling multiple local environments simultaneously.

## Problem

Developers running multiple Claude Code sessions, Next.js apps, APIs, and other local services lose track of what is running on which port. There is no native, low-friction way to see this at a glance without running terminal commands.

## Goals

- Show all listening localhost processes (name + port) in the menubar
- Click a row to open `http://localhost:{port}` in the default browser
- Auto-refresh every 3 seconds, always live
- Native macOS feel using Liquid Glass design (macOS 26+)
- Open-source on GitHub, distributed via GitHub Releases as a signed `.app`

## Non-Goals

- Port labeling / custom aliases (post-v1)
- Notifications when servers start/stop (post-v1)
- Remote host support

## Architecture

Single Swift Package Manager project. Runs as a menubar-only agent (`LSUIElement = true` — no Dock icon).

**Tech:**
- Swift + SwiftUI
- `MenuBarExtra` (macOS 13+) for the menubar UI
- `Process` / shell to run `lsof`
- `.glassEffect()` and Liquid Glass materials (macOS 26+)
- Minimum deployment target: macOS 26

## Components

### `ServerProcess` (struct)
```swift
struct ServerProcess: Identifiable {
    let pid: Int
    let name: String
    let port: Int
}
```

### `PortScanner` (ObservableObject)
- Owns a `Timer` that fires every 3 seconds
- Shells out: `lsof -iTCP -sTCP:LISTEN -n -P`
- Parses stdout into `[ServerProcess]`
- Publishes results via `@Published var servers: [ServerProcess]`
- Also refreshes on app foreground (`NSWorkspace.didActivateApplicationNotification`)

### `MenuBarView`
- `MenuBarExtra` with SF Symbol `globe` or `network` icon
- Lists `ServerRowView` for each server
- Empty state: "No local servers running"
- "Quit Porthole" at the bottom

### `ServerRowView`
- Green dot + process name + port
- `Button` action: `NSWorkspace.shared.open(URL(string: "http://localhost:\(server.port)")!)`
- Liquid Glass hover effect via `.glassEffect(.regular)`

### `@main PortholeApp`
- Sets up `MenuBarExtra`
- Holds `PortScanner` as `@StateObject`

## Data Flow

```
Timer (3s) → lsof shell call → stdout parsed → [ServerProcess] published
     ↓
MenuBarView re-renders
     ↓
User clicks row → NSWorkspace.open(localhost:PORT) → browser opens
```

## UI Design

- Menubar icon: SF Symbol `network` with hierarchical rendering
- Popover panel: `.glassEffect()` background (Liquid Glass, macOS 26)
- Rows: process name left-aligned, port right-aligned, green dot indicator
- Hover state: `.glassEffect(.regular)` on row
- Typography: SF Mono for port numbers, SF Pro for process names
- Row example: `● vite                    :5173`

## Distribution

**Repo structure:**
```
porthole/
  Sources/Porthole/        — Swift source files
  Porthole.xcodeproj/      — Xcode project
  docs/plans/              — design + implementation docs
  README.md                — setup, contribution guide, requirements
  .github/workflows/       — CI: build + attach .app to GitHub Release on tag push
```

**Workflow:**
- Contributors: clone repo, open in Xcode 26, build and run
- Teammates: download `Porthole.zip` from GitHub Releases, drag to Applications
- Releases: tag `vX.Y.Z` → GitHub Actions builds signed `.app` → attaches to Release

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26 for contributors building from source

## Open Questions (post-v1)

- Code signing / notarization for Gatekeeper (needed for clean install experience)
- Auto-update mechanism (Sparkle framework or manual check-for-update menu item)
