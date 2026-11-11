# SURVIVE 72 · iOS

Native SwiftUI app for SURVIVE 72.

| Setting | Value |
| --- | --- |
| App / scheme | `SURVIVE72` |
| Test target | `SURVIVE72Tests` (unit tests, hosted by the app) |
| Bundle identifier | `com.survive72.app` |
| Deployment target | iOS 17.0 |
| UI | SwiftUI, dark, high contrast |
| Data | On device only, no network |

## Modules

- **Kit (SURVIVE KIT)**: real 72-hour checklist with six categories (Water, Food,
  Health, Lighting, Documents, Gear), overall and per-category progress, and a
  "Reset checklist" button with confirmation. Checked items are saved in
  `UserDefaults` under `survive72.kit.checkedItemIDs.v1`.
- **Knowledge (SURVIVE KNOWLEDGE)**: offline library bundled with the app, with
  six categories, local search on title and text (case- and accent-insensitive,
  all words must match), category filters and an article page. Every article is
  demo content marked **TO BE VERIFIED**: no instructions, no medical guidance.
- **Alert (SURVIVE ALERT)**: local emergency planning. Add, edit and delete
  emergency contacts; a personal plan (name, meeting point, note); an SOS
  message generated from them that you can edit and copy with
  "Copy SOS message". Nothing is ever sent: the screen always shows
  "NOT SENT · NO EMERGENCY SERVICE CONTACTED". No network, SMS, calls, GPS or
  permissions. Data is saved as JSON in `UserDefaults` under
  `survive72.alert.planData.v1`.
- **Tools (SURVIVE TOOLS)**: a stopwatch (start, pause/resume, reset; readable
  `MM:SS.t` / `H:MM:SS` format, based on timestamps so it stays correct in the
  background); an on-screen SOS signal (... --- ... in white on black, 0.5 s
  per Morse unit, at most one flash per second, starts only on tap, keeps the
  screen awake while running); and a Torch screen marked **REQUIRES
  PHYSICAL-DEVICE TEST** that does not use the camera, flash or permissions.
  State is kept in memory only.
- **Settings**: metric/imperial units, high contrast (bolder text), battery
  saver (fewer screen refreshes), a privacy summary and "Erase all local data"
  with confirmation. Preferences are saved as JSON in `UserDefaults` under
  `survive72.settings.v1`.
- **Downloads**: local offline packs with status (included, prepared, not
  prepared), readiness of required packs and space used/missing compared with
  the free space on the device. Nothing is downloaded: non-bundled packs can
  only be marked as prepared (`survive72.downloads.preparedPackIDs.v1`).
- **Radio**: offline information guide with topic filters and search. No
  frequencies, no radio access, nothing is transmitted.
- **Connect (SURVIVE CONNECT)**: local demo chat with fictional conversations,
  a message composer and history. Sent messages enter a local queue as
  **queued**; buttons simulate **delivered** or **failed**, and failed messages
  can be queued again. A priority SOS with editable text always goes ahead of
  other queued messages. Every Connect screen shows
  "LOCAL DEMO · NOT TRANSMITTED". No Bluetooth, Wi-Fi peer-to-peer, network,
  GPS or permissions. Data is saved as JSON in `UserDefaults` under
  `survive72.connect.data.v1` and is erased by "Erase all local data".
- **Maps and Medical**: placeholder demo data (`SURVIVE72/Data/DemoContent.swift`).

## Structure

```
ios/
├── SURVIVE72.xcodeproj
├── SURVIVE72/
│   ├── App/            entry point, injects the Kit store
│   ├── Theme/          colors and metrics
│   ├── Models/         Home sections, Kit, Knowledge, Alert, Tools, settings, packs, radio guide, Connect messages and queue
│   ├── Data/           Kit default items, Knowledge articles, Connect demo chats, demo content
│   ├── Storage/        Kit, Alert, Settings, Downloads and Connect stores, ToolsState (memory)
│   ├── Views/          Home, section tile, demo detail
│   │   ├── Kit/        checklist, item row, progress card
│   │   ├── Knowledge/  library list and article page
│   │   ├── Alert/      plan, contacts, SOS message, contact editor
│   │   ├── Tools/      tools list, stopwatch, SOS signal, torch placeholder
│   │   ├── Settings/   preferences, privacy, erase local data
│   │   ├── Downloads/  offline packs and space
│   │   ├── Radio/      offline radio guide
│   │   └── Connect/    local chat, queue, SOS composer
│   └── Assets.xcassets
└── SURVIVE72Tests/     unit tests for every real module
```

## Build and test without signing

```sh
cd ios
xcodebuild test \
  -project SURVIVE72.xcodeproj \
  -scheme SURVIVE72 \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

Use any installed iPhone simulator name. The same build and tests run on
GitHub Actions through `.github/workflows/ios-build.yml`, which picks an
available simulator automatically.

## Not implemented yet

Bluetooth, maps, GPS, torch, networking, downloads and real medical content.
No accounts, keys, certificates or TestFlight configuration are included.
