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

    @Test func noNowPlayingIsIdle() {
        #expect(islandState(nowPlaying: nil, hovering: false, pausedFor: nil) == .idle)
    }

    @Test func recentNowPlayingPeeks() {
        #expect(islandState(nowPlaying: paused, hovering: false, pausedFor: 179.9) == .peek)
    }

    @Test func longPausedNowPlayingIsIdle() {
        #expect(islandState(nowPlaying: paused, hovering: false, pausedFor: 180) == .idle)
    }

    @Test func panelMatchesTheVisibleIslandSize() {
        #expect(
            IslandLayout.panelSize(for: .idle, hasNowPlaying: false)
                == CGSize(width: 264, height: 32)
        )
        #expect(
            IslandLayout.panelSize(for: .peek, hasNowPlaying: true)
                == CGSize(width: 264, height: 32)
        )
        #expect(
            IslandLayout.panelSize(for: .expanded, hasNowPlaying: true)
                == CGSize(width: 392, height: 220)
        )
    }
}
