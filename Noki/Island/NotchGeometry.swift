import AppKit

/// Where the built-in display's Notch sits in screen coordinates.
struct NotchGeometry: Equatable {
    let screenFrame: CGRect
    let notchRect: CGRect

    var centerX: CGFloat { notchRect.midX }

    /// Whether the pointer is over the Notch. No top bound, since the cursor
    /// pins to the screen edge and `CGRect.contains` would reject it.
    func containsPointer(_ location: CGPoint) -> Bool {
        location.x >= notchRect.minX
            && location.x < notchRect.maxX
            && location.y >= notchRect.minY
    }

    /// Finds the screen with a Notch, or nil if there isn't one.
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
            // Older macOS may omit the auxiliary areas; fall back to a centred 200pt target.
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
