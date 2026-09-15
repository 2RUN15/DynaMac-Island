import Foundation
import Combine

/// Protocol defining the backend interface for monitoring system events.
protocol EventMonitoringService: AnyObject {
    var eventsPublisher: AnyPublisher<IslandEvent, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}

/// A strong backend service manager for monitoring state.
/// For the free version, this uses simulated/mock hooks to display UI easily.
class SystemEventMonitor: EventMonitoringService {
    private var eventsSubject = PassthroughSubject<IslandEvent, Never>()
    private var dummyActivityTimer: Timer?
    
    var eventsPublisher: AnyPublisher<IslandEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        // Here you would normally set up IOKit observers, MPNowPlayingInfo hooks, etc.
        // For the simplified free-version UI demo, we simulate events.
        simulateEventsForUI()
    }
    
    func stopMonitoring() {
        dummyActivityTimer?.invalidate()
        dummyActivityTimer = nil
    }
    
    private func simulateEventsForUI() {
        // Publish an initial event
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.eventsSubject.send(IslandEvent(type: .generic(title: "Alclove Başlatıldı", icon: "sparkles")))
        }
        
        let events: [IslandEvent] = [
            IslandEvent(type: .battery(level: 100, isCharging: true)),
            IslandEvent(type: .volume(level: 75.0)),
            IslandEvent(type: .music(song: "Bohemian Rhapsody", artist: "Queen"))
        ]
        
        var index = 0
        dummyActivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.eventsSubject.send(events[index % events.count])
            index += 1
        }
    }
}
