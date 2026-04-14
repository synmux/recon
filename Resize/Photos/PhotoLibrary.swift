import Foundation
import Photos

struct PhotoLibrary {

    static let albumName = "Resize"

    enum LibraryError: LocalizedError {
        case albumLookupFailed
        case accessDenied(PHAccessLevel)

        var errorDescription: String? {
            switch self {
            case .albumLookupFailed:
                return "Couldn't find the Resize album after creating it."
            case .accessDenied(let level):
                let kind = level == .addOnly ? "add" : "read-write"
                return "Photos access (\(kind)) was denied."
            }
        }
    }

    /// Prompt-once read-write access; needed to resolve picker identifiers to PHAssets.
    static func requestReadAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    /// Prompt-once add-only access; needed to write outputs to the Resize album.
    static func requestAddOnlyAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }

    /// Returns the existing "Resize" user album, or creates it and returns the new one.
    func findOrCreateResizeAlbum() async throws -> PHAssetCollection {
        if let existing = fetchResizeAlbum() {
            return existing
        }

        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
            placeholder = request.placeholderForCreatedAssetCollection
        }

        guard let localID = placeholder?.localIdentifier,
              let created = PHAssetCollection
                .fetchAssetCollections(withLocalIdentifiers: [localID], options: nil)
                .firstObject
        else {
            throw LibraryError.albumLookupFailed
        }
        return created
    }

    /// Writes the file at `fileURL` to Photos as a new asset and appends it to
    /// `album`. Uses `shouldMoveFile = true` so the temp file is consumed in place.
    /// The whole operation is one atomic `performChanges` transaction.
    func append(fileURL: URL, to album: PHAssetCollection) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            let resourceOptions = PHAssetResourceCreationOptions()
            resourceOptions.shouldMoveFile = true
            creationRequest.addResource(with: .photo, fileURL: fileURL, options: resourceOptions)

            if let placeholder = creationRequest.placeholderForCreatedAsset,
               let albumRequest = PHAssetCollectionChangeRequest(for: album) {
                albumRequest.addAssets([placeholder] as NSFastEnumeration)
            }
        }
    }

    // MARK: - Private

    private func fetchResizeAlbum() -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", Self.albumName)
        return PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: options
        ).firstObject
    }
}
