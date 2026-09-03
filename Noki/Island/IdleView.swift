import SwiftUI

/// Shown when nothing is playing. Mirrors `PeekView`'s layout so the
/// slots swap cleanly into artwork and visualizer when music starts.
struct IdleView: View {
    private let tint = Color.white.opacity(0.35)

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "moon.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 32)

            Spacer(minLength: 0)

            Visualizer(isPlaying: false, accent: tint)
                .frame(width: 11.5, height: 11)
                .frame(width: 28, height: 32)
        }
        .frame(width: 252, height: 32)
        .accessibilityHidden(true)
    }
}
