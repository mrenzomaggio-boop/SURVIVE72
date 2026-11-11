# SURVIVE 72 · iOS

Native SwiftUI foundation for SURVIVE 72.

| Setting | Value |
| --- | --- |
| App / scheme | `SURVIVE72` |
| Bundle identifier | `com.survive72.app` |
| Deployment target | iOS 17.0 |
| UI | SwiftUI, dark, high contrast |
| Data | Local demo data only (`SURVIVE72/Data/DemoContent.swift`) |

## Structure

```
ios/
├── SURVIVE72.xcodeproj
└── SURVIVE72/
    ├── App/            entry point
    ├── Theme/          colors and metrics
    ├── Models/         the ten Home sections
    ├── Data/           local demo content
    ├── Views/          Home, section tile, section detail
    └── Assets.xcassets
```

## Build without signing

```sh
cd ios
xcodebuild build \
  -project SURVIVE72.xcodeproj \
  -scheme SURVIVE72 \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

The same build runs on GitHub Actions through `.github/workflows/ios-build.yml`
(manual trigger only).

## Not implemented yet

Bluetooth, maps, GPS, torch, networking, downloads and real medical content.
Every section currently shows placeholder demo items. No accounts, keys,
certificates or TestFlight configuration are included.
