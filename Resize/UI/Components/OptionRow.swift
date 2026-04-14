import SwiftUI

struct OptionRow: View {
    let title: String
    let subtitle: String?
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(AppFont.listTitle).foregroundStyle(Color.text)
                        if let badge {
                            Text(badge)
                                .font(AppFont.caption)
                                .foregroundStyle(Color.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentSoft, in: Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(AppFont.listSubtitle)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                radio
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected ? Color.accent : Color.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var radio: some View {
        ZStack {
            Circle().stroke(Color.border, lineWidth: 2).frame(width: 22, height: 22)
            if isSelected {
                Circle().fill(Color.accent).frame(width: 22, height: 22)
                Circle().fill(Color.onAccent).frame(width: 10, height: 10)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 12) {
        OptionRow(
            title: "JPEG",
            subtitle: "Universally supported; great for photos",
            badge: "Most compatible",
            isSelected: true
        ) {}
        OptionRow(
            title: "PNG",
            subtitle: "Lossless, with transparency",
            isSelected: false
        ) {}
    }
    .padding()
    .background(Color.bg)
}
