import Photos
import SwiftUI
import UIKit

struct ProcessingView: View {
    @Environment(ResizeSession.self) private var session
    @Environment(ResizeRouter.self) private var router

    @State private var errorMessage: String?
    @State private var started = false

    var body: some View {
        ZStack {
            Color.bg.ignoresSafeArea()
            VStack(spacing: 28) {
                Text("Processing")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(Color.text)
                ProgressRing(progress: session.progress) {
                    VStack(spacing: 4) {
                        Text("\(session.processedCount) of \(session.assets.count)")
                            .font(AppFont.body)
                            .foregroundStyle(Color.textSecondary)
                        Text("\(Int((session.progress * 100).rounded()))%")
                            .font(AppFont.ringPercent)
                            .foregroundStyle(Color.text)
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(Color.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryCTA("Cancel", style: .secondary) {
                cancel()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !started else { return }
            started = true
            await run()
        }
    }

    private func cancel() {
        session.isCancelled = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        if router.path.last == .processing {
            router.path.removeLast()
        }
    }

    private func run() async {
        session.beginProcessing()
        let assets = session.assets
        let format = session.format
        let quality = session.quality
        let resize = session.resize
        let library = PhotoLibrary()

        let addStatus = await PhotoLibrary.requestAddOnlyAccess()
        guard addStatus == .authorized || addStatus == .limited else {
            errorMessage = "Resize needs add-only Photos access to save converted files."
            return
        }

        let album: PHAssetCollection
        do {
            album = try await library.findOrCreateResizeAlbum()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Couldn't create the Resize album."
            return
        }

        let limit = max(1, ProcessInfo.processInfo.activeProcessorCount)
        let total = assets.count
        var nextIndex = 0

        await withTaskGroup(of: (Int, Error?).self) { group in
            while nextIndex < limit && nextIndex < total {
                let idx = nextIndex
                nextIndex += 1
                group.addTask {
                    await Self.processOne(
                        asset: assets[idx],
                        index: idx,
                        format: format,
                        quality: quality,
                        resize: resize,
                        album: album,
                        library: library
                    )
                }
            }

            while let (idx, error) = await group.next() {
                if let error {
                    session.failures.append(ProcessingFailure(
                        asset: assets[idx],
                        message: (error as? LocalizedError)?.errorDescription
                            ?? error.localizedDescription
                    ))
                }
                session.processedCount += 1
                session.progress = Double(session.processedCount) / Double(max(total, 1))

                if session.isCancelled {
                    group.cancelAll()
                    break
                }
                if nextIndex < total {
                    let nextIdx = nextIndex
                    nextIndex += 1
                    group.addTask {
                        await Self.processOne(
                            asset: assets[nextIdx],
                            index: nextIdx,
                            format: format,
                            quality: quality,
                            resize: resize,
                            album: album,
                            library: library
                        )
                    }
                }
            }
        }

        if session.isCancelled {
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        router.path.append(.done)
    }

    nonisolated private static func processOne(
        asset: PHAsset,
        index: Int,
        format: OutputFormat,
        quality: Double,
        resize: ResizeMode,
        album: PHAssetCollection,
        library: PhotoLibrary
    ) async -> (Int, Error?) {
        do {
            let url = try await ImageProcessor.process(
                asset: asset,
                format: format,
                quality: quality,
                resize: resize
            )
            try await library.append(fileURL: url, to: album)
            return (index, nil)
        } catch {
            return (index, error)
        }
    }
}
