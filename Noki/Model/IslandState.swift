import AppKit
import Foundation
import Observation

enum IslandState: Equatable {
    case hidden
    case peek
    case expanded
}

func islandState(
    nowPlaying: NowPlaying?,
    hovering: Bool,
    pausedFor: TimeInterval?
) -> IslandState {
    if hovering { return .expanded }
    guard nowPlaying != nil else { return .hidden }
    if let pausedFor, pausedFor >= 180 { return .hidden }
    return .peek
}

@MainActor
@Observable
final class IslandModel {
    private(set) var nowPlaying: NowPlaying?
    private(set) var isHovering = false
    private(set) var pausedSince: Date?

    private var hoverLeaveTask: Task<Void, Never>?
    private var pauseDeadlineTask: Task<Void, Never>?
    private var clock = Date.now

    var state: IslandState {
        islandState(
            nowPlaying: nowPlaying,
            hovering: isHovering,
            pausedFor: pausedSince.map { clock.timeIntervalSince($0) }
        )
    }

    func updateNowPlaying(_ update: NowPlaying?) {
        if var update, let existing = nowPlaying, update.id == existing.id, update.artwork == nil {
            update.artwork = existing.artwork
            update.accent = existing.accent
            nowPlaying = update
        } else {
            nowPlaying = update
        }

        if nowPlaying?.isPlaying == true {
            pausedSince = nil
            pauseDeadlineTask?.cancel()
        } else if nowPlaying != nil, pausedSince == nil {
            pausedSince = .now
            schedulePauseDeadline()
        } else if nowPlaying == nil {
            pausedSince = nil
            pauseDeadlineTask?.cancel()
        }
    }

    func setArtwork(_ image: NSImage, accent: NSColor, for trackID: String) {
        guard nowPlaying?.id == trackID else { return }
        nowPlaying?.artwork = image
        nowPlaying?.accent = accent
    }

    func pointerEntered() {
        hoverLeaveTask?.cancel()
        isHovering = true
    }

    func pointerExited() {
        hoverLeaveTask?.cancel()
        hoverLeaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            self?.isHovering = false
        }
    }

    private func schedulePauseDeadline() {
        pauseDeadlineTask?.cancel()
        pauseDeadlineTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(180))
            guard !Task.isCancelled, let self else { return }
            self.clock = .now
        }
    }
}
