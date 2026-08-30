import AppKit
import Foundation

@MainActor
final class SpotifyObserver: NSObject {
    private let model: IslandModel
    private let spotify: Spotify
    private var artworkTask: Task<Void, Never>?

    init(model: IslandModel, spotify: Spotify) {
        self.model = model
        self.spotify = spotify
    }

    func start() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(playbackDidChange(_:)),
            name: Notification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        refreshFromSpotify()
    }

    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        artworkTask?.cancel()
    }

    @objc private func playbackDidChange(_ notification: Notification) {
        receivePlaybackChange(notification)
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            app.bundleIdentifier == "com.spotify.client"
        else { return }
        artworkTask?.cancel()
        model.updateNowPlaying(nil)
    }

    private func receivePlaybackChange(_ notification: Notification) {
        guard let update = NowPlaying(notification: notification) else {
            refreshFromSpotify()
            return
        }
        let trackChanged = update.id != model.nowPlaying?.id
        model.updateNowPlaying(update)
        if trackChanged { loadArtwork(for: update.id) }
    }

    private func refreshFromSpotify() {
        do {
            let update = try spotify.readNowPlaying()
            model.updateNowPlaying(update)
            if let update { loadArtwork(for: update.id) }
        } catch {
            model.updateNowPlaying(nil)
        }
    }

    private func loadArtwork(for trackID: String) {
        artworkTask?.cancel()
        artworkTask = Task { [weak self] in
            guard let self, let url = try? spotify.artworkURL() else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            guard !Task.isCancelled, let image = NSImage(data: data) else { return }
            model.setArtwork(image, accent: ArtworkAccent.extract(from: image), for: trackID)
        }
    }
}

private extension NowPlaying {
    init?(notification: Notification) {
        guard let values = notification.userInfo else { return nil }

        func string(_ keys: String...) -> String? {
            for key in keys {
                if let value = values[key] as? String { return value }
            }
            return nil
        }

        func number(_ keys: String...) -> TimeInterval {
            for key in keys {
                if let value = values[key] as? NSNumber { return value.doubleValue }
                if let value = values[key] as? String, let number = TimeInterval(value) { return number }
            }
            return 0
        }

        guard let title = string("Name", "name") else { return nil }
        let rawDuration = number("Duration", "duration")
        self.init(
            id: string("Track ID", "TrackID", "id") ?? "\(title)|\(string("Artist", "artist") ?? "")",
            title: title,
            artist: string("Artist", "artist") ?? "",
            album: string("Album", "album") ?? "",
            isPlaying: string("Player State", "PlayerState", "state")?.lowercased() == "playing",
            position: number("Playback Position", "PlaybackPosition", "position"),
            duration: rawDuration > 10_000 ? rawDuration / 1_000 : rawDuration,
            observedAt: .now,
            artwork: nil,
            accent: .white
        )
    }
}
