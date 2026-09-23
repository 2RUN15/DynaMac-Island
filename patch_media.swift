import Foundation

let path = "DynaMac Island 2/Core/Services/MediaService.swift"
if var content = try? String(contentsOfFile: path) {
    // Inject distributed notifications
    let notifs = """
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(mediaStateDidChange),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(mediaStateDidChange),
            name: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil
        )
"""
    
    // add it in init()
    content = content.replacingOccurrences(of: "        startPolling()\n    }", with: "        startPolling()\n\(notifs)    }")
    
    // add the objc function
    let objcFunc = """
    @objc private func mediaStateDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.fetchState()
        }
    }
"""
    content = content.replacingOccurrences(of: "    private func startPolling() {", objcFunc + "\n    private func startPolling() {")
    
    // change the polling timer from 2.0 to 4.0 seconds
    content = content.replacingOccurrences(of: "timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true)", with: "timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true)")
    
    // avoid executing apple script if app is paused for a long time?
    // Not directly needed since we slowed it to 4 seconds, and mostly rely on instant NSNotifications anyway.
    
    try? content.write(toFile: path, atomically: true, encoding: .utf8)
    print("Patched MediaService.swift")
}
