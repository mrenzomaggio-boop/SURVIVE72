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
- **All other sections**: placeholder demo data (`SURVIVE72/Data/DemoContent.swift`).

## Structure

```
ios/
├── SURVIVE72.xcodeproj
├── SURVIVE72/
│   ├── App/            entry point, injects the Kit store
│   ├── Theme/          colors and metrics
│   ├── Models/         Home sections, Kit models, Knowledge article + search
│   ├── Data/           Kit default items, Knowledge articles, demo content
│   ├── Storage/        KitChecklistStore (UserDefaults)
│   ├── Views/          Home, section tile, demo detail
│   │   ├── Kit/        checklist, item row, progress card
│   │   └── Knowledge/  library list and article page
│   └── Assets.xcassets
└── SURVIVE72Tests/     Kit persistence/progress, Knowledge search/filters
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
