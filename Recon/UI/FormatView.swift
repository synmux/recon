import SwiftUI

struct FormatView: View {
    @Environment(ReconSession.self) private var session
    @Environment(ReconRouter.self) private var router

    var body: some View {
        @Bindable var session = session

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                StepDots(current: 2, total: 4)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Format")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(Color.text)
                    Text("Pick the file type for your converted copies.")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                }
                VStack(spacing: 12) {
                    ForEach(OutputFormat.allCases) { format in
                        OptionRow(
                            title: format.displayName,
                            subtitle: format.subtitle,
                            badge: format.badge,
                            isSelected: session.format == format
                        ) {
                            UISelectionFeedbackGenerator().selectionChanged()
                            session.format = format
                        }
                    }
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
                router.path.append(session.showsQualityStep ? .quality : .options)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
