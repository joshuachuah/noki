import AppKit
import Foundation
import Testing
@testable import Noki

struct NowPlayingTests {
    @Test(arguments: [
        (0.0, "0:00"),
        (59.0, "0:59"),
        (60.0, "1:00"),
        (61.0, "1:01"),
        (3_599.0, "59:59"),
        (-1.0, "0:00"),
    ])
    func formatsTime(seconds: TimeInterval, expected: String) {
        #expect(formatTime(seconds) == expected)
    }

    @Test func clampsTimeLabelsToTrackBounds() {
        let observedAt = Date(timeIntervalSinceReferenceDate: 100)
        let beforeStart = NowPlaying(
            id: "track",
            title: "Nightcall",
            artist: "Kavinsky",
            album: "OutRun",
            isPlaying: false,
            position: -10,
            duration: 60,
            observedAt: observedAt,
            artwork: nil,
            accent: .white
        )
        let pastEnd = NowPlaying(
            id: "track",
            title: "Nightcall",
            artist: "Kavinsky",
            album: "OutRun",
            isPlaying: false,
            position: 70,
            duration: 60,
            observedAt: observedAt,
            artwork: nil,
            accent: .white
        )

        #expect(beforeStart.elapsedLabel(at: observedAt) == "0:00")
        #expect(beforeStart.remainingLabel(at: observedAt) == "-1:00")
        #expect(pastEnd.elapsedLabel(at: observedAt) == "1:00")
        #expect(pastEnd.remainingLabel(at: observedAt) == "-0:00")
    }

    @Test func estimatesProgressOnlyWhilePlaying() {
        let observedAt = Date(timeIntervalSinceReferenceDate: 100)
        let playing = NowPlaying(
            id: "track",
            title: "Title",
            artist: "Artist",
            album: "Album",
            isPlaying: true,
            position: 20,
            duration: 100,
            observedAt: observedAt,
            artwork: nil,
            accent: .white
        )
        let paused = NowPlaying(
            id: "track",
            title: "Title",
            artist: "Artist",
            album: "Album",
            isPlaying: false,
            position: 20,
            duration: 100,
            observedAt: observedAt,
            artwork: nil,
            accent: .white
        )

        #expect(playing.progress(at: observedAt.addingTimeInterval(10)) == 0.3)
        #expect(paused.progress(at: observedAt.addingTimeInterval(10)) == 0.2)
    }

    @Test func clampsProgress() {
        let playing = NowPlaying(
            id: "track",
            title: "Title",
            artist: "Artist",
            album: "Album",
            isPlaying: true,
            position: 99,
            duration: 100,
            observedAt: .now,
            artwork: nil,
            accent: .white
        )
        #expect(playing.progress(at: playing.observedAt.addingTimeInterval(20)) == 1)
    }
}
