import SwiftUI

enum AppFont {
    static let display = Font.system(size: 34, weight: .bold)
    static let sectionTitle = Font.system(size: 28, weight: .bold)
    static let navTitle = Font.system(size: 17, weight: .semibold)
    static let navSubtitle = Font.system(size: 12, weight: .medium)
    static let body = Font.system(size: 15, weight: .regular)
    static let listTitle = Font.system(size: 16, weight: .semibold)
    static let listSubtitle = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
    static let valueDisplay = Font.system(size: 72, weight: .bold).monospacedDigit()
    static let ringPercent = Font.system(size: 54, weight: .bold).monospacedDigit()
}
