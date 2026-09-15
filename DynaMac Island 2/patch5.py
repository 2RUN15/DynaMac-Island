import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

# Replace the giant fragile script with a bulletproof robust script
robust_script = """            let script = \"\"\"
            tell application "\\(app)"
                try
                    set theState to player state as string
                on error
                    return ""
                end try
                
                if theState is "stopped" then return ""
                
                try
                    set theName to name of current track
                on error
                    set theName to "Bilinmeyen Şarkı"
                end try
                
                try
                    set theArtist to artist of current track
                on error
                    set theArtist to "Bilinmeyen Sanatçı"
                end try
                
                try
                    set theDuration to duration of current track
                on error
                    set theDuration to 1
                end try
                
                try
                    set thePosition to player position
                on error
                    set thePosition to 0
                end try
                
                set theArtUrl to "NONE"
                if "\\(app)" is "Spotify" then
                    try
                        set theArtUrl to artwork url of current track
                    end try
                end if
                
                return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition & "|||" & theArtUrl
            end tell
            \"\"\"
"""

# We need to find where the old script is defined and replace it
# The old script starts with `let script = """` and ends with `end try\n            """`
text = re.sub(r'let script = """\n\s*try\n\s*tell application .*?end try\n\s*"""', robust_script.strip(), text, flags=re.DOTALL)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
