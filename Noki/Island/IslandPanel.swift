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
    }

    /// Opens the Island when the cursor enters the Notch.
    private func pointerMoved() {
        guard let geometry else { return }
        let location = NSEvent.mouseLocation
        let isOverNotch = geometry.containsPointer(location)
        defer { pointerWasOverNotch = isOverNotch }

        if isOverNotch, !pointerWasOverNotch {
            if model.nowPlaying == nil { pinStore.reload() }
            model.pointerEntered()
        }
        updateClickThrough(at: location)
    }

    /// The panel is bigger than the visible Island, so only take mouse events
    /// while the pointer is over the Island's current shape.
    private func updateClickThrough(at location: CGPoint) {
        guard let geometry, let panel else { return }
        let size = model.state.size(hasNowPlaying: model.nowPlaying != nil)
        let minX = geometry.centerX - size.width / 2
        // Top edge is open-ended for the same reason as `containsPointer`.
        let isOverIsland = location.x >= minX
            && location.x < minX + size.width
            && location.y >= geometry.screenFrame.maxY - size.height
        panel.ignoresMouseEvents = !isOverIsland

        // SwiftUI hover exit can't fire once the panel ignores events, so close from here.
        if pointerWasOverIsland, !isOverIsland { model.pointerExited() }
        pointerWasOverIsland = isOverIsland
    }

    private func reposition() {
        geometry = NotchGeometry.builtIn()
        guard let geometry else {
            panel?.orderOut(nil)
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
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        // Starts click-through; `updateClickThrough` takes events back over the Island.
        panel.ignoresMouseEvents = true
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(
            rootView: IslandView(model: model, pinStore: pinStore, spotify: spotify)
        )
        return panel
    }
}
