import AppKit
import Testing
@testable import Noki

struct NotchGeometryTests {
    private let geometry = NotchGeometry(
        screenFrame: CGRect(x: 0, y: 0, width: 1_440, height: 900),
        notchRect: CGRect(x: 620, y: 868, width: 200, height: 32)
    )

    @Test func includesTheCursorAtTheScreenTopEdge() {
        #expect(geometry.containsPointer(CGPoint(x: 720, y: 900)))
    }

    @Test func excludesPointsOutsideThePhysicalNotch() {
        #expect(!geometry.containsPointer(CGPoint(x: 720, y: 901)))
        #expect(!geometry.containsPointer(CGPoint(x: 619, y: 884)))
        #expect(!geometry.containsPointer(CGPoint(x: 820, y: 884)))
        #expect(!geometry.containsPointer(CGPoint(x: 720, y: 867)))
    }
}
