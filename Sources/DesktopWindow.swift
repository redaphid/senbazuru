import AppKit

/// A borderless, click-through window pinned to the desktop layer — just below
/// the desktop icons and above the system wallpaper, spanning one screen.
final class DesktopWindow: NSWindow {
    let controller = WebViewController()
    var displayKey = ""
    var isLeader = false

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = true
        backgroundColor = .black
        ignoresMouseEvents = true
        hasShadow = false
        isMovable = false
        canHide = false
        contentView = controller.webView
        setFrame(screen.frame, display: true)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show(_ url: URL) {
        controller.load(url)
        orderFrontRegardless()
    }
}
