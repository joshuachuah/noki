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

    func elapsedLabel(at date: Date) -> String {
        formatTime(estimatedPosition(at: date))
    }

    func remainingLabel(at date: Date) -> String {
        "-\(formatTime(duration - estimatedPosition(at: date)))"
    }

    private func estimatedPosition(at date: Date) -> TimeInterval {
        let estimate = isPlaying ? position + date.timeIntervalSince(observedAt) : position
        return min(max(estimate, 0), max(duration, 0))
    }
}

func formatTime(_ seconds: TimeInterval) -> String {
    let wholeSeconds = max(Int(seconds), 0)
    return "\(wholeSeconds / 60):\(String(format: "%02d", wholeSeconds % 60))"
}
