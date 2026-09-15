import Foundation
import Combine
import AppKit
import SwiftUI
import Carbon

// Average Color Extension
extension NSImage {
    var dominantColor: Color {
        var imageRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        guard let cgImage = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else { return .purple }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rgba = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
            return .purple
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let r = Double(rgba[0]) / 255.0
        let g = Double(rgba[1]) / 255.0
        let b = Double(rgba[2]) / 255.0
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        
        var finalR = r
        var finalG = g
        var finalB = b
        
        if brightness < 0.25 {
            finalR = min(r + 0.35, 1.0)
            finalG = min(g + 0.35, 1.0)
            finalB = min(b + 0.35, 1.0)
        }
        
        return Color(red: finalR, green: finalG, blue: finalB)
    }
}

protocol MediaServiceProtocol: AnyObject {
    var mediaStatePublisher: AnyPublisher<MediaState, Never> { get }
    func togglePlayPause()
    func nextTrack()
    func previousTrack()
    func setPlayerPosition(to time: TimeInterval)
    func toggleShuffle()
}

enum MediaPlayerType: String {
    case music = "Music"
    case spotify = "Spotify"
    
    var bundleId: String {
        switch self {
        case .music: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        }
    }
}

class MediaService: MediaServiceProtocol {
    @Published private var state: MediaState
    private var timer: Timer?
    
    var mediaStatePublisher: AnyPublisher<MediaState, Never> {
        $state.eraseToAnyPublisher()
    }
    
    private var activePlayer: MediaPlayerType? = nil
    private var currentSongIdentity: String = ""
    private var cachedArtwork: NSImage?
    private var cachedColor: Color = .purple
    private var artworkRetries: Int = 0
    
    init() {
        self.state = MediaState(
            song: "Şu An Çalınmıyor",
            artist: "Oynatıcı kapalı veya boş",
            coverIcon: "music.note",
            isPlaying: false,
            currentTime: 0.0,
            duration: 1.0,
            artworkImage: nil,
            dominantColor: .purple,
            isShuffleEnabled: false
        )
        
        startPolling()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollMediaStatus()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    // YENİ: Apple Event'leri daha stabil çalıştıran ve hata fırlatan yapı.
    private func executeScript(_ script: String) -> String? {
        return autoreleasepool {
            var errorInfo: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else { return nil }
            
            let eventResult = appleScript.executeAndReturnError(&errorInfo)
            
            if errorInfo != nil {
                return nil
            }
            
            return eventResult.stringValue
        }
    }
    
    func toggleShuffle() {
        guard let app = activePlayer else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let getStateScript = app == .spotify ? "get shuffling" : "get shuffle enabled"
            let setStateScript = app == .spotify ? "set shuffling to " : "set shuffle enabled to "
            
            let currentState = self.executeScript("tell application \"\(app.rawValue)\" to \(getStateScript)") == "true"
            let newState = !currentState
            
            _ = self.executeScript("tell application \"\(app.rawValue)\" to \(setStateScript)\(newState)")
            self.pollImmediately()
        }
    }

