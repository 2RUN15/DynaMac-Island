import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

# Refactor executeScript
executeScriptOld = """    private func executeScript(_ script: String) -> String? {
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        
        let eventResult = appleScript.executeAndReturnError(&errorInfo)
        
        if let error = errorInfo {
            // Eğer AppleScript hata verirse (örneğin uygulama kilitli vs.) nil döner, böylece UI kitlenmez.
            print("AppleScript Hata: \\(error)")
            return nil
        }
        
        return eventResult.stringValue
    }"""

executeScriptNew = """    private func executeScript(_ script: String) -> String? {
        return autoreleasepool {
            var errorInfo: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else { return nil }
            
            let eventResult = appleScript.executeAndReturnError(&errorInfo)
            
            if let error = errorInfo {
                return nil
            }
            
            return eventResult.stringValue
        }
    }"""
text = text.replace(executeScriptOld, executeScriptNew)

# Refactor fetchMusicAppArtwork
fetchArtworkOld = """    private func fetchMusicAppArtwork() -> NSImage? {
        let script = "tell application \\"Music\\" to get raw data of artwork 1 of current track"
        var err: NSDictionary? = nil
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        
        let eventResult = appleScript.executeAndReturnError(&err)
        
        if err == nil {
            return NSImage(data: eventResult.data)
        }
        return nil
    }"""

fetchArtworkNew = """    private func fetchMusicAppArtwork() -> NSImage? {
        return autoreleasepool {
            let script = "tell application \\"Music\\" to get raw data of artwork 1 of current track"
            var err: NSDictionary? = nil
            guard let appleScript = NSAppleScript(source: script) else { return nil }
            
            let eventResult = appleScript.executeAndReturnError(&err)
            
            if err == nil {
                return NSImage(data: eventResult.data)
            }
            return nil
        }
    }"""
text = text.replace(fetchArtworkOld, fetchArtworkNew)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
