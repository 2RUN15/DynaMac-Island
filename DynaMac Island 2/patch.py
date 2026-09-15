import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

text = text.replace('let script = "try\\\\n tell application \\"\\\\(app)\\" to \\\\(command)\\\\n end try"', 
                    'let script = "try\\n tell application \\"\\(app)\\" to \\(command)\\n end try"')

text = text.replace('print("AppleScript Hata: \\\\(String(describing: error))")', 
                    'print("AppleScript Hata:", error ?? "")')

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)

