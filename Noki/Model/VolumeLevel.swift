import Foundation

struct VolumeLevel: Equatable {
    private(set) var level: Double
    private(set) var restoreLevel: Double

    init(level: Double, restoreLevel: Double? = nil) {
        self.level = Self.clamp(level)
        self.restoreLevel = Self.clamp(restoreLevel ?? (level > 0 ? level : 0.5))
    }

    mutating func adjust(by amount: Double) {
        level = Self.clamp(level + amount)
        if level > 0 {
            restoreLevel = level
        }
    }

    mutating func toggleMute() {
        if level > 0 {
            restoreLevel = level
            level = 0
        } else {
            level = restoreLevel
        }
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
