import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

replacement = """    func setPlayerPosition(to time: TimeInterval) {
        let intTime = Int(time)
        let active = activeApp
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "try\\n tell application \\"\\(active)\\" to set player position to \\(intTime)\\n end try"
            _ = self.runRawAppleScript(script)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.pollMediaStatus()
            }
        }
    }"""

text = re.sub(r'    func setPlayerPosition\(to time: TimeInterval\) \{[\s\S]*?pollMediaStatus\(\) \}\n    \}', replacement, text)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
