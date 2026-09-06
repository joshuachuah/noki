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

    @Test @MainActor func leavingKeepsTheIslandOpenBriefly() async throws {
        let model = IslandModel()
        model.updateNowPlaying(paused)
        model.pointerEntered()
        model.pointerExited()

        try await Task.sleep(for: .milliseconds(75))
        #expect(model.state == .expanded)
        try await Task.sleep(for: .milliseconds(150))
        #expect(model.state == .peek)
    }

    @Test @MainActor func returningCancelsThePendingClose() async throws {
        let model = IslandModel()
        model.pointerEntered()
        model.pointerExited()
        try await Task.sleep(for: .milliseconds(75))
        model.pointerEntered()

        try await Task.sleep(for: .milliseconds(200))
        #expect(model.state == .expanded)

        model.pointerExited()
        try await Task.sleep(for: .milliseconds(200))
        #expect(model.state == .hidden)
    }

    @Test @MainActor func continuedMovementOutsideDoesNotRestartTheCloseDelay() async throws {
        let model = IslandModel()
        model.pointerEntered()
        model.pointerExited()
        try await Task.sleep(for: .milliseconds(100))
        model.pointerExited()

        try await Task.sleep(for: .milliseconds(100))
        #expect(model.state == .hidden)
    }
}