    func togglePlayPause() {
        guard let app = activePlayer else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeScript("tell application \"\(app.rawValue)\" to playpause")
            self.pollImmediately()
        }
    }
    
    func nextTrack() {
        guard let app = activePlayer else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeScript("tell application \"\(app.rawValue)\" to next track")
            self.pollImmediately()
        }
    }
    
    func previousTrack() {
        guard let app = activePlayer else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.executeScript("tell application \"\(app.rawValue)\" to previous track")
            self.pollImmediately()
        }
    }
    
    func setPlayerPosition(to time: TimeInterval) {
        guard let app = activePlayer else { return }
        
        // Virgül hatasından kaçınmak için noktaya dönüştürüldü
        let formattedTime = String(format: "%.1f", time).replacingOccurrences(of: ",", with: ".")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // "tell application" bloğu try içine alınarak çökme engellendi
            let script = """
            try
                tell application "\(app.rawValue)" to set player position to \(formattedTime)
            end try
            """
            
            _ = self.executeScript(script)
            
            // Müziğin komuta yetişmesi için 0.4 sn bekle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.pollMediaStatus()
            }
        }
    }
    
    private func pollImmediately() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.pollMediaStatus() }
    }
    
    private func pollMediaStatus() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let isSpotifyRunning = self.isAppRunning(bundleId: MediaPlayerType.spotify.bundleId)
            let isMusicRunning = self.isAppRunning(bundleId: MediaPlayerType.music.bundleId)
            
            var targetApp: MediaPlayerType? = nil
            
            if isSpotifyRunning && isMusicRunning {
                let spotifyState = self.executeScript("tell application \"Spotify\" to player state as string") ?? ""
                let musicState = self.executeScript("tell application \"Music\" to player state as string") ?? ""
                
                let isSpotifyPlaying = spotifyState.lowercased().contains("playing")
                let isMusicPlaying = musicState.lowercased().contains("playing")
                
                if isSpotifyPlaying {
                    targetApp = .spotify
                } else if isMusicPlaying {
                    targetApp = .music
                } else {
                    // Eğer ikisi de duraklatılmış (paused) ise, son aktif olanı veya durumu paused olanı tut
                    if self.activePlayer == .spotify && spotifyState.lowercased().contains("paused") {
                        targetApp = .spotify
                    } else if self.activePlayer == .music && musicState.lowercased().contains("paused") {
                        targetApp = .music
                    } else if spotifyState.lowercased().contains("paused") {
                        targetApp = .spotify
                    } else {
                        targetApp = .music
                    }
                }
            } else if isSpotifyRunning {
                targetApp = .spotify
            } else if isMusicRunning {
                targetApp = .music
            }
            
            guard let app = targetApp else {
                DispatchQueue.main.async {
                    if self.state.song != "Şu An Çalınmıyor" {
                        self.state = MediaState(song: "Şu An Çalınmıyor", artist: "", coverIcon: "music.note", isPlaying: false, currentTime: 0, duration: 1, artworkImage: nil, dominantColor: .purple)
                    }
                }
                return
            }
            
            // YENİ: Parçalanmış ve ÇOK DAHA güvenilir (Robust) Veri Çekme Lojik Katmanı
            let shuffleProperty = app == .spotify ? "shuffling" : "shuffle enabled"
            let artScript = app == .spotify ? "\n                try\n                    set theArtUrl to artwork url of current track\n                end try" : ""
            
            let script = """
            tell application "\(app.rawValue)"
                try
                    set theState to player state as string
                on error
                    return ""
                end try
                
                if theState is "stopped" then return ""
                
                try
                    set theName to name of current track as string
                on error
                    set theName to "Bilinmeyen Şarkı"
                end try
                
                try
                    set theArtist to artist of current track as string
                on error
                    set theArtist to "Bilinmeyen Sanatçı"
                end try
                
                try
                    set theDuration to (duration of current track) as string
                on error
                    set theDuration to "1"
                end try
                
                try
                    set thePosition to (player position) as string
                on error
                    set thePosition to "0"
                end try
                
                set theShuffle to "false"
                try
                    set theShuffle to (\(shuffleProperty)) as string
                end try
                
                set theArtUrl to "NONE" \(artScript)
                
                return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition & "|||" & theArtUrl & "|||" & theShuffle
            end tell
            """
            
            if let result = self.executeScript(script), !result.isEmpty, let baseState = self.parseResponse(result, app: app) {
                
                let trackId = "\(baseState.song)-\(baseState.artist)"
                
                // Track değiştiyse: Resmi ve Sayacı hemen sıfırla
                if self.currentSongIdentity != trackId {
                    self.currentSongIdentity = trackId
                    self.cachedArtwork = nil 
                    self.cachedColor = .purple
                    self.artworkRetries = 0 
                }
                
                // Kapak alınamadıysa Retry (Tekrar Deneme) bloğu (Network veya Bellek tıkanmasını bloklamaz)
                if self.cachedArtwork == nil && self.artworkRetries < 5 {
                    self.artworkRetries += 1
                    
                    if app == .music {
                        self.cachedArtwork = self.fetchMusicAppArtwork()
                    } else if app == .spotify, let urlString = baseState.coverIcon as String?, urlString.hasPrefix("http") {
                        if let url = URL(string: urlString) {
                            // URL Session kullanarak ASYNC indirme (Senkronu engellemek için)
                            let semaphore = DispatchSemaphore(value: 0)
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                if let data = data {
                                    self.cachedArtwork = NSImage(data: data)
                                }
                                semaphore.signal()
                            }.resume()
                            _ = semaphore.wait(timeout: .now() + 1.5) // Max 1.5 saniye bekle (Timeout)
                        }
                    }
                    
                    if let newArt = self.cachedArtwork {
                        self.cachedColor = newArt.dominantColor
                    }
                }
                
                DispatchQueue.main.async {
                    self.activePlayer = app
                    var finalState = baseState
                    
                    finalState.coverIcon = (app == .spotify) ? "antenna.radiowaves.left.and.right" : "applelogo"
                    finalState.artworkImage = self.cachedArtwork
                    finalState.dominantColor = self.cachedColor
                    self.state = finalState
                }
            }
        }
    }
    
    private func fetchMusicAppArtwork() -> NSImage? {
        return autoreleasepool {
            let script = "tell application \"Music\" to get raw data of artwork 1 of current track"
            var err: NSDictionary? = nil
            guard let appleScript = NSAppleScript(source: script) else { return nil }
            
            let eventResult = appleScript.executeAndReturnError(&err)
            
            if err == nil {
                return NSImage(data: eventResult.data)
            }
            return nil
        }
    }
    
    private func parseResponse(_ result: String, app: MediaPlayerType) -> MediaState? {
        let components = result.components(separatedBy: "|||")
        guard components.count >= 6 else { return nil }
        
        let song = components[0].isEmpty ? "Bilinmeyen Şarkı" : components[0]
        let artist = components[1].isEmpty ? "Bilinmeyen Sanatçı" : components[1]
        let stateStr = components[2].lowercased()
        let durationStr = components[3].replacingOccurrences(of: ",", with: ".")
        let positionStr = components[4].replacingOccurrences(of: ",", with: ".")
        let artUrl = components[5]
        
        let isPlaying = stateStr.contains("playing")
        let currentTime = Double(positionStr) ?? 0.0
        var duration = Double(durationStr) ?? 1.0
        
        if duration > 10000 { duration /= 1000 }
        if duration <= 0 { duration = 1.0 }
        
        let isShuffle = components.indices.contains(6) ? (components[6].lowercased() == "true") : false
        
        return MediaState(
            song: song,
            artist: artist,
            coverIcon: app == .spotify ? artUrl : "applelogo",
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration,
            artworkImage: nil,
            dominantColor: .purple,
            isShuffleEnabled: isShuffle
        )
    }
    
    private func isAppRunning(bundleId: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }
}
