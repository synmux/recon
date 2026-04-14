import Foundation
import Observation
import Photos

struct ProcessingFailure: Identifiable {
    let id = UUID()
    let asset: PHAsset
    let message: String
}

@Observable
final class ResizeSession {
    var assets: [PHAsset] = []
    var format: OutputFormat = .jpeg
    var quality: Double = 0.85
    var resize: ResizeMode = .percentage(75)
    var progress: Double = 0
    var processedCount: Int = 0
    var isCancelled: Bool = false
    var failures: [ProcessingFailure] = []

    var showsQualityStep: Bool { format.supportsQuality }

    func reset() {
        assets = []
        format = .jpeg
        quality = 0.85
        resize = .percentage(75)
        progress = 0
        processedCount = 0
        isCancelled = false
        failures = []
    }

    func beginProcessing() {
        progress = 0
        processedCount = 0
        isCancelled = false
        failures = []
    }
}
