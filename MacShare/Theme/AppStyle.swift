import SwiftUI

enum AppFont {
    static let largeTitle = Font.custom("Manrope", size: 38, relativeTo: .largeTitle).weight(.bold)
    static let title = Font.custom("Manrope", size: 30, relativeTo: .title).weight(.bold)
    static let title2 = Font.custom("Manrope", size: 24, relativeTo: .title2).weight(.bold)
    static let title3 = Font.custom("Manrope", size: 19, relativeTo: .title3).weight(.semibold)
    static let headline = Font.custom("Manrope", size: 16, relativeTo: .headline).weight(.semibold)
    static let body = Font.custom("Manrope", size: 14, relativeTo: .body).weight(.regular)
    static let bodyMedium = Font.custom("Manrope", size: 14, relativeTo: .body).weight(.medium)
    static let callout = Font.custom("Manrope", size: 13.5, relativeTo: .callout).weight(.regular)
    static let subheadline = Font.custom("Manrope", size: 13, relativeTo: .subheadline).weight(.regular)
    static let footnote = Font.custom("Manrope", size: 12, relativeTo: .footnote).weight(.regular)
    static let caption = Font.custom("Manrope", size: 11.5, relativeTo: .caption).weight(.regular)
    static let captionMedium = Font.custom("Manrope", size: 11.5, relativeTo: .caption).weight(.medium)
    static let pinCode = Font.custom("Manrope", size: 38, relativeTo: .largeTitle).weight(.bold).monospacedDigit()

    /// SF Symbols should be laid out with the system font so their metrics stay correct.
    static func icon(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight)
    }
}

enum AppStyle {
    enum Radius {
        static let chip: CGFloat = 8
        static let control: CGFloat = 10
        static let tile: CGFloat = 12
        static let panel: CGFloat = 14
        static let card: CGFloat = 16
        static let sheet: CGFloat = 22
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Row {
        static let compactHeight: CGFloat = 34
        static let standardHeight: CGFloat = 40
        static let listRowMinHeight: CGFloat = 56
        static let iconFrameSize: CGFloat = 28
    }

    enum Typography {
        static let pageTitle = AppFont.title
        static let pageSubtitle = AppFont.callout
        static let rowTitle = AppFont.body.weight(.medium)
        static let metadata = AppFont.caption
        static let metadataEmphasis = AppFont.caption.weight(.medium)
        static let sectionLabel = AppFont.caption.weight(.semibold)
    }

    enum Layout {
        static let sidebarWidth: CGFloat = 264
        static let detailMinWidth: CGFloat = 640
        static let detailMinHeight: CGFloat = 540
        static let contentInset: CGFloat = 32
        // Kept for compatibility with existing call sites.
        static let detailHorizontalInset: CGFloat = 32
        static let detailTopInset: CGFloat = 30
        static let sidebarTopInset: CGFloat = 46
        static let sidebarItemHeight: CGFloat = 38
    }
}

extension View {
    func settingsCaption() -> some View {
        self.font(AppFont.callout)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Standard elevated surface: card background + hairline border.
    func appSurface(cornerRadius: CGFloat = AppStyle.Radius.card) -> some View {
        self.background(AppColors.bgCard, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
    }
}

/// A padded, bordered surface used for grouping related content.
struct AppCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(padding: CGFloat = AppStyle.Spacing.medium,
         cornerRadius: CGFloat = AppStyle.Radius.card,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurface(cornerRadius: cornerRadius)
    }
}

/// Small uppercase label that introduces a group of content.
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(AppStyle.Typography.sectionLabel)
            .tracking(0.7)
            .foregroundStyle(AppColors.textTertiary)
    }
}

/// Page title + optional supporting line. Compose actions alongside it in an HStack.
struct PageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(AppStyle.Typography.pageTitle)
                .foregroundStyle(AppColors.textPrimary)
            if let subtitle, subtitle.isEmpty == false {
                Text(subtitle)
                    .font(AppStyle.Typography.pageSubtitle)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

/// Rounded tinted square used to anchor an icon in cards and rows.
struct IconTile: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = AppColors.accent
    var isPulsing: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(tint.opacity(0.15))
            Image(systemName: systemName)
                .font(AppFont.icon(size: size * 0.42, weight: .medium))
                .foregroundStyle(tint)
                .symbolEffect(.pulse, options: .repeating, isActive: isPulsing)
        }
        .frame(width: size, height: size)
    }
}

struct InsetCardDivider: View {
    var horizontalInset: CGFloat = AppStyle.Spacing.medium

    var body: some View {
        Rectangle()
            .fill(AppColors.borderSubtle)
            .frame(height: 1)
            .padding(.horizontal, horizontalInset)
    }
}

enum TagType {
    case success, warning, danger, neutral

    var textColor: Color {
        switch self {
        case .success: return AppColors.tagSuccessText
        case .warning: return AppColors.tagWarningText
        case .danger: return AppColors.tagDangerText
        case .neutral: return AppColors.tagNeutralText
        }
    }

    var bgColor: Color {
        switch self {
        case .success: return AppColors.tagSuccessBg
        case .warning: return AppColors.tagWarningBg
        case .danger: return AppColors.tagDangerBg
        case .neutral: return AppColors.tagNeutralBg
        }
    }
}
