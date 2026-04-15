import SwiftUI
import UIKit

struct DoneView: View {
    @Environment(ReconSession.self) private var session
    @Environment(ReconRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(Color.accentSoft).frame(width: 96, height: 96)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.accent)
                }
                .accessibilityHidden(true)

                Text(summaryTitle)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.center)

                Text(summaryDetail)
                    .font(AppFont.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            Spacer()
            ctaStack
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(Color.bg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var ctaStack: some View {
        VStack(spacing: 12) {
            if !session.failures.isEmpty {
                PrimaryCTA("Retry failed (\(session.failures.count))", style: .secondary) {
                    retryFailed()
                }
            }
            PrimaryCTA("Open Photos") { openPhotos() }
            PrimaryCTA("Recon More", style: .secondary) { reconMore() }
        }
    }

    private var savedCount: Int {
        max(0, session.processedCount - session.failures.count)
    }

    private var summaryTitle: String {
        if savedCount == 0 {
            return "Nothing was saved."
        }
        return "\(savedCount) \(savedCount == 1 ? "photo" : "photos") saved to Recon."
    }

    private var summaryDetail: String {
        if session.failures.isEmpty {
            return "Find them in Photos under the \"Recon\" album."
        }
        let n = session.failures.count
        return "\(n) \(n == 1 ? "file" : "files") failed. You can retry just those."
    }

    private func openPhotos() {
        guard let url = URL(string: "photos-redirect://") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func reconMore() {
        session.reset()
        router.path.removeAll()
    }

    private func retryFailed() {
        let failedAssets = session.failures.map(\.asset)
        session.assets = failedAssets
        session.failures.removeAll()
        if router.path.last == .done {
            router.path.removeLast()
        }
        router.path.append(.processing)
    }
}
