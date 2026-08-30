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

        // Opening the Island is driven by the raw cursor position rather than
        // SwiftUI's `onHover`. Hover relies on tracking-area transitions, which
        // can miss a cursor that jumps into the Notch in one event and stops
        // against the screen edge. Global monitors only see events bound for
        // other apps, so a local one covers the cursor over our own panel.
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

    /// Opens the Island on the transition into the Notch. Leaving is left to
    /// `IslandView`'s hover, which knows the Island's current shape.
    private func pointerMoved() {
        guard let geometry else { return }
        let isOverNotch = geometry.containsPointer(NSEvent.mouseLocation)
        defer { pointerWasOverNotch = isOverNotch }
        guard isOverNotch, !pointerWasOverNotch else { return }

        if model.nowPlaying == nil { pinStore.reload() }
        model.pointerEntered()
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
        panel.ignoresMouseEvents = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(
            rootView: IslandView(model: model, pinStore: pinStore, spotify: spotify)
        )
        return panel
    }
}
