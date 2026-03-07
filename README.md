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
