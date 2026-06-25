import AppKit
import CoreGraphics
import Foundation

/// Persists the visualizer URL. Defaults to the user's Paper Cranes visuals.
/// `url` is the global default; per-display overrides are keyed by the display's
/// stable UUID so they survive reboots and reconnects.
enum Preferences {
    private static let urlKey = "visualizerURL"
    private static let mapKey = "displayURLs"
    private static let defaultURL = URL(string: "https://visuals.beadfamous.com/?shader=redaphid%2Firis%2F1&wavelet=true&controller=wavelet-ease&fullscreen=true&knob_1=0.45&knob_20=0.1&knob_21=1.0&knob_2=0.2&knob_3=0.66&knob_27=1&knob_8=1&knob_18=0.7&knob_26=0.8&knob_41=0.6&knob_9=0.7&knob_10=0.6&knob_11=0.6&knob_12=0.6&knob_13=0.6&knob_6=1.0&knob_14=0.4&knob_15=0.5&knob_16=0.4")!

    static var url: URL {
        get {
            guard let raw = UserDefaults.standard.string(forKey: urlKey) else { return defaultURL }
            return URL(string: raw) ?? defaultURL
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: urlKey) }
    }

    /// Stable per-monitor identifier (display UUID), persistent across reconnects.
    static func displayKey(_ screen: NSScreen) -> String {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return "main" }
        let id = CGDirectDisplayID(number.uint32Value)
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return "display-\(id)" }
        return CFUUIDCreateString(nil, uuid) as String
    }

    private static var map: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: mapKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: mapKey) }
    }

    /// The URL for a given display: its override if set, else the global default.
    static func url(for key: String) -> URL {
        guard let raw = map[key], let parsed = URL(string: raw) else { return url }
        return parsed
    }

    static func setURL(_ newValue: URL, for key: String) {
        var current = map
        current[key] = newValue.absoluteString
        map = current
    }

    /// Sets every display back to one URL, clearing per-display overrides.
    static func resetAll(to newValue: URL) {
        url = newValue
        map = [:]
    }

    /// Coerces freeform input into a URL, prepending https:// when no scheme is present.
    static func normalize(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://\(trimmed)")
    }
}

extension URL {
    /// Forces audio=none so follower displays never open the mic. WebKit allows
    /// only one live capture per app; letting every webview capture means they
    /// steal it from each other and only one reacts.
    func disablingAudio() -> URL {
        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        var items = comps.queryItems ?? []
        items.removeAll { $0.name == "audio" }
        items.append(URLQueryItem(name: "audio", value: "none"))
        comps.queryItems = items
        return comps.url ?? self
    }
}
