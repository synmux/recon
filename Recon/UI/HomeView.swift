import Photos
import PhotosUI
import SwiftUI

struct HomeView: View {
    @Environment(ReconSession.self) private var session
    @Environment(ReconRouter.self) private var router

    @State private var showingPicker = false
    @State private var readAccessDenied = false

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    heroCard
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                PrimaryCTA("Choose Photos") {
                    Task { await presentPicker() }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationDestination(for: Step.self) { step in
                destinationView(for: step)
            }
            .sheet(isPresented: $showingPicker) {
                PhotoPicker { results in
                    showingPicker = false
                    Task { await handlePicked(results) }
                }
                .ignoresSafeArea()
            }
            .alert("Photos access denied", isPresented: $readAccessDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Open Settings to allow Recon to read your photo library.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recon")
                .font(AppFont.display)
                .foregroundStyle(Color.text)
            Text("Convert and recon photos in a tap.")
                .font(AppFont.body)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24).fill(Color.surface)
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    Color.border,
                    style: StrokeStyle(lineWidth: 2, dash: [6, 6])
                )
                .padding(11)
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.accentSoft).frame(width: 80, height: 80)
                    Image(systemName: "plus")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                VStack(spacing: 8) {
                    Text("Select images")
                        .font(AppFont.listTitle)
                        .foregroundStyle(Color.text)
                    Text("Choose one or more photos from your library to convert and recon.")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                Text("Processed images are saved to Photos in a \"Recon\" album.")
                    .font(AppFont.caption)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 313)
                    .padding(.top, 4)
            }
            .padding(32)
        }
        .frame(height: 360)
    }

    private func presentPicker() async {
        let status = await PhotoLibrary.requestReadAccess()
        switch status {
        case .authorized, .limited:
            showingPicker = true
        default:
            readAccessDenied = true
        }
    }

    private func handlePicked(_ results: [PHPickerResult]) async {
        let assets = AssetLoader.resolveAssets(from: results)
        guard !assets.isEmpty else { return }
        session.reset()
        session.assets = assets
        UISelectionFeedbackGenerator().selectionChanged()
        router.path = [.selected]
    }

    @ViewBuilder
    private func destinationView(for step: Step) -> some View {
        switch step {
        case .selected: SelectedView()
        case .format: FormatView()
        case .quality: QualityView()
        case .options: ReconOptionsView()
        case .processing: ProcessingView()
        case .done: DoneView()
        }
    }
}

#Preview {
    HomeView()
        .environment(ReconSession())
        .environment(ReconRouter())
}
