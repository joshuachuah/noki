import AppKit
import SwiftUI

@MainActor
final class IslandPanelController {
    private let model: IslandModel
    private let pinStore: PinStore
    private let spotify: Spotify
    private var panel: NSPanel?
    private var screenObserver: NSObjectProtocol?

    private let panelSize = CGSize(width: 550, height: 110)

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
    }

    func stop() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        panel?.close()
        panel = nil
    }

    private func reposition() {
        guard let geometry = NotchGeometry.builtIn() else {
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

