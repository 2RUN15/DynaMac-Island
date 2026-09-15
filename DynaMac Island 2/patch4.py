import re

# PATCH 1: Fix Image updates in ContentView
with open("ContentView.swift", "r") as f:
    text = f.read()

# Add .id to Image(nsImage:) inside expanded media view
text = text.replace('Image(nsImage: nsImage)\\n                        .resizable()', 
                    'Image(nsImage: nsImage)\\n                        .resizable()\\n                        .id(viewModel.mediaState.song + "exp")')

# Add .id to Image(nsImage:) inside idle media view
text = text.replace('Image(nsImage: nsImage)\\n                            .resizable()', 
                    'Image(nsImage: nsImage)\\n                            .resizable()\\n                            .id(viewModel.mediaState.song + "idle")')

with open("ContentView.swift", "w") as f:
    f.write(text)


# PATCH 2: Dispatch AppleScript execution for setPlayerPosition to background
with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

replacement = """    func setPlayerPosition(to time: TimeInterval) {
        let intTime = Int(time)
        let active = activeApp
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "tell application \\"\\(active)\\" to set player position to \\(intTime)"
            _ = self.runRawAppleScript(script)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.pollMediaStatus()
            }
        }
    }"""

text = re.sub(r'    func setPlayerPosition\(to time: TimeInterval\) \{[\s\S]*?pollImmediately\(\)\n    \}', replacement, text)

# Just in case, let's also fix toggle, next, previous so they don't block main thread AppleEvents
for action in ["playpause", "next track", "previous track"]:
    old = f'        _ = runAppleScript(app: activeApp, command: "{action}")\\n        pollImmediately()'
    new = f'        let active = activeApp\\n        DispatchQueue.global(qos: .userInitiated).async {{\\n            _ = self.runAppleScript(app: active, command: "{action}")\\n            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {{ self.pollMediaStatus() }}\\n        }}'
    text = text.replace(old, new)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)

