import AppKit

struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    let notchRect: CGRect

    var centerX: CGFloat { notchRect.midX }

    /// Whether a screen-space pointer location is over the Notch. The top edge
    /// is inclusive because the cursor pins to `screenFrame.maxY`, which
    /// `CGRect.contains` would treat as outside.
    func containsPointer(_ location: CGPoint) -> Bool {
        location.x >= notchRect.minX
            && location.x < notchRect.maxX
            && location.y >= notchRect.minY
            && location.y <= screenFrame.maxY
    }

    static func builtIn(from screens: [NSScreen] = NSScreen.screens) -> NotchGeometry? {
        guard let screen = screens.first(where: { $0.safeAreaInsets.top > 0 }) else {
            return nil
        }

        let leftArea = screen.auxiliaryTopLeftArea ?? .zero
        let rightArea = screen.auxiliaryTopRightArea ?? .zero
        let notchHeight = screen.safeAreaInsets.top

        let notchMinX: CGFloat
        let notchMaxX: CGFloat
        if !leftArea.isEmpty, !rightArea.isEmpty {
            notchMinX = leftArea.maxX
            notchMaxX = rightArea.minX
        } else {
            // Older macOS versions may omit the auxiliary areas. A centred
            // 200-point target still gives the real Notch a usable hover area.
            notchMinX = screen.frame.midX - 100
            notchMaxX = screen.frame.midX + 100
        }

        return NotchGeometry(
            screenFrame: screen.frame,
            notchRect: CGRect(
                x: notchMinX,
                y: screen.frame.maxY - notchHeight,
                width: notchMaxX - notchMinX,
                height: notchHeight
            )
        )
    }
}
