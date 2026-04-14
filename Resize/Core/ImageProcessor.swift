import CoreGraphics
import Foundation
import ImageIO
import Photos
import UniformTypeIdentifiers

struct ImageProcessor {

    enum ProcessingError: LocalizedError {
        case sourceLoadFailed(underlying: Error?)
        case decodeFailed
        case encodeUnavailable(OutputFormat)
        case encodeFailed

        var errorDescription: String? {
            switch self {
            case .sourceLoadFailed(let error):
                if let error {
                    return "Couldn't read the photo: \(error.localizedDescription)"
                }
                return "Couldn't read the photo."
            case .decodeFailed:
                return "Couldn't decode the photo."
            case .encodeUnavailable(let format):
                return "This device can't save \(format.displayName)."
            case .encodeFailed:
                return "Couldn't save the output."
            }
        }
    }

    /// End-to-end: load asset bytes, decode + optionally resize, re-encode, return the
    /// temp URL of the resulting file. `nonisolated` so callers in `TaskGroup`s can
    /// run it off-main without hopping to the MainActor.
    nonisolated static func process(
        asset: PHAsset,
        format: OutputFormat,
        quality: Double,
        resize: ResizeMode
    ) async throws -> URL {
        try assertEncoderAvailable(format)

        let data = try await loadAssetData(asset)
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ProcessingError.decodeFailed
        }

        let sourceSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let (image, sourceProperties) = try decode(
            source: source,
            resize: resize,
            sourceSize: sourceSize
        )

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).\(format.filenameExtension)")
        try encode(
            image: image,
            sourceProperties: sourceProperties,
            to: url,
            format: format,
            quality: quality
        )
        return url
    }

    /// Raises `.encodeUnavailable` if the current device cannot encode `format`.
    /// Cheap: consults the ImageIO-registered encoder list, cached by the OS.
    nonisolated static func assertEncoderAvailable(_ format: OutputFormat) throws {
        let supported = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        if !supported.contains(format.utType.identifier) {
            throw ProcessingError.encodeUnavailable(format)
        }
    }

    /// Decodes the image at index 0 of `source`, applying EXIF orientation to the
    /// pixels, and optionally downsizing so its longest edge is at most
    /// `ResizeMode.targetMaxPixelSize(for:source:)`. For `.original` the thumbnail
    /// API is still used (with a generous max) to guarantee the orientation bake.
    nonisolated static func decode(
        source: CGImageSource,
        resize: ResizeMode,
        sourceSize: CGSize
    ) throws -> (image: CGImage, properties: [CFString: Any]) {
        let originalProperties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]
        let longEdge = max(sourceSize.width, sourceSize.height)
        let fallbackCap = max(1, Int(longEdge.rounded()))
        let maxPx = ResizeMode.targetMaxPixelSize(for: resize, source: sourceSize) ?? fallbackCap

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPx,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ProcessingError.decodeFailed
        }
        return (image, originalProperties)
    }

    /// Writes `image` to `url` in `format`. Source properties (EXIF/GPS/etc.) are
    /// preserved except orientation, which is forced to `.up` because the pixel
    /// buffer is already oriented after `decode(...)` and leaving the old
    /// orientation tag would cause viewers to rotate a second time.
    nonisolated static func encode(
        image: CGImage,
        sourceProperties: [CFString: Any],
        to url: URL,
        format: OutputFormat,
        quality: Double
    ) throws {
        var props = sanitize(properties: sourceProperties)
        if format.supportsQuality {
            props[kCGImageDestinationLossyCompressionQuality] = max(0.0, min(1.0, quality))
        }
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessingError.encodeFailed
        }
        CGImageDestinationAddImage(destination, image, props as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.encodeFailed
        }
    }

    /// Normalises a properties dict for re-encoding. The pixel buffer is already
    /// in display orientation after `decode(...)`, so the output metadata must
    /// claim orientation = 1 — otherwise viewers double-rotate.
    nonisolated static func sanitize(properties: [CFString: Any]) -> [CFString: Any] {
        var out = properties
        out[kCGImagePropertyOrientation] = 1
        return out
    }

    // MARK: - Private

    private nonisolated static func loadAssetData(_ asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .current
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: ProcessingError.sourceLoadFailed(underlying: error))
                    return
                }
                guard let data else {
                    continuation.resume(throwing: ProcessingError.sourceLoadFailed(underlying: nil))
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }
}
