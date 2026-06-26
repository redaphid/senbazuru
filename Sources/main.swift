import AppKit
import ServiceManagement

// Scriptable launch-at-login control, so the login item can be (re)pointed at
// a stable install location without clicking the menu toggle.
if CommandLine.arguments.contains("--register-login") {
    do { try SMAppService.mainApp.register() } catch {
        FileHandle.standardError.write(Data("register failed: \(error)\n".utf8))
        exit(1)
    }
    exit(0)
}
if CommandLine.arguments.contains("--unregister-login") {
    do { try SMAppService.mainApp.unregister() } catch {
        FileHandle.standardError.write(Data("unregister failed: \(error)\n".utf8))
        exit(1)
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
