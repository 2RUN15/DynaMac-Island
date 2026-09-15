import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

for action in ["playpause", "next track", "previous track"]:
    old = f'        _ = runAppleScript(app: activeApp, command: "{action}")\\n        pollImmediately()'
    new = f'        let active = activeApp\\n        DispatchQueue.global(qos: .userInitiated).async {{\\n            _ = self.runAppleScript(app: active, command: "{action}")\\n            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {{ self.pollMediaStatus() }}\\n        }}'
    text = text.replace(old, new)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
