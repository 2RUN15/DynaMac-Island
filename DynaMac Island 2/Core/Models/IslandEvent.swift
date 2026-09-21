import Foundation

/// Enum representing the core types of events that the Dynamic Island will display.
enum IslandEventType: Equatable {
    case music(song: String, artist: String)
    case battery(level: Int, isCharging: Bool)
    case volume(level: Double)
    case brightness(level: Double)
    case audioDevice(name: String, battery: Int?)
    case generic(title: String, icon: String)
}

/// The core domain model for an event to be shown on the Island.
struct IslandEvent: Identifiable, Equatable {
    let id: UUID
    let type: IslandEventType
    let timestamp: Date
    let duration: TimeInterval?
    
    init(id: UUID = UUID(), type: IslandEventType, timestamp: Date = Date(), duration: TimeInterval? = 3.0) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.duration = duration
    }
}
