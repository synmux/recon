import CoreGraphics
import Foundation

enum ReconMode: Hashable {
    case original
    case percentage(Int)
    case longEdge(Int)
    case shortEdge(Int)
}

extension ReconMode {
    /// The max-pixel-size value to pass to `CGImageSourceCreateThumbnailAtIndex`,
    /// or `nil` when no resampling should happen (keep-original, or the target
    /// would upscale the source).
    ///
    /// `CGImageSourceCreateThumbnailAtIndex` applies `kCGImageSourceThumbnailMaxPixelSize`
    /// to the longer of the two output edges, so every mode here reduces to
    /// "what should the longer edge become?".
    static func targetMaxPixelSize(for mode: ReconMode, source: CGSize) -> Int? {
        let longEdge = max(source.width, source.height)
        let shortEdge = min(source.width, source.height)
        guard longEdge > 0, shortEdge > 0 else { return nil }

        switch mode {
        case .original:
            return nil

        case .percentage(let percent):
            guard percent > 0, percent < 100 else { return nil }
            let scaled = Int((longEdge * CGFloat(percent) / 100.0).rounded())
            return scaled > 0 ? scaled : nil

        case .longEdge(let target):
            guard target > 0, CGFloat(target) < longEdge else { return nil }
            return target

        case .shortEdge(let target):
            guard target > 0, CGFloat(target) < shortEdge else { return nil }
            let scale = CGFloat(target) / shortEdge
            let scaledLong = Int((longEdge * scale).rounded())
            return scaledLong > 0 ? scaledLong : nil
        }
    }
}
