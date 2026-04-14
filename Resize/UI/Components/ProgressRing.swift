import SwiftUI

struct ProgressRing<Center: View>: View {
    let progress: Double
    @ViewBuilder let center: () -> Center

    @ScaledMetric(relativeTo: .largeTitle) private var ringSize: CGFloat = 220
    private let strokeWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.border, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    Color.accent,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.25), value: progress)
            center()
        }
        .frame(width: ringSize, height: ringSize)
    }
}

#Preview {
    ProgressRing(progress: 0.67) {
        VStack {
            Text("3 of 5").font(AppFont.body).foregroundStyle(Color.textSecondary)
            Text("67%").font(AppFont.ringPercent).foregroundStyle(Color.text)
        }
    }
    .padding()
    .background(Color.bg)
}
