import Cocoa

class Accessibility {
    /// Prompts for Accessibility permission if Lattice is not trusted yet.
    @discardableResult
    func requestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            Log.warn("Lattice is not trusted for Accessibility. Grant it in System Settings > Privacy & Security > Accessibility.")
        }
        return trusted
    }

    /// Captures the focused window of `app`.
    func captureWindow(of app: NSRunningApplication) -> AXUIElement? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        let name = app.bundleIdentifier ?? app.localizedName ?? "unknown"

        var windowRef: CFTypeRef?

        var result = AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &windowRef)

        // Some apps only expose a focused window while active; fall back to the first window.
        if result != .success {
            var windowsRef: CFTypeRef?
            let listResult = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &windowsRef)
            if listResult == .success, let windows = windowsRef as? [AXUIElement], let first = windows.first {
                windowRef = first
                result = .success
            }
        }

        guard result == .success, let windowElement = windowRef as! AXUIElement? else {
            Log.error("Could not capture window of \(name). Error code: \(result.rawValue). Trusted: \(AXIsProcessTrusted())")
            return nil
        }

        return windowElement
    }

    /// Moves and resizes an already captured window.
    /// `frame` is expected in Accessibility coordinates (origin top-left of the primary screen, y growing down).
    func setFrame(of window: AXUIElement, to frame: CGRect) {
        var origin = frame.origin
        var size = frame.size

        guard let axOrigin = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!, &origin),
              let axSize = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &size) else {
            Log.error("Failed to create AXValue for frame.")
            return
        }

        // Position first, then size: some apps clamp size against the current screen.
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, axOrigin)
        if positionResult != .success {
            Log.error("Failed to move window. Error code: \(positionResult.rawValue)")
            return
        }

        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, axSize)
        if sizeResult != .success {
            Log.error("Failed to resize window. Error code: \(sizeResult.rawValue)")
            return
        }

        Log.info("Window placed successfully")
    }

    func resizeWindowOfApp(bundleId: String, newSize: CGSize) {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first else {
            Log.error("App with bundle ID \(bundleId) is not running.")
            return
        }

        let pid = app.processIdentifier

        let element = AXUIElementCreateApplication(pid)

        var windowRef: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &windowRef)

        guard result == .success, let windowElement = windowRef as! AXUIElement? else {
            Log.error("Could not find the frontmost window. Ensure the app is active or unminimized.")
            return
        }

        var size = newSize
        guard let axSizeValue = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!, &size) else {
            Log.error("Failed to create AXValue for size.")
            return
        }

        let resizeResult = AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, axSizeValue)

        if resizeResult != .success {
            Log.error("Failed to resize window. Error code: \(resizeResult.rawValue)")
            return
        }

        Log.info("Window resized successfully")
    }
}
