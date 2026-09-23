import Foundation

struct ScriptHelper {
    /// Executes a given AppleScript and returns its standard output as an optional string.
    nonisolated static func run(_ scriptSource: String) -> String? {
        var error: NSDictionary? = nil
        if let scriptObject = NSAppleScript(source: scriptSource) {
            let eventResult = scriptObject.executeAndReturnError(&error)
            if error == nil {
                if let stringValue = eventResult.stringValue {
                    let output = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !output.isEmpty { return output }
                } else if eventResult.int32Value != 0 {
                    return String(eventResult.int32Value)
                }
            } else {
                print("NSAppleScript Error: \(error?.description ?? "Bilinmeyen hata")")
            }
        }
        return nil
    }
    
    /// Hides native macOS Notification Center banners via Accessibility UI scripting.
    nonisolated static func dismissSystemNotifications() {
        // macOS Notification Center (process "NotificationCenter") 
        let script = """
        tell application "System Events"
            try
                tell process "NotificationCenter"
                    set allWindows to every window
                    repeat with w in allWindows
                        try
                            perform (first action of w whose name contains "Close" or name contains "Clear")
                        end try
                        try
                            click (first button of w whose description is "close button")
                        end try
                        try
                            click button "Close" of w
                        end try
                    end repeat
                end tell
            end try
        end tell
        """
        
        // Asynchronously run this multiple times over a few seconds 
        // to catch the AirPods popup since it might have a slight delay.
        for delay in [0.2, 0.5, 1.0, 1.5, 2.0] {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
                _ = self.run(script)
            }
        }
    }
}
