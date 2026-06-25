import Foundation

/// Persists the visualizer URL. Defaults to the user's Paper Cranes visuals.
enum Preferences {
    private static let urlKey = "visualizerURL"
    private static let defaultURL = URL(string: "https://visuals.beadfamous.com/?shader=redaphid%2Firis%2F1&wavelet=true&controller=wavelet-ease&fullscreen=true&knob_1=0.45&knob_20=0.1&knob_21=1.0&knob_2=0.2&knob_3=0.66&knob_27=1&knob_8=1&knob_18=0.7&knob_26=0.8&knob_41=0.6&knob_9=0.7&knob_10=0.6&knob_11=0.6&knob_12=0.6&knob_13=0.6&knob_6=1.0&knob_14=0.4&knob_15=0.5&knob_16=0.4")!

    static var url: URL {
        get {
            guard let raw = UserDefaults.standard.string(forKey: urlKey) else { return defaultURL }
            return URL(string: raw) ?? defaultURL
        }
        set { UserDefaults.standard.set(newValue.absoluteString, forKey: urlKey) }
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
