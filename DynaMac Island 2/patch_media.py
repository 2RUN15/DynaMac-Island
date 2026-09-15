import re

with open("Core/Services/MediaService.swift", "r") as f:
    text = f.read()

# 1. Update Protocol
text = text.replace("    func setPlayerPosition(to time: TimeInterval)\n}", "    func setPlayerPosition(to time: TimeInterval)\n    func toggleShuffle()\n}")

# 2. Add toggleShuffle method
toggle_code = """    func toggleShuffle() {
        guard let app = activePlayer else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let getStateScript = app == .spotify ? "get shuffling" : "get shuffle enabled"
            let setStateScript = app == .spotify ? "set shuffling to " : "set shuffle enabled to "
            
            let currentState = self.executeScript("tell application \\"\\(app.rawValue)\\" to \\(getStateScript)") == "true"
            let newState = !currentState
            
            _ = self.executeScript("tell application \\"\\(app.rawValue)\\" to \\(setStateScript)\\(newState)")
            self.pollImmediately()
        }
    }
"""
text = text.replace("    func togglePlayPause() {", toggle_code + "\n    func togglePlayPause() {")

# 3. Update AppleScript execution
script_old = """                try
                    set thePosition to player position
                on error
                    set thePosition to 0
                end try
                
                set theArtUrl to "NONE"
                if "\\(app.rawValue)" is "Spotify" then
                    try
                        set theArtUrl to artwork url of current track
                    end try
                end if
                
                return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition & "|||" & theArtUrl"""

script_new = """                try
                    set thePosition to player position
                on error
                    set thePosition to 0
                end try
                
                set theShuffle to false
                try
                    if "\\(app.rawValue)" is "Spotify" then
                        set theShuffle to shuffling
                    else
                        set theShuffle to shuffle enabled
                    end if
                end try
                
                set theArtUrl to "NONE"
                if "\\(app.rawValue)" is "Spotify" then
                    try
                        set theArtUrl to artwork url of current track
                    end try
                end if
                
                return theName & "|||" & theArtist & "|||" & theState & "|||" & theDuration & "|||" & thePosition & "|||" & theArtUrl & "|||" & theShuffle"""
text = text.replace(script_old, script_new)

# 4. Update parseResponse
parse_old = """        return MediaState(
            song: song,
            artist: artist,
            coverIcon: app == .spotify ? artUrl : "applelogo",
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration,
            artworkImage: nil, // Referans güncelleniyor
            dominantColor: .purple
        )"""

parse_new = """        let isShuffle = components.indices.contains(6) ? (components[6].lowercased() == "true") : false
        
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
        )"""
text = text.replace(parse_old, parse_new)

# Initializer Fix (in class init)
init_old = """        self.state = MediaState(
            song: "Şu An Çalınmıyor",
            artist: "Oynatıcı kapalı veya boş",
            coverIcon: "music.note",
            isPlaying: false,
            currentTime: 0.0,
            duration: 1.0,
            artworkImage: nil,
            dominantColor: .purple
        )"""

init_new = """        self.state = MediaState(
            song: "Şu An Çalınmıyor",
            artist: "Oynatıcı kapalı veya boş",
            coverIcon: "music.note",
            isPlaying: false,
            currentTime: 0.0,
            duration: 1.0,
            artworkImage: nil,
            dominantColor: .purple,
            isShuffleEnabled: false
        )"""
text = text.replace(init_old, init_new)

with open("Core/Services/MediaService.swift", "w") as f:
    f.write(text)
