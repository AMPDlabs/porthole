```
  ____  ___  ____  ____  _  _  _____  __    ____
 (  _ \/ __)(  _ \(_  _)/ )( \(  _  )(  )  (  __)
  ) __/\__ \ )   / _)(_) \/ ( )(_)(  )(__   ) _)
 (__)  (___/(__\_)(____)\____/(_____)(____) (____)

  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·
        see what's listening on localhost
  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·
```

A native macOS menubar app that shows every localhost server running on your machine — grouped, labeled, and one click away from opening in your browser.

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-black?style=flat-square)
![Swift 6](https://img.shields.io/badge/Swift-6-orange?style=flat-square)
![License MIT](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

---

## What it does

Porthole sits in your menubar and scans active TCP listeners every 3 seconds. Open it and instantly see what's running — dev servers, databases, tools, and system processes — grouped into collapsible categories with well-known port labels.

```
◉  Dev Servers  · 3
   Node / Next.js          :3000
   Node                    :3001
   Vite                    :5173

◉  Databases  · 2          ›  (collapsed)
◉  Tools  · 1              ›  (collapsed)
◉  Unknown  · 2            ›  (collapsed)
```

Click any row to open `http://localhost:PORT` in your default browser.

---

## Features

- **Auto-detection** — scans every 3 seconds, no setup required
- **Port labels** — 50+ well-known ports pre-labeled (Vite, Next.js, Astro, MinIO, PostgreSQL, Redis, etc.)
- **Categorized** — Dev Servers, Databases, Tools, System, Unknown
- **Collapsible sections** — focus on what matters, collapse what doesn't
- **One-click open** — click any row to open in browser
- **Liquid Glass UI** — native macOS 26 `.glassEffect()` design
- **Zero config** — lives in your menubar, no Dock icon

---

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26 to build from source

---

## Install

Download `Porthole.zip` from [Releases](../../releases/latest), unzip, and drag `Porthole.app` to `/Applications`.

> **Note:** The app is currently unsigned. On first launch, right-click → Open to bypass Gatekeeper, or go to System Settings → Privacy & Security → Open Anyway.

---

## Build from source

```bash
git clone https://github.com/AMPDlabs/porthole.git
cd porthole
open Porthole/Porthole.xcodeproj
```

Then in Xcode:

1. Select the **Porthole** scheme and **My Mac** as destination
2. **Cmd+R** to run, or **Cmd+B** to build

No dependencies, no package manager — pure Swift and Apple frameworks.

---

## Project structure

```
porthole/
├── Porthole/
│   ├── Porthole.xcodeproj/       Xcode project
│   └── Porthole/
│       ├── PortholeApp.swift     App entry point, MenuBarExtra
│       ├── PortScanner.swift     lsof / netstat polling, 3s timer
│       ├── ProcessScanner.swift  libproc-based process name lookup
│       ├── PortRegistry.swift    Well-known port → service name map
│       ├── ServerProcess.swift   Model + PortCategory enum
│       ├── MenuBarView.swift     Main dropdown UI, category sections
│       └── ServerRowView.swift   Individual server row
└── .github/workflows/
    └── release.yml               Build + attach zip on git tag push
```

---

## How detection works

Porthole tries two methods in order:

1. **lsof** — `lsof -iTCP -sTCP:LISTEN -n -P` gives both port and process name. May be restricted depending on macOS permissions.
2. **netstat fallback** — `netstat -anp tcp` always works and gets port numbers. Port labels come from the built-in registry.

Process names are enriched via `libproc` (`proc_listallpids` + `proc_pidfdinfo`) when available.

---

## Release

Tagging `vX.Y.Z` triggers a GitHub Actions build that produces `Porthole.zip` and attaches it to the release automatically:

```bash
git tag v1.0.0
git push origin v1.0.0
```

> Builds are currently unsigned. Code signing + notarization (removes the Gatekeeper warning) is on the roadmap.

---

## Roadmap

- [ ] Code signing + notarization
- [ ] Custom port labels (name `:3000` → "my-app")
- [ ] Notifications when a server starts or stops
- [ ] Auto-update via Sparkle
- [ ] IPv6 listener support

---

## Contributing

PRs welcome. Open an issue first for anything significant.

---

## License

MIT
