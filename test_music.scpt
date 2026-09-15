try
    tell application "Music"
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
        return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition
    end tell
on error errStr
    return "ERROR: " & errStr
end try
