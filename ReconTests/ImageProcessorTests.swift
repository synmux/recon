import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Recon

struct ImageProcessorTests {

    enum TestError: Error {
        case contextSetup
        case contextMakeImage
        case readBackFailed
    }

    private func makeTestImage(width: Int = 100, height: Int = 100) throws -> CGImage {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw TestError.contextSetup
        }
        ctx.setFillColor(CGColor(red: 0.31, green: 0.48, blue: 0.05, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.setFillColor(CGColor(red: 0.78, green: 1.0, blue: 0.24, alpha: 1))
        ctx.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        guard let image = ctx.makeImage() else { throw TestError.contextMakeImage }
        return image
    }

    private func tempURL(suffix: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageProcessorTest_\(UUID().uuidString).\(suffix)")
    }

    private func readOrientation(from url: URL) throws -> Int? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            throw TestError.readBackFailed
        }
        if let int = props[kCGImagePropertyOrientation] as? Int { return int }
        if let num = props[kCGImagePropertyOrientation] as? NSNumber { return num.intValue }
        return nil
    }

    @Test("sanitize rewrites any orientation to 1 and preserves other keys")
    func sanitizeRewritesOrientation() {
        let input: [CFString: Any] = [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyPixelWidth: 4000,
            kCGImagePropertyPixelHeight: 3000,
        ]
        let out = ImageProcessor.sanitize(properties: input)
        #expect(out[kCGImagePropertyOrientation] as? Int == 1)
        #expect(out[kCGImagePropertyPixelWidth] as? Int == 4000)
        #expect(out[kCGImagePropertyPixelHeight] as? Int == 3000)
    }

    @Test("sanitize sets orientation even when input has none")
    func sanitizeAddsOrientationWhenMissing() {
        let out = ImageProcessor.sanitize(properties: [:])
        #expect(out[kCGImagePropertyOrientation] as? Int == 1)
    }

    @Test("encode JPEG produces a non-empty, readable file")
    func encodeJpeg() throws {
        let image = try makeTestImage()
        let url = tempURL(suffix: "jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        try ImageProcessor.encode(
            image: image,
            sourceProperties: [:],
            to: url,
            format: .jpeg,
            quality: 0.85
        )
        let data = try Data(contentsOf: url)
        #expect(data.count > 0)
        #expect(CGImageSourceCreateWithData(data as CFData, nil) != nil)
    }

    @Test("Round-trip all formats with an available encoder")
    func roundTripAllFormats() throws {
        let image = try makeTestImage(width: 128, height: 128)
        for format in OutputFormat.allCases {
            do {
                try ImageProcessor.assertEncoderAvailable(format)
            } catch {
                // Simulator may lack specific encoders; skip rather than fail.
                continue
            }
            let url = tempURL(suffix: format.filenameExtension)
            defer { try? FileManager.default.removeItem(at: url) }
            try ImageProcessor.encode(
                image: image,
                sourceProperties: [:],
                to: url,
                format: format,
                quality: 0.85
            )
            let data = try Data(contentsOf: url)
            #expect(data.count > 0, "\(format.displayName) output is empty")
            #expect(
                CGImageSourceCreateWithData(data as CFData, nil) != nil,
                "\(format.displayName) output is unreadable"
            )
        }
    }

    @Test("JPEG quality 0.1 produces a smaller file than 0.9")
    func jpegQualityAffectsFileSize() throws {
        let image = try makeTestImage(width: 400, height: 400)
        let low = tempURL(suffix: "jpg")
        let high = tempURL(suffix: "jpg")
        defer {
            try? FileManager.default.removeItem(at: low)
            try? FileManager.default.removeItem(at: high)
        }
        try ImageProcessor.encode(image: image, sourceProperties: [:], to: low, format: .jpeg, quality: 0.1)
        try ImageProcessor.encode(image: image, sourceProperties: [:], to: high, format: .jpeg, quality: 0.9)
        let lowSize = try FileManager.default.attributesOfItem(atPath: low.path)[.size] as? Int ?? 0
        let highSize = try FileManager.default.attributesOfItem(atPath: high.path)[.size] as? Int ?? 0
        #expect(lowSize > 0)
        #expect(lowSize < highSize)
    }

    @Test("Encoded output metadata has orientation 1 even when source claimed otherwise")
    func outputOrientationAlwaysUp() throws {
        let image = try makeTestImage()
        let url = tempURL(suffix: "jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        // Simulate a source whose EXIF said orientation 6 (needs 90° CCW rotation).
        // sanitize() inside encode() must force this to 1 to avoid double-rotation.
        let sourceProps: [CFString: Any] = [kCGImagePropertyOrientation: 6]
        try ImageProcessor.encode(
            image: image,
            sourceProperties: sourceProps,
            to: url,
            format: .jpeg,
            quality: 0.85
        )
        #expect(try readOrientation(from: url) == 1)
    }
}
