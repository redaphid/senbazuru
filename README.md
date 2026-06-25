# Senbazuru 🕊️

A native macOS app that renders a web page as your **live desktop wallpaper** — like
[Plash](https://github.com/sindresorhus/Plash), but with one thing Plash refuses to do:
**it gives the page microphone access.** Your audio-reactive visuals can finally hear the room.

Built for [Paper Cranes](https://visuals.beadfamous.com) (`loqwai/paper-cranes`), so your
music-reactive shaders live on the desktop and pulse to whatever's playing.

> **Senbazuru** (千羽鶴) — "a thousand cranes." Fold a thousand paper cranes and you're
> granted a wish. Your whole desktop becomes that thousand-fold wish: living wallpaper
> that listens.

## Why this exists

Plash embeds a `WKWebView` but never implements WebKit's media-capture permission
delegate, so `getUserMedia()` is denied and audio-reactive sites stay silent. Senbazuru
implements that one method and grants it:

```swift
func webView(_ webView: WKWebView,
             requestMediaCapturePermissionFor origin: WKSecurityOrigin,
             initiatedByFrame frame: WKFrameInfo,
             type: WKMediaCaptureType,
             decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    decisionHandler(.grant)
}
```

That, plus an `NSMicrophoneUsageDescription` and the `audio-input` entitlement, is the
whole trick.

## Multi-display

WebKit keeps only **one live mic capture per app** — with a webview per monitor they
steal it from each other and only one reacts. So the first display (the *leader*) owns
the only capture, and its live audio features are mirrored into every other display each
frame via Paper Cranes' highest-precedence channel (`window.cranes.messageParams`).
Followers load with `audio=none` and never contend. All monitors react in sync.

## Build & run

```sh
./build.sh
open "build/Senbazuru.app"
```

Requirements: macOS 13+, Xcode command-line tools (Swift). The build compiles with
`swiftc`, assembles the `.app` bundle, and ad-hoc signs it with a hardened runtime so the
microphone permission prompt works. **On first launch, allow microphone access** when
macOS asks — that's what lets the visuals react.

It lives in the menu bar (no Dock icon). Click the `◎` icon to:

- **Set Visualizer URL…** — point it at any web visualizer (defaults to a tuned Paper
  Cranes `iris` preset)
- **Reload**
- **Launch at Login**
- **Quit**

## Notes

- `getUserMedia()` needs a secure context — use `https://` or `localhost`.
- The window sits just below the desktop icons and is click-through, so it never gets in
  your way.
- Want a specific shader? Paste its `visuals.beadfamous.com/?shader=…&fullscreen=true`
  URL into **Set Visualizer URL…**.
