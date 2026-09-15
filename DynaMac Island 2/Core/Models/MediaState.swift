import Foundation
import AppKit
import SwiftUI

struct MediaState: Equatable {
    var song: String
    var artist: String
    var coverIcon: String
    var isPlaying: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    
    // YENİ: Gerçek kapak resmi için
    var artworkImage: NSImage?
    var dominantColor: Color = .purple

    
    // Equatable için (NSImage her zaman re-render etmesin)
    static func == (lhs: MediaState, rhs: MediaState) -> Bool {
        return lhs.song == rhs.song &&
               lhs.artist == rhs.artist &&
               lhs.isPlaying == rhs.isPlaying &&
               lhs.currentTime == rhs.currentTime &&
               lhs.duration == rhs.duration &&
               lhs.artworkImage == rhs.artworkImage
    }
}
