import AppKit

let script = """
tell application "Music"
    get raw data of artwork 1 of current track
end tell
"""
var err: NSDictionary?
let appleScript = NSAppleScript(source: script)
let res = appleScript?.executeAndReturnError(&err)
if let e = err {
    print("ERROR: \(e)")
} else {
    print("SUCCESS! Data size: \(res?.data?.count ?? 0)")
}
