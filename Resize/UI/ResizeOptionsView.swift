import Photos
import SwiftUI

struct ResizeOptionsView: View {
    @Environment(ResizeSession.self) private var session
    @Environment(ResizeRouter.self) private var router

    @State private var percentText: String = ""
    @State private var longEdgeText: String = ""
    @State private var shortEdgeText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                StepDots(current: 4, total: 4)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Resize")
                        .font(AppFont.sectionTitle)
                        .foregroundStyle(Color.text)
                    Text("How should the output be sized?")
                        .font(AppFont.body)
                        .foregroundStyle(Color.textSecondary)
                }
                VStack(spacing: 12) {
                    keepOriginalRow
                    percentageRow
                    longEdgeRow
                    shortEdgeRow
                }
                if isOriginal {
                    notice
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PrimaryCTA(processLabel) {
                UISelectionFeedbackGenerator().selectionChanged()
                router.path.append(.processing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: seedDefaults)
    }

    private var keepOriginalRow: some View {
        OptionRow(
            title: "Keep original",
            subtitle: "Convert without resizing.",
            isSelected: isOriginal
        ) {
            UISelectionFeedbackGenerator().selectionChanged()
            session.resize = .original
        }
    }

    private var percentageRow: some View {
        VStack(spacing: 10) {
            OptionRow(
                title: "Percentage",
                subtitle: "Scale each photo to a percent of its original size.",
                isSelected: isPercentage
            ) {
                UISelectionFeedbackGenerator().selectionChanged()
                let value = clampPercent(percentText) ?? 75
                percentText = String(value)
                session.resize = .percentage(value)
            }
            if isPercentage {
                inlineNumberField(text: $percentText, suffix: "%", placeholder: "75") { newValue in
                    if let int = clampPercent(newValue) {
                        session.resize = .percentage(int)
                    }
                }
            }
        }
    }

    private var longEdgeRow: some View {
        VStack(spacing: 10) {
            OptionRow(
                title: "Long edge",
                subtitle: "Cap the longest side to this pixel size.",
                isSelected: isLongEdge
            ) {
                UISelectionFeedbackGenerator().selectionChanged()
                let value = clampPx(longEdgeText) ?? defaultLongEdge
                longEdgeText = String(value)
                session.resize = .longEdge(value)
            }
            if isLongEdge {
                inlineNumberField(text: $longEdgeText, suffix: "px", placeholder: String(defaultLongEdge)) { newValue in
                    if let px = clampPx(newValue) {
                        session.resize = .longEdge(px)
                    }
                }
            }
        }
    }

    private var shortEdgeRow: some View {
        VStack(spacing: 10) {
            OptionRow(
                title: "Short edge",
                subtitle: "Cap the shortest side to this pixel size.",
                isSelected: isShortEdge
            ) {
                UISelectionFeedbackGenerator().selectionChanged()
                let value = clampPx(shortEdgeText) ?? defaultShortEdge
                shortEdgeText = String(value)
                session.resize = .shortEdge(value)
            }
            if isShortEdge {
                inlineNumberField(text: $shortEdgeText, suffix: "px", placeholder: String(defaultShortEdge)) { newValue in
                    if let px = clampPx(newValue) {
                        session.resize = .shortEdge(px)
                    }
                }
            }
        }
    }

    private var notice: some View {
        Text("Keep-original just re-encodes into the chosen format; the Photos library will hold a separate copy in the Resize album.")
            .font(AppFont.caption)
            .foregroundStyle(Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.surfaceAlt, in: RoundedRectangle(cornerRadius: 14))
    }

    private func inlineNumberField(
        text: Binding<String>,
        suffix: String,
        placeholder: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)
                .font(AppFont.listTitle)
                .foregroundStyle(Color.text)
                .onChange(of: text.wrappedValue) { _, new in onChange(new) }
            Text(suffix)
                .font(AppFont.body)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.border, lineWidth: 1)
        )
    }

    private var isOriginal: Bool {
        if case .original = session.resize { return true }
        return false
    }

    private var isPercentage: Bool {
        if case .percentage = session.resize { return true }
        return false
    }

    private var isLongEdge: Bool {
        if case .longEdge = session.resize { return true }
        return false
    }

    private var isShortEdge: Bool {
        if case .shortEdge = session.resize { return true }
        return false
    }

    private var defaultLongEdge: Int {
        let maxEdge = session.assets.map { max($0.pixelWidth, $0.pixelHeight) }.max() ?? 2000
        return max(100, (maxEdge / 100) * 100)
    }

    private var defaultShortEdge: Int {
        let maxEdge = session.assets.map { min($0.pixelWidth, $0.pixelHeight) }.max() ?? 1200
        return max(100, (maxEdge / 100) * 100)
    }

    private var processLabel: String {
        let n = session.assets.count
        return "Process \(n) \(n == 1 ? "Photo" : "Photos")"
    }

    private func clampPercent(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let v = Int(trimmed), v >= 1, v <= 99 else { return nil }
        return v
    }

    private func clampPx(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let v = Int(trimmed), v >= 1, v <= 20000 else { return nil }
        return v
    }

    private func seedDefaults() {
        switch session.resize {
        case .percentage(let p): percentText = String(p)
        case .longEdge(let l): longEdgeText = String(l)
        case .shortEdge(let s): shortEdgeText = String(s)
        case .original: break
        }
        if percentText.isEmpty { percentText = "75" }
        if longEdgeText.isEmpty { longEdgeText = String(defaultLongEdge) }
        if shortEdgeText.isEmpty { shortEdgeText = String(defaultShortEdge) }
    }
}
