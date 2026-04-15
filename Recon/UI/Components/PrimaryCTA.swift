import SwiftUI

struct PrimaryCTA: View {
    enum Style { case primary, secondary }

    let title: String
    let style: Style
    let isEnabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.listTitle)
                .frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.border, lineWidth: style == .secondary ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var foreground: Color {
        switch style {
        case .primary: return Color.onAccent
        case .secondary: return Color.text
        }
    }

    private var background: Color {
        switch style {
        case .primary: return Color.accent
        case .secondary: return Color.surface
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryCTA("Continue") {}
        PrimaryCTA("Cancel", style: .secondary) {}
        PrimaryCTA("Disabled", isEnabled: false) {}
    }
    .padding()
    .background(Color.bg)
}
