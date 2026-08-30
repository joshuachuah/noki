import AppKit
import Foundation

struct NowPlaying {
    let id: String
    let title: String
    let artist: String
    let album: String
    let isPlaying: Bool
    let position: TimeInterval
    let duration: TimeInterval
    let observedAt: Date
    var artwork: NSImage?
    var accent: NSColor

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }

    func progress(at date: Date) -> Double {
        guard isPlaying, duration > 0 else { return progress }
        let estimatedPosition = position + date.timeIntervalSince(observedAt)
        return min(max(estimatedPosition / duration, 0), 1)
    }
}

