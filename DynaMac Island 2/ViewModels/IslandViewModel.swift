import SwiftUI
import Combine
import AppKit

@MainActor
class IslandViewModel: ObservableObject {
    @Published var mediaState: MediaState
    @Published var isHovered: Bool = false
    
    @Published var editingTime: TimeInterval = 0
    @Published var isScrubbing: Bool = false
    
    @Published var hardwareNotchWidth: CGFloat = 180.0
    @Published var hardwareNotchHeight: CGFloat = 32.0
    
    // Auto-fade mantığı
    @Published var isIdleTimeout: Bool = false
    private var idleTask: Task<Void, Never>?
    
    // Scrub lastik bandı önleme mantığı (Seek'ten hemen sonraki pollingleri yoksaymak için)
    @Published var ignoreUpdatesUntil: Date = Date.distantPast
    
    // Takvim mantığı
    @Published var calendarEvents: [CalendarEvent] = []
    private var calendarService = CalendarService()
    
    var hasActiveMusic: Bool {
        return mediaState.song != "Şu An Çalınmıyor" && !mediaState.song.isEmpty
    }
    
    var isExpanded: Bool {
        return isHovered
    }
    
    private let mediaService: MediaServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var hasInitializedPlayState = false
    
    init(mediaService: MediaServiceProtocol? = nil) {
        self.mediaService = mediaService ?? MediaService()
        self.mediaState = MediaState(song: "", artist: "", coverIcon: "", isPlaying: false, currentTime: 0, duration: 1, artworkImage: nil, dominantColor: .purple)
        
        self.calendarService.$upcomingEvents
            .receive(on: RunLoop.main)
            .assign(to: \.calendarEvents, on: self)
            .store(in: &cancellables)
            
        calculateNotchDimensions()
        
        self.mediaService.mediaStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                
                // Müzik Durumu değiştiğinde veya uygulama yeni açıldığında Timeout lojiğini tetikleme
                if state.isPlaying != self.mediaState.isPlaying || (!self.hasInitializedPlayState && state.song != "Şu An Çalınmıyor") {
                    self.hasInitializedPlayState = true
                    self.handlePlayStateChange(state.isPlaying)
                }
                
                self.mediaState = state
                
                // Eğer barı sürüklüyorsa veya sürüklemeyi yeni bırakmışsa barı titretme
                if !self.isScrubbing && Date() > self.ignoreUpdatesUntil {
                    self.editingTime = state.currentTime
                }
            }
            .store(in: &cancellables)
    }
    
    private func handlePlayStateChange(_ isPlaying: Bool) {
        idleTask?.cancel()
        
        if isPlaying {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isIdleTimeout = false
            }
        } else {
            idleTask = Task {
                let userTimeout = UserDefaults.standard.double(forKey: "autoFadeTimeout")
                let delay = userTimeout > 0 ? userTimeout : 7.0
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        self.isIdleTimeout = true
                    }
                }
            }
        }
    }
    
    private func calculateNotchDimensions() {
        #if os(macOS)
        if #available(macOS 12.0, *) {
            if let screen = NSScreen.main {
                if let left = screen.auxiliaryTopLeftArea,
                   let right = screen.auxiliaryTopRightArea {
                    
                    self.hardwareNotchWidth = screen.frame.width - left.width - right.width
                    self.hardwareNotchHeight = left.height 
                    return
                }
            }
        }
        self.hardwareNotchWidth = 179.0
        self.hardwareNotchHeight = 32.0
        #endif
    }
    
    func togglePlayPause() {
        mediaService.togglePlayPause()
    }
    
    func nextTrack() {
        mediaService.nextTrack()
    }
    
    func previousTrack() {
        mediaService.previousTrack()
    }
    
    func seekTime(to time: TimeInterval) {
        // Çubuğu bıraktıktan sonra 2 saniye boyunca müzik dinleyicisinden gelen saniyeleri engelle.
        // Böylece "eski" saniyeye hoplama/titreme olmadan doğrudan müziğin atlamasını sağlamış olursun.
        ignoreUpdatesUntil = Date().addingTimeInterval(2.0)
        mediaService.setPlayerPosition(to: time)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let maxTime = max(0, time)
        let minutes = Int(maxTime) / 60
        let seconds = Int(maxTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
