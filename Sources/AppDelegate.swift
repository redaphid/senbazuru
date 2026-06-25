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
            window.show(index == 0 ? Preferences.url : Preferences.url.disablingAudio())
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

        let current = NSMenuItem(title: Preferences.url.absoluteString, action: nil, keyEquivalent: "")
        current.isEnabled = false
        menu.addItem(current)
        menu.addItem(.separator())

        menu.addItem(item("Set Visualizer URL…", #selector(setURL)))
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

    @objc private func setURL() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Visualizer URL"
        alert.informativeText = "The web page to render as your live wallpaper."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
        field.stringValue = Preferences.url.absoluteString
        alert.accessoryView = field
        alert.addButton(withTitle: "Load")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        guard let url = Preferences.normalize(field.stringValue) else { return }
        Preferences.url = url
        buildMenu()
        rebuildWindows()
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
