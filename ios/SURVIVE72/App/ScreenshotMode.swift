import Foundation

/// App Store screenshots, taken by the "Store screenshots" workflow in the
/// simulator. The workflow launches the app with `-screenshot <screen>` and
/// the app opens directly on that screen, without permission prompts.
///
/// Only in Debug builds: the App Store build never reads the argument.
enum ScreenshotMode {
    /// The screen to open, or nil in normal use.
    static let screen: String? = {
        #if DEBUG
        UserDefaults.standard.string(forKey: "screenshot")
        #else
        nil
        #endif
    }()

    static var isOn: Bool { screen != nil }

    /// The section to open on launch ("board" opens the alert board).
    static var initialPath: [AppSection] {
        switch screen {
        case "board": [.alert]
        case "connect": [.connect]
        case "maps": [.maps]
        case "medical": [.medical]
        case "knowledge": [.knowledge]
        case "kit": [.kit]
        case "tools": [.tools]
        case "radio": [.radio]
        default: []
        }
    }
}
