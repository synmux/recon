import Foundation
import UniformTypeIdentifiers

enum OutputFormat: String, CaseIterable, Identifiable, Hashable {
    case jpeg
    case webp
    case avif
    case png
    case tiff

    var id: String { rawValue }

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .webp: return .webP
        case .avif: return UTType("public.avif") ?? .image
        case .png: return .png
        case .tiff: return .tiff
        }
    }

    var filenameExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .webp: return "webp"
        case .avif: return "avif"
        case .png: return "png"
        case .tiff: return "tiff"
        }
    }

    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .webp: return "image/webp"
        case .avif: return "image/avif"
        case .png: return "image/png"
        case .tiff: return "image/tiff"
        }
    }

    var supportsQuality: Bool {
        switch self {
        case .jpeg, .webp, .avif: return true
        case .png, .tiff: return false
        }
    }

    var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .webp: return "WebP"
        case .avif: return "AVIF"
        case .png: return "PNG"
        case .tiff: return "TIFF"
        }
    }

    var subtitle: String {
        switch self {
        case .jpeg: return "Universally supported; great for photos"
        case .webp: return "Smaller than JPEG at similar quality"
        case .avif: return "Smallest modern format; slower to encode"
        case .png: return "Lossless, with transparency"
        case .tiff: return "Lossless; archival"
        }
    }

    var badge: String? {
        switch self {
        case .jpeg: return "Most compatible"
        case .webp: return "Smaller"
        case .avif: return "Smallest"
        case .png, .tiff: return nil
        }
    }
}
