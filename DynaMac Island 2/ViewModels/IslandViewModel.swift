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
    
    // Takvim mantığı
    @Published var calendarEvents: [CalendarEvent] = []
    private var calendarService = CalendarService()
    
    // Batarya ve Anlık Bildirim (Transient Event) Mantığı
    @Published var activeTransientEvent: IslandEventType? = nil
    private var transientEventTimer: Timer?
    private var batteryService = BatteryService()
    var audioService = AudioDeviceService()
    
    // Scrub lastik bandı önleme mantığı
    @Published var ignoreUpdatesUntil: Date = Date.distantPast
    private var hasInitializedPlayState = false
    
    var hasActiveMusic: Bool {
        return mediaState.song != "Şu An Çalınmıyor" && !mediaState.song.isEmpty
    }
    
    var isExpanded: Bool {
        // Eğer fare ile üzerine gelinmişse VEYA geçici bir bildirim (örn: pil, ses) gösteriliyorsa adayı genişlet
        return isHovered || activeTransientEvent != nil
    }
    
    private let mediaService: MediaServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(mediaService: MediaServiceProtocol? = nil) {
        self.mediaService = mediaService ?? MediaService()
        self.mediaState = MediaState(song: "", artist: "", coverIcon: "", isPlaying: false, currentTime: 0, duration: 1, artworkImage: nil, dominantColor: .purple, isShuffleEnabled: false)
        
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
            
        self.audioService.deviceChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] name in
                self?.triggerDeviceEvent(name: name)
            }
            .store(in: &cancellables)
            
        // Ses seviyesi (donanım düğmeniyle vb) değiştirilirse bildirimi aç
        self.audioService.volumeChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] volume in
                self?.triggerVolumeEvent(level: volume)
            }
            .store(in: &cancellables)
            
        // Pil durumu değişimini dinle ve bildirim ekranı göster
        self.batteryService.powerChangePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.triggerBatteryEvent(state: state)
            }
            .store(in: &cancellables)
    }
    
    func triggerVolumeEvent(level: Double) {
        if isHovered { return } // Kullanıcı adanın üzerindeyse rahatsız etme, müziği/takvimi açık tut
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
            self.activeTransientEvent = .volume(level: level)
        }
        
        transientEventTimer?.invalidate()
        transientEventTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                    // Sadece hala volume gösteriliyorsa kapat (kullanıcı hover yapmışsa aktive edilmiş event değişir)
                    if case .volume = self?.activeTransientEvent {
                        self?.activeTransientEvent = nil
                    }
                }
            }
        }
    }
    
    func triggerDeviceEvent(name: String) {
        if isHovered { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
            self.activeTransientEvent = .audioDevice(name: name)
        }
        
        transientEventTimer?.invalidate()
        transientEventTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                    if case .audioDevice = self?.activeTransientEvent {
                        self?.activeTransientEvent = nil
                    }
                }
            }
        }
    }
    
    private func triggerBatteryEvent(state: BatteryState) {
        if isHovered { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
            self.activeTransientEvent = .battery(level: state.level, isCharging: state.isPlugged)
        }
        
        transientEventTimer?.invalidate()
        transientEventTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)) {
                    if case .battery = self?.activeTransientEvent {
                        self?.activeTransientEvent = nil
                    }
                }
            }
        }
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
    
    func toggleShuffle() {
        mediaService.toggleShuffle()
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
