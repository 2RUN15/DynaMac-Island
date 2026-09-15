import AppKit

let script = "tell application \"Music\" to set player position to 50"
var error: NSDictionary? = nil
if let appleScript = NSAppleScript(source: script) {
    let _ = appleScript.executeAndReturnError(&error)
    if let err = error {
        print("Error: \(err)")
    } else {
        print("Success seeking")
    }
}
