import AppKit
import ServiceManagement
import SwiftUI

@main
struct NokiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            Button("Edit Pins") {
                appDelegate.pinStore.openInDefaultEditor()
            }

            Button {
                appDelegate.launchAtLogin.toggle()
            } label: {
                Label(
                    "Launch at Login",
                    systemImage: appDelegate.launchAtLogin.isEnabled ? "checkmark" : ""
                )
            }

            Divider()

            Button("Quit Noki") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "music.note")
                .accessibilityLabel("Noki")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = IslandModel()
    let pinStore = PinStore()
    let spotify = Spotify()
    let launchAtLogin = LaunchAtLoginController()

    private var panelController: IslandPanelController?
    private var spotifyObserver: SpotifyObserver?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Skip startup under XCTest so tests never touch the Notch or Spotify.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return
        }

        panelController = IslandPanelController(
            model: model,
            pinStore: pinStore,
            spotify: spotify
        )
        panelController?.start()

        spotifyObserver = SpotifyObserver(model: model, spotify: spotify)
        spotifyObserver?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        spotifyObserver?.stop()
        panelController?.stop()
    }
}

@MainActor
@Observable
final class LaunchAtLoginController {
    private(set) var isEnabled = SMAppService.mainApp.status == .enabled

    func toggle() {
        do {
            if isEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSSound.beep()
        }

        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
