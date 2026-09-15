import Foundation
import SwiftUI

struct MediaState: Equatable {
    var song: String
    var artist: String
    var coverIcon: String
    var isPlaying: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    var artworkImage: NSImage?
    var dominantColor: Color
    var isShuffleEnabled: Bool = false
}
