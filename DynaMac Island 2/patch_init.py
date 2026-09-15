import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

text = text.replace('''        DispatchQueue.global(qos: .background).async {
            _ = self.runAppleScript(app: "Spotify", command: "get player state")
            _ = self.runAppleScript(app: "Music", command: "get player state")
        }''', '')

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
