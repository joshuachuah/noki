import AppKit
import Testing
@testable import Noki

struct IslandStateTests {
    private let paused = NowPlaying(
        id: "track",
        title: "Nightcall",
        artist: "Kavinsky",
        album: "OutRun",
        isPlaying: false,
        position: 20,
        duration: 100,
        observedAt: .now,
        artwork: nil,
        accent: .white
    )

    @Test func hoverAlwaysExpands() {
        #expect(islandState(nowPlaying: nil, hovering: true, pausedFor: nil) == .expanded)
        #expect(islandState(nowPlaying: paused, hovering: true, pausedFor: 300) == .expanded)
    }

    @Test func noNowPlayingIsHidden() {
        #expect(islandState(nowPlaying: nil, hovering: false, pausedFor: nil) == .hidden)
    }

    @Test func recentNowPlayingPeeks() {
        #expect(islandState(nowPlaying: paused, hovering: false, pausedFor: 179.9) == .peek)
    }

    @Test func longPausedNowPlayingIsHidden() {
        #expect(islandState(nowPlaying: paused, hovering: false, pausedFor: 180) == .hidden)
    }
}

