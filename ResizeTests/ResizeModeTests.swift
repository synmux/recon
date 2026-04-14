import CoreGraphics
import Testing
@testable import Resize

struct ResizeModeTests {

    @Test("Keep-original returns nil regardless of source size")
    func keepOriginal() {
        #expect(ResizeMode.targetMaxPixelSize(for: .original, source: CGSize(width: 4000, height: 3000)) == nil)
        #expect(ResizeMode.targetMaxPixelSize(for: .original, source: CGSize(width: 10, height: 10)) == nil)
    }

    @Test("Zero or negative source returns nil")
    func invalidSource() {
        #expect(ResizeMode.targetMaxPixelSize(for: .percentage(50), source: CGSize(width: 0, height: 100)) == nil)
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(100), source: CGSize(width: 100, height: 0)) == nil)
    }

    @Test("Percentage 50 of 4000x3000 is 2000 on long edge")
    func percentageHalfLandscape() {
        #expect(ResizeMode.targetMaxPixelSize(for: .percentage(50), source: CGSize(width: 4000, height: 3000)) == 2000)
    }

    @Test("Percentage 75 of 4000x3000 is 3000 on long edge")
    func percentageThreeQuarters() {
        #expect(ResizeMode.targetMaxPixelSize(for: .percentage(75), source: CGSize(width: 4000, height: 3000)) == 3000)
    }

    @Test("Percentage 100 is treated as no resize")
    func percentageFull() {
        #expect(ResizeMode.targetMaxPixelSize(for: .percentage(100), source: CGSize(width: 4000, height: 3000)) == nil)
    }

    @Test("Percentage zero is no-op")
    func percentageZero() {
        #expect(ResizeMode.targetMaxPixelSize(for: .percentage(0), source: CGSize(width: 4000, height: 3000)) == nil)
    }

    @Test("longEdge above source long edge does not upscale")
    func longEdgeAboveSourceIsNil() {
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(3000), source: CGSize(width: 1000, height: 800)) == nil)
    }

    @Test("longEdge equal to source long edge is no-op (no resample needed)")
    func longEdgeEqualSourceIsNil() {
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(4000), source: CGSize(width: 4000, height: 3000)) == nil)
    }

    @Test("longEdge below source long edge returns that target")
    func longEdgeBelowSourceReturnsTarget() {
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(2000), source: CGSize(width: 4000, height: 3000)) == 2000)
    }

    @Test("Portrait source: longEdge is the height dimension")
    func longEdgePortrait() {
        // source 800x1200 -> longEdge is 1200; target 1500 would upscale -> nil
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(1500), source: CGSize(width: 800, height: 1200)) == nil)
        // target 600 < 1200 -> 600
        #expect(ResizeMode.targetMaxPixelSize(for: .longEdge(600), source: CGSize(width: 800, height: 1200)) == 600)
    }

    @Test("shortEdge above source short edge does not upscale")
    func shortEdgeAboveSourceIsNil() {
        #expect(ResizeMode.targetMaxPixelSize(for: .shortEdge(1200), source: CGSize(width: 1000, height: 800)) == nil)
    }

    @Test("shortEdge 1200 on 4000x3000 scales long edge to 1600")
    func shortEdgeLandscape() {
        // shortEdge 3000 -> 1200, scale = 0.4, long 4000 -> 1600
        #expect(ResizeMode.targetMaxPixelSize(for: .shortEdge(1200), source: CGSize(width: 4000, height: 3000)) == 1600)
    }

    @Test("shortEdge 800 on 1200x1800 portrait gives long 1200")
    func shortEdgePortrait() {
        // shortEdge 1200 -> 800, scale = 2/3, long 1800 * 2/3 = 1200
        #expect(ResizeMode.targetMaxPixelSize(for: .shortEdge(800), source: CGSize(width: 1200, height: 1800)) == 1200)
    }
}
