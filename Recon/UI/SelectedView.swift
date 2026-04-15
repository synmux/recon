import SwiftUI

struct SelectedView: View {
    @Environment(ReconSession.self) private var session
    @Environment(ReconRouter.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                StepDots(current: 1, total: 4)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(Color.text)
                    Text("Review your selection, then continue.")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                }
                ThumbGrid(assets: session.assets)
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryCTA("Continue", isEnabled: !session.assets.isEmpty) {
                UISelectionFeedbackGenerator().selectionChanged()
                router.path.append(.format)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        let count = session.assets.count
        return "\(count) \(count == 1 ? "photo" : "photos") selected"
    }
}
