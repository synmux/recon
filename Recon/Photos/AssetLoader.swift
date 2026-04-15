import Photos
import PhotosUI

enum AssetLoader {

    /// Resolves `PHPickerResult`s to the underlying `PHAsset`s, preserving the order
    /// the user picked them in. `PHAsset.fetchAssets(withLocalIdentifiers:)` returns
    /// results in an unspecified order, so we project back through the original
    /// identifier array.
    static func resolveAssets(from results: [PHPickerResult]) -> [PHAsset] {
        let identifiers = results.compactMap(\.assetIdentifier)
        guard !identifiers.isEmpty else { return [] }

        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var byIdentifier: [String: PHAsset] = [:]
        fetch.enumerateObjects { asset, _, _ in
            byIdentifier[asset.localIdentifier] = asset
        }
        return identifiers.compactMap { byIdentifier[$0] }
    }
}
