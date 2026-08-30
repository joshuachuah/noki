import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class PinStore {
    private(set) var pins: [Pin] = []
    private(set) var loadError: String?

    private let fileManager: FileManager
    let fileURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = support.appending(path: "Noki/pins.json")
    }

    func reload() {
        do {
            try ensureFileExists()
            let data = try Data(contentsOf: fileURL)
            let source = String(decoding: data, as: UTF8.self)
            let json = source
                .split(separator: "\n", omittingEmptySubsequences: false)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            pins = try JSONDecoder().decode([Pin].self, from: Data(json.utf8))
            loadError = nil
        } catch {
            pins = []
            loadError = "pins.json could not be read"
        }
    }

    func openInDefaultEditor() {
        do {
            try ensureFileExists()
            NSWorkspace.shared.open(fileURL)
        } catch {
            NSSound.beep()
        }
    }

    private func ensureFileExists() throws {
        guard !fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let template = """
        [
          // { "name": "Focus", "uri": "spotify:playlist:37i9dQZF1DX8NTLI2TtZa6" }
        ]
        """
        try Data(template.utf8).write(to: fileURL, options: .atomic)
    }
}

