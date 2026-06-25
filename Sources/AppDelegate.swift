import AppKit
import AVFoundation
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windows: [DesktopWindow] = []
    private var bridgeTimer: Timer?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    /// Reads the leader webview's live audio features (merged across the FFT,
    /// wavelet, and controller passes) as JSON for mirroring onto followers.
    private static let readFeaturesJS = """
    (() => {
      const c = window.cranes;
      if (!c) return "{}";
      return JSON.stringify(Object.assign({}, c.measuredAudioFeatures, c.waveletFeatures, c.controllerFeatures));
    })()
    """

    func applicationDidFinishLaunching(_ notification: Notification) {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
        buildMenu()
        rebuildWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(rebuildWindows),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: Desktop windows

    @objc private func rebuildWindows() {
        windows.forEach { $0.close() }
        windows = NSScreen.screens.enumerated().map { index, screen in
            let window = DesktopWindow(screen: screen)
            window.displayKey = Preferences.displayKey(screen)
            window.isLeader = index == 0
            let url = Preferences.url(for: window.displayKey)
            window.show(window.isLeader ? url : url.disablingAudio())
            return window
        }
        startBridge()
    }

    private func reloadAll() {
        windows.forEach { $0.controller.reload() }
        startBridge()
    }

    // MARK: Audio bridge

    /// The leader (first screen) owns the only mic capture. Every frame its live
    /// audio features are pushed into each follower's highest-precedence channel
    /// (window.cranes.messageParams) so all displays react in sync.
    private func startBridge() {
        bridgeTimer?.invalidate()
        bridgeTimer = nil
        guard let leader = windows.first, windows.count > 1 else { return }
        let followers = Array(windows.dropFirst())
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
            leader.controller.webView.evaluateJavaScript(Self.readFeaturesJS) { result, _ in
                guard let json = result as? String, json.count > 2 else { return }
                let writeJS = "window.cranes && Object.assign(window.cranes.messageParams, \(json));"
                followers.forEach { $0.controller.webView.evaluateJavaScript(writeJS, completionHandler: nil) }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        bridgeTimer = timer
    }

    // MARK: Menu

    private func buildMenu() {
        let icon = NSImage(contentsOf: Bundle.main.url(forResource: "menubar", withExtension: "png")!)!
        icon.isTemplate = true
        icon.size = NSSize(width: 18, height: 18)
        statusItem.button?.image = icon
        let menu = NSMenu()

        let displays = NSMenuItem(title: "Displays", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for screen in NSScreen.screens {
            let key = Preferences.displayKey(screen)
            let title = "\(screen.localizedName) — \(label(for: Preferences.url(for: key)))"
            let entry = NSMenuItem(title: title, action: #selector(setDisplayURL(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = key
            submenu.addItem(entry)
        }
        displays.submenu = submenu
        menu.addItem(displays)
        menu.addItem(.separator())

        menu.addItem(item("Set All Displays…", #selector(setAllURL)))
        menu.addItem(item("Reload", #selector(reload)))
        menu.addItem(.separator())

        let login = item("Launch at Login", #selector(toggleLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        menu.addItem(item("Quit Senbazuru", #selector(quit)))
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.target = self
        return menuItem
    }

    // MARK: Actions

    /// Sets one display's URL and reloads just that monitor in place.
    @objc private func setDisplayURL(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        guard let url = promptForURL(title: "Visualizer URL for this display", current: Preferences.url(for: key)) else { return }
        Preferences.setURL(url, for: key)
        if let window = windows.first(where: { $0.displayKey == key }) {
            window.show(window.isLeader ? url : url.disablingAudio())
        }
        buildMenu()
    }

    @objc private func setAllURL() {
        guard let url = promptForURL(title: "Visualizer URL (all displays)", current: Preferences.url) else { return }
        Preferences.resetAll(to: url)
        rebuildWindows()
        buildMenu()
    }

    private func promptForURL(title: String, current: URL) -> URL? {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        field.stringValue = current.absoluteString
        alert.accessoryView = field
        alert.addButton(withTitle: "Load")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return Preferences.normalize(field.stringValue)
    }

    /// A short human label for a URL: the Paper Cranes shader name, else the host.
    private func label(for url: URL) -> String {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url.absoluteString }
        if let shader = comps.queryItems?.first(where: { $0.name == "shader" })?.value { return shader }
        return url.host ?? url.absoluteString
    }

    @objc private func reload() {
        reloadAll()
    }

    @objc private func toggleLogin() {
        let enabled = SMAppService.mainApp.status == .enabled
        try? (enabled ? SMAppService.mainApp.unregister() : SMAppService.mainApp.register())
        buildMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
