import SwiftUI

struct StepDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                let step = index + 1
                let isActive = step == current
                let isCompleted = step < current
                Capsule()
                    .fill(isActive || isCompleted ? Color.accent : Color.border)
                    .frame(width: isActive ? 22 : 6, height: 6)
                    .animation(.snappy(duration: 0.2), value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(total)")
    }
}

#Preview {
    VStack(spacing: 20) {
        StepDots(current: 1, total: 4)
        StepDots(current: 2, total: 4)
        StepDots(current: 3, total: 4)
        StepDots(current: 4, total: 4)
    }
    .padding()
    .background(Color.bg)
}
