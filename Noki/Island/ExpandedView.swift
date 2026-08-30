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
    }
}

/// Stacks track details, labelled progress, and five controls below the notch.
private struct NowPlayingRow: View {
    let nowPlaying: NowPlaying
    let spotify: Spotify

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    Button {
                        spotify.openTrack(id: nowPlaying.id)
                    } label: {
                        ArtworkView(image: nowPlaying.artwork, cornerRadius: 12)
                            .frame(width: 60, height: 60)
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

                    Visualizer(
                        isPlaying: nowPlaying.isPlaying,
                        accent: Color(nsColor: nowPlaying.accent),
                        style: .expanded
                    )
                    .frame(width: 25, height: 18)
                    .padding(.trailing, 4)
                }

                HStack(spacing: 12) {
                    TimeLabel(nowPlaying.elapsedLabel(at: timeline.date))
                    ProgressBar(
                        progress: nowPlaying.progress(at: timeline.date),
                        accent: Color(nsColor: nowPlaying.accent)
                    )
                    TimeLabel(nowPlaying.remainingLabel(at: timeline.date))
                }
                .frame(height: 20)

                HStack(spacing: 0) {
                    VolumeSlot(spotify: spotify)
                    Spacer()
                    SlotButton(symbol: "backward.fill", label: "Previous", action: spotify.previous)
                    Spacer()
                    SlotButton(
                        symbol: nowPlaying.isPlaying ? "pause.fill" : "play.fill",
                        label: nowPlaying.isPlaying ? "Pause" : "Play",
                        action: spotify.playPause
                    )
                    Spacer()
                    SlotButton(symbol: "forward.fill", label: "Next", action: spotify.next)
                    Spacer()
                    ShuffleSlot(accent: Color(nsColor: nowPlaying.accent), spotify: spotify)
                }
                .frame(height: 44)
            }
            .padding(.top, 48)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(width: 380, height: 220)
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
                .font(.system(size: 14))
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

private struct SlotButton: View {
    let symbol: String
    let label: String
    var tint: Color = .white.opacity(0.85)
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: symbol == "play.fill" || symbol == "pause.fill" ? 24 : 20, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(.white.opacity(isHovering ? 0.12 : 0), in: RoundedRectangle(cornerRadius: 12))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .help(label)
        .onHover { isHovering = $0 }
    }
}

private struct VolumeSlot: View {
    let spotify: Spotify

    @State private var volume = VolumeLevel(level: 0.5)
    @State private var scrollRemainder: CGFloat = 0
    @State private var pendingWrite: Task<Void, Never>?

    var body: some View {
        SlotButton(
            symbol: speakerSymbol,
            label: volume.level == 0 ? "Unmute" : "Mute",
            action: toggleMute
        )
        .background {
            ScrollWheelCatcher(onScroll: handleScroll)
        }
        .accessibilityValue("\(Int(volume.level * 100)) percent")
        .accessibilityAdjustableAction { direction in
            volume.adjust(by: direction == .increment ? 0.05 : -0.05)
            scheduleWrite()
        }
        .onAppear {
            if let current = try? spotify.readVolume() {
                volume = VolumeLevel(level: Double(current) / 100)
            }
        }
    }

    private var speakerSymbol: String {
        switch volume.level {
        case 0: "speaker.slash.fill"
        case ..<0.34: "speaker.wave.1.fill"
        case ..<0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }

    private func handleScroll(_ delta: CGFloat) {
        scrollRemainder += delta
        var didAdjust = false

        while abs(scrollRemainder) >= 10 {
            let step = scrollRemainder > 0 ? 0.05 : -0.05
            volume.adjust(by: step)
            scrollRemainder += scrollRemainder > 0 ? -10 : 10
            didAdjust = true
        }

        if didAdjust {
            scheduleWrite()
        }
    }

    private func toggleMute() {
        volume.toggleMute()
        scheduleWrite()
    }

    /// Coalesces a trackpad gesture into at most one Spotify write every 60ms.
    private func scheduleWrite() {
        guard pendingWrite == nil else { return }
        pendingWrite = Task {
            try? await Task.sleep(for: .milliseconds(60))
            spotify.setVolume(Int((volume.level * 100).rounded()))
            pendingWrite = nil
        }
    }
}

private struct ShuffleSlot: View {
    let accent: Color
    let spotify: Spotify

    @State private var isShuffling = false

    var body: some View {
        SlotButton(
            symbol: "shuffle",
            label: isShuffling ? "Turn shuffle off" : "Turn shuffle on",
            tint: isShuffling ? accent : .white.opacity(0.85)
        ) {
            isShuffling.toggle()
            spotify.setShuffling(isShuffling)
        }
        .onAppear {
            if let current = try? spotify.readShuffling() {
                isShuffling = current
            }
        }
    }
}

private struct TimeLabel: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .font(.system(size: 13, weight: .medium))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.7))
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
        .frame(height: 6)
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
        .frame(width: 380, height: 100, alignment: .top)
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
