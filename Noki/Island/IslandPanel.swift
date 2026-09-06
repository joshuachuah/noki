import AppKit
import SwiftUI

@MainActor
final class IslandPanelController {
    private let model: IslandModel
    private let pinStore: PinStore
    private let spotify: Spotify
    private var panel: NSPanel?
    private var geometry: NotchGeometry?
    private var screenObserver: NSObjectProtocol?
    private var mouseMonitors: [Any] = []
    private var pointerWasOverNotch = false
    private var pointerWasOverIsland = false
    private var hitRegion: IslandHitRegion?

    // 380 for the Island body plus 6 on each side for the top flares.
    // Keep in sync with the outer frame in `IslandView`.
    private let panelSize = CGSize(width: 392, height: 220)

    init(model: IslandModel, pinStore: PinStore, spotify: Spotify) {
        self.model = model
        self.pinStore = pinStore
        self.spotify = spotify
    }

    func start() {
        reposition()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reposition()
            }
        }

        // Track the raw cursor instead of SwiftUI hover, which misses a cursor that
        // jumps straight into the Notch. Global monitors skip our own panel, so add a local one.
        mouseMonitors = [
            NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
                MainActor.assumeIsolated { self?.pointerMoved() }
            },
            NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
                MainActor.assumeIsolated { self?.pointerMoved() }
                return event
            },
        ].compactMap { $0 }
    }

    func stop() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        mouseMonitors.forEach(NSEvent.removeMonitor)
        mouseMonitors = []
        panel?.close()
        panel = nil
        hitRegion = nil
        pointerWasOverNotch = false
        pointerWasOverIsland = false
    }

    /// Owns expansion and dismissal. SwiftUI only reports the displayed outline.
    private func pointerMoved() {
        guard let geometry, let panel else { return }
        let location = NSEvent.mouseLocation
        let isOverNotch = geometry.containsPointer(location)
        let isOverIsland = containsPointer(location, in: panel)
        defer {
            pointerWasOverNotch = isOverNotch
            pointerWasOverIsland = isOverIsland
        }

        if model.isHovering {
            if isOverNotch || isOverIsland {
                model.pointerEntered()
            } else {
                model.pointerExited()
            }
        } else if (isOverNotch && !pointerWasOverNotch)
            || (model.state == .hidden && isOverIsland && !pointerWasOverIsland) {
            if model.nowPlaying == nil { pinStore.reload() }
            model.pointerEntered()
        }
        updateClickThrough(isOverIsland: isOverIsland)
    }

    private func containsPointer(_ location: CGPoint, in panel: NSPanel) -> Bool {
        // SwiftUI measures down from the top; AppKit measures up from the bottom.
        let point = CGPoint(x: location.x - panel.frame.minX, y: panel.frame.maxY - location.y)
        return hitRegion?.contains(point) == true
    }

    private func updateClickThrough(isOverIsland: Bool) {
        let ignoresMouseEvents = !isOverIsland
        guard let panel, panel.ignoresMouseEvents != ignoresMouseEvents else { return }
        panel.ignoresMouseEvents = ignoresMouseEvents
    }

    /// Re-evaluate even with a stationary cursor when animation or content changes the outline.
    private func hitRegionChanged(_ region: IslandHitRegion) {
        hitRegion = region
        pointerMoved()
    }

    private func reposition() {
        geometry = NotchGeometry.builtIn()
        guard let geometry else {
            panel?.ignoresMouseEvents = true
            panel?.orderOut(nil)
            model.pointerExited()
            pointerWasOverNotch = false
            pointerWasOverIsland = false
            return
        }

        let panel = panel ?? makePanel()
        let origin = CGPoint(
            x: geometry.centerX - panelSize.width / 2,
            y: geometry.screenFrame.maxY - panelSize.height
        )
        panel.setFrame(CGRect(origin: origin, size: panelSize), display: true)
        panel.orderFrontRegardless()
        self.panel = panel
        pointerMoved()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Stay below the fullscreen toolbar's tracking window. Sharing its level
        // can intercept the pointer transition that dismisses the title bar.
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // Starts click-through; only the displayed outline takes mouse events back.
        panel.ignoresMouseEvents = true
        panel.acceptsMouseMovedEvents = true
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(
            rootView: IslandView(
                model: model,
                pinStore: pinStore,
                spotify: spotify,
                onHitRegionChange: { [weak self] region in self?.hitRegionChanged(region) }
            )
        )
        return panel
    }
}
