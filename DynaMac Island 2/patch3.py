import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

text = text.replace('let intTime = Int(time)\\n        _ = runAppleScript(app: activeApp, command: "set player position to \\\\(intTime)")', 
                    'let intTime = Int(time)\n        _ = runAppleScript(app: activeApp, command: "set player position to \\(intTime)")')

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
