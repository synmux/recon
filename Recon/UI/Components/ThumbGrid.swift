import Photos
import SwiftUI

struct ThumbGrid: View {
    let assets: [PHAsset]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                ThumbCell(asset: asset)
                    .accessibilityLabel("Photo \(index + 1) of \(assets.count)")
            }
        }
    }
}

private struct ThumbCell: View {
    let asset: PHAsset
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.surfaceAlt
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .task(id: asset.localIdentifier) {
                await stream(targetWidth: geo.size.width, scale: displayScale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func stream(targetWidth: CGFloat, scale: CGFloat) async {
        let target = CGSize(width: targetWidth * scale, height: targetWidth * scale)

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        let stream = AsyncStream<UIImage>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let id = PHImageManager.default().requestImage(
                for: asset,
                targetSize: target,
                contentMode: .aspectFill,
                options: options
            ) { img, info in
                if let img { continuation.yield(img) }
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !degraded { continuation.finish() }
            }
            continuation.onTermination = { _ in
                PHImageManager.default().cancelImageRequest(id)
            }
        }

        for await newImage in stream {
            image = newImage
        }
    }
}
