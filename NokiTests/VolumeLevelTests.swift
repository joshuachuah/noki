import Testing
@testable import Noki

struct VolumeLevelTests {
    @Test func clampsAdjustmentsAtBothEnds() {
        var volume = VolumeLevel(level: 0.5)

        volume.adjust(by: 1)
        #expect(volume.level == 1)

        volume.adjust(by: -2)
        #expect(volume.level == 0)
    }

    @Test func muteRestoresTheExactPreviousLevel() {
        var volume = VolumeLevel(level: 0.37)

        volume.toggleMute()
        #expect(volume.level == 0)

        volume.toggleMute()
        #expect(volume.level == 0.37)
    }

    @Test func adjustingWhileMutedUnmutes() {
        var volume = VolumeLevel(level: 0.6)
        volume.toggleMute()

        volume.adjust(by: 0.05)

        #expect(volume.level == 0.05)
        #expect(volume.restoreLevel == 0.05)
    }
}
