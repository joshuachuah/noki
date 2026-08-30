import AppKit
import Foundation
import Testing
@testable import Noki

struct NowPlayingTests {
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
