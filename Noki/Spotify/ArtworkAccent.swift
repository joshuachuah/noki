import AppKit

enum ArtworkAccent {
    static func extract(from image: NSImage) -> NSColor {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 8,
            pixelsHigh: 8,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return .white }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: CGRect(x: 0, y: 0, width: 8, height: 8))
        NSGraphicsContext.restoreGraphicsState()

        var selected: NSColor?
        var selectedSaturation: CGFloat = 0
        for x in 0..<8 {
            for y in 0..<8 {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
                guard saturation > selectedSaturation, brightness > 0.12 else { continue }
                selectedSaturation = saturation
                selected = NSColor(
                    calibratedHue: hue,
                    saturation: max(saturation, 0.45),
                    brightness: min(max(brightness, 0.42), 0.82),
                    alpha: 1
                )
            }
        }
        return selected ?? .white
    }
}

