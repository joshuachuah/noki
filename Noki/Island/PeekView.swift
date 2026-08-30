import SwiftUI

struct PeekView: View {
    let nowPlaying: NowPlaying
    let spotify: Spotify

    @State private var isHoveringPlayback = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                spotify.openTrack(id: nowPlaying.id)
            } label: {
                ArtworkView(image: nowPlaying.artwork, cornerRadius: 4)
                    .frame(width: 16, height: 16)
                    .frame(width: 30, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(nowPlaying.title) in Spotify")
            .help("Open song in Spotify")

            Spacer(minLength: 0)

            Button(action: spotify.playPause) {
                Group {
                    if isHoveringPlayback {
                        Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    } else {
                        Visualizer(
                            isPlaying: nowPlaying.isPlaying,
                            accent: Color(nsColor: nowPlaying.accent)
                        )
                        .frame(width: 11.5, height: 11)
                    }
                }
                .frame(width: 28, height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(nowPlaying.isPlaying ? "Pause" : "Play")
            .help(nowPlaying.isPlaying ? "Pause" : "Play")
            .onHover { isHoveringPlayback = $0 }
            .animation(.easeOut(duration: 0.1), value: isHoveringPlayback)
        }
        .frame(width: 252, height: 32)
    }
}

struct ArtworkView: View {
    let image: NSImage?
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color.white.opacity(0.12)
                    Image(systemName: "music.note")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
