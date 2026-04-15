import SwiftUI
import UIKit

struct QualitySlider: View {
    @Binding var value: Double

    private let trackHeight: CGFloat = 6
    private let knobSize: CGFloat = 22
    private let ringWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let clamped = min(max(value, 0), 1)
            let knobLeadingOffset = clamped * (width - knobSize)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.border)
                    .frame(height: trackHeight)
                    .frame(maxWidth: .infinity)
                Capsule()
                    .fill(Color.accent)
                    .frame(width: knobLeadingOffset + knobSize / 2, height: trackHeight)
                Circle()
                    .fill(Color.surface)
                    .frame(width: knobSize, height: knobSize)
                    .overlay(Circle().stroke(Color.accent, lineWidth: ringWidth))
                    .shadow(color: Color.black.opacity(0.15), radius: 3, y: 2)
                    .offset(x: knobLeadingOffset)
            }
            .frame(height: knobSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let usable = max(width - knobSize, 1)
                        let touch = min(max(gesture.location.x - knobSize / 2, 0), usable)
                        value = Double(touch / usable)
                    }
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            )
        }
        .frame(height: 22)
        .accessibilityElement()
        .accessibilityRepresentation {
            Slider(value: $value, in: 0...1, step: 0.01)
        }
    }
}

#Preview {
    @Previewable @State var value: Double = 0.85
    VStack(spacing: 20) {
        QualitySlider(value: $value)
        Text(String(format: "%.2f", value)).font(AppFont.body)
    }
    .padding()
    .background(Color.bg)
}
