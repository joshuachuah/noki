import AppKit
import SwiftUI
import Testing
@testable import Noki

struct IslandHitRegionTests {
    @Test func roundedCornersAndFlaresMatchTheVisibleOutline() {
        let region = IslandHitRegion(
            frame: CGRect(x: 6, y: 0, width: 380, height: 220),
            cornerRadius: 28
        )

        #expect(region.contains(CGPoint(x: 196, y: 100)))
        #expect(region.contains(CGPoint(x: 5, y: 1)))
        #expect(!region.contains(CGPoint(x: 7, y: 219)))
        #expect(!region.contains(CGPoint(x: 196, y: 221)))
    }

    /// Exercise SwiftUI's actual animation reporting without moving the user's pointer.
    @Test @MainActor func animationReportsIntermediateBoundsAndFinalCollapsedBounds() async throws {
        let model = IslandModel()
        var regions: [IslandHitRegion] = []
        let view = IslandView(
            model: model,
            pinStore: PinStore(),
            spotify: Spotify(),
            onHitRegionChange: { regions.append($0) }
        )
        let panel = NSPanel(
            contentRect: CGRect(x: -10000, y: -10000, width: 392, height: 220),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFront(nil)
        defer { panel.close() }

        try await Task.sleep(for: .milliseconds(200))
        #expect(try #require(regions.last).frame.height == 32)

        regions.removeAll()
        model.pointerEntered()
        try await Task.sleep(for: .seconds(1))
        #expect(regions.contains { $0.frame.height > 32 && $0.frame.height < 100 })
        #expect(abs(try #require(regions.last).frame.height - 100) < 0.5)

        regions.removeAll()
        model.pointerExited()
        try await Task.sleep(for: .seconds(1))
        #expect(regions.contains { $0.frame.height > 32 && $0.frame.height < 100 })
        let collapsed = try #require(regions.last)
        #expect(abs(collapsed.frame.height - 32) < 0.5)
        #expect(!collapsed.contains(CGPoint(x: 196, y: 80)))
    }
}
