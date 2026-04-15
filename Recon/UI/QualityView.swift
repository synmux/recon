import SwiftUI

struct QualityView: View {
    @Environment(ReconSession.self) private var session
    @Environment(ReconRouter.self) private var router

    var body: some View {
        @Bindable var session = session

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                StepDots(current: 3, total: 4)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quality")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(Color.text)
                    Text("Balance file size against image fidelity.")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                }
                valueDisplay
                    .padding(.top, 12)
                QualitySlider(value: $session.quality)
                    .padding(.vertical, 16)
                HStack {
                    Text("Smaller")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("Sharper")
                        .font(AppFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryCTA("Continue") {
                UISelectionFeedbackGenerator().selectionChanged()
                router.path.append(.options)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var valueDisplay: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(String(format: "%.2f", session.quality))
                .font(AppFont.valueDisplay)
                .foregroundStyle(Color.text)
            Text("quality")
                .font(AppFont.body)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
