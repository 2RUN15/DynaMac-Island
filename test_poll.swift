import AppKit

let app = "Music"
let script = """
try
    tell application "\(app)"
        if player state as string is "stopped" then return ""
        set theName to name of current track
        try
            set theArtist to artist of current track
        on error
            set theArtist to "Bilinmeyen Sanatçı"
        end try
        set theState to player state as string
        set theDuration to duration of current track
        set thePosition to player position
        set theArtUrl to "NONE"
        if "\(app)" is "Spotify" then
            try
                set theArtUrl to artwork url of current track
            end try
        end if
        return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition & "|||" & theArtUrl
    end tell
on error err
    return "APP_ERR: " & err
end try
"""

var error: NSDictionary? = nil
if let appleScript = NSAppleScript(source: script) {
    let result = appleScript.executeAndReturnError(&error)
    print("Output: \(result.stringValue ?? "nil")")
    if let e = error { print("Error: \(e)") }
}
