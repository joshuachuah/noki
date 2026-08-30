import SwiftUI

struct ExpandedView: View {
    let nowPlaying: NowPlaying?
    let pins: [Pin]
    let pinLoadError: String?
    let spotify: Spotify
    let editPins: () -> Void

    var body: some View {
        Group {
            if let nowPlaying {
                NowPlayingRow(nowPlaying: nowPlaying, spotify: spotify)
            } else {
                PinsRow(
                    pins: pins,
                    loadError: pinLoadError,
                    play: spotify.play,
                    editPins: editPins
                )
            }
        }
        .frame(width: 540, height: 100)
    }
}

private struct NowPlayingRow: View {
    let nowPlaying: NowPlaying
    let spotify: Spotify

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            ZStack(alignment: .bottomLeading) {
                HStack(spacing: 14) {
                    Button {
                        spotify.openTrack(id: nowPlaying.id)
                    } label: {
                        ArtworkView(image: nowPlaying.artwork, cornerRadius: 10)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(nowPlaying.title) in Spotify")
                    .help("Open song in Spotify")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        ArtistButton(name: nowPlaying.artist, spotify: spotify)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VolumeSlider(spotify: spotify)

                    TransportControls(nowPlaying: nowPlaying, spotify: spotify)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 20)

                ProgressBar(
                    progress: nowPlaying.progress(at: timeline.date),
                    accent: Color(nsColor: nowPlaying.accent)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct ArtistButton: View {
    let name: String
    let spotify: Spotify

    @State private var isHovering = false

    var body: some View {
        Button {
            spotify.openArtist(named: name)
        } label: {
            Text(name)
                .font(.system(size: 13))
                .foregroundStyle(
                    isHovering
                        ? Color.white
                        : Color(red: 0.604, green: 0.604, blue: 0.635)
                )
                .lineLimit(1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(name) in Spotify")
        .help("Open artist in Spotify")
        .onHover { isHovering = $0 }
    }
}

private struct TransportControls: View {
    let nowPlaying: NowPlaying
    let spotify: Spotify

    var body: some View {
        HStack(spacing: 14) {
            ControlButton(symbol: "backward.fill", label: "Previous", action: spotify.previous)
            ControlButton(
                symbol: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                label: nowPlaying.isPlaying ? "Pause" : "Play",
                action: spotify.playPause
            )
            ControlButton(symbol: "forward.fill", label: "Next", action: spotify.next)
        }
    }
}

private struct ControlButton: View {
    let symbol: String
    let label: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: symbol == "play.fill" || symbol == "pause.fill" ? 16 : 14, weight: .medium))
                .foregroundStyle(.white.opacity(isHovering ? 1 : 0.92))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .onHover { isHovering = $0 }
    }
}

/// Drag-to-set slider for Spotify's volume. Reads the current volume when
/// the Island expands and throttles writes so a drag doesn't queue up one
/// AppleScript call per pointer move.
private struct VolumeSlider: View {
    let spotify: Spotify

    @State private var volume = 0.0
    @State private var pendingWrite: Task<Void, Never>?

    private let trackWidth: CGFloat = 72

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: speakerSymbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 16)

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.2))
                Capsule()
                    .fill(.white)
                    .frame(width: trackWidth * volume)
            }
            .frame(width: trackWidth, height: 3)
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        volume = min(max(drag.location.x / trackWidth, 0), 1)
                        scheduleWrite()
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Volume")
        .accessibilityValue("\(Int(volume * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let step = direction == .increment ? 0.05 : -0.05
            volume = min(max(volume + step, 0), 1)
            scheduleWrite()
        }
        .onAppear {
            if let current = try? spotify.readVolume() {
                volume = Double(current) / 100
            }
        }
    }

    private var speakerSymbol: String {
        switch volume {
        case 0: "speaker.slash.fill"
        case ..<0.34: "speaker.wave.1.fill"
        case ..<0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }

    // Only one write is ever waiting; it sends whatever the volume is when it fires.
    private func scheduleWrite() {
        guard pendingWrite == nil else { return }
        pendingWrite = Task {
            try? await Task.sleep(for: .milliseconds(60))
            spotify.setVolume(Int((volume * 100).rounded()))
            pendingWrite = nil
        }
    }
}

private struct ProgressBar: View {
    let progress: Double
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(accent.opacity(0.2))
                Capsule()
                    .fill(accent)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 3)
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct PinsRow: View {
    let pins: [Pin]
    let loadError: String?
    let play: (String) -> Void
    let editPins: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let loadError {
                Text(loadError)
                    .foregroundStyle(Color(red: 0.604, green: 0.604, blue: 0.635))
                EditPinsButton(action: editPins)
            } else if pins.isEmpty {
                Text("No pins yet.")
                    .foregroundStyle(Color(red: 0.604, green: 0.604, blue: 0.635))
                EditPinsButton(action: editPins)
                Text("in the menu bar")
                    .foregroundStyle(.white.opacity(0.38))
            } else {
                Text("PINS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.66)
                    .foregroundStyle(Color(red: 0.541, green: 0.541, blue: 0.573))
                    .padding(.trailing, 10)

                ForEach(pins.prefix(4)) { pin in
                    PinButton(pin: pin) { play(pin.uri) }
                }
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 20)
    }
}

private struct PinButton: View {
    let pin: Pin
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(pin.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(.white.opacity(isHovering ? 0.24 : 0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct EditPinsButton: View {
    let action: () -> Void

    var body: some View {
        Button("Edit Pins", action: action)
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .overlay(alignment: .bottom) {
                Rectangle().fill(.white.opacity(0.4)).frame(height: 1)
            }
    }
}
