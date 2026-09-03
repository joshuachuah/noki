import AppKit
import Foundation

@MainActor
final class Spotify {
    enum CommandError: Error {
        case appleScript(String)
        case malformedResponse
    }

    func readNowPlaying() throws -> NowPlaying? {
        guard isRunning else { return nil }

        let separator = "\u{1F}"
        let source = """
        tell application "Spotify"
            if player state is stopped then return ""
            set currentItem to current track
            set fields to {id of currentItem, name of currentItem, artist of currentItem, album of currentItem, player state as text, player position as text, duration of currentItem as text}
            set AppleScript's text item delimiters to "(separator)"
            return fields as text
        end tell
        """
        let value = try run(source)
        guard !value.isEmpty else { return nil }
        let fields = value.components(separatedBy: separator)
        guard fields.count == 7 else { throw CommandError.malformedResponse }

        return NowPlaying(
            id: fields[0],
            title: fields[1],
            artist: fields[2],
            album: fields[3],
            isPlaying: fields[4].lowercased() == "playing",
            position: TimeInterval(fields[5]) ?? 0,
            duration: (TimeInterval(fields[6]) ?? 0) / 1_000,
            observedAt: .now,
            artwork: nil,
            accent: .white
        )
    }

    func artworkURL() throws -> URL? {
        guard isRunning else { return nil }
        let value = try run("tell application \"Spotify\" to return artwork url of current track")
        return URL(string: value)
    }

    func playPause() { _ = try? run("tell application \"Spotify\" to playpause") }
    func next() { _ = try? run("tell application \"Spotify\" to next track") }
    func previous() { _ = try? run("tell application \"Spotify\" to previous track") }

    /// Opens the current track in the Spotify app.
    func openTrack(id: String) {
        let uri = id.hasPrefix("spotify:") ? id : "spotify:track:\(id)"
        open(uri: uri)
    }

    /// AppleScript exposes the artist name but not its URI, so this opens a Spotify search instead.
    func openArtist(named artist: String) {
        guard let query = "artist:\(artist)"
            .addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        else {
            NSSound.beep()
            return
        }

        open(uri: "spotify:search:\(query)")
    }

    /// Spotify's own volume, 0 to 100. Independent of the system volume.
    func readVolume() throws -> Int {
        let value = try run("tell application \"Spotify\" to return sound volume as text")
        guard let volume = Int(value) else { throw CommandError.malformedResponse }
        return volume
    }

    func setVolume(_ volume: Int) {
        _ = try? run("tell application \"Spotify\" to set sound volume to \(min(max(volume, 0), 100))")
    }

    func readShuffling() throws -> Bool {
        let value = try run("tell application \"Spotify\" to return shuffling as text")
        switch value.lowercased() {
        case "true": return true
        case "false": return false
        default: throw CommandError.malformedResponse
        }
    }

    func setShuffling(_ isShuffling: Bool) {
        _ = try? run("tell application \"Spotify\" to set shuffling to \(isShuffling)")
    }

    func play(uri: String) {
        let escaped = uri.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        _ = try? run("tell application \"Spotify\" to play track \"\(escaped)\"")
    }

    private func open(uri: String) {
        guard let url = URL(string: uri) else {
            NSSound.beep()
            return
        }

        NSWorkspace.shared.open(url)
    }

    private var isRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.spotify.client"
        }
    }

    @discardableResult
    private func run(_ source: String) throws -> String {
        guard let script = NSAppleScript(source: source) else {
            throw CommandError.malformedResponse
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw CommandError.appleScript(errorInfo.description)
        }
        return result.stringValue ?? ""
    }
}
