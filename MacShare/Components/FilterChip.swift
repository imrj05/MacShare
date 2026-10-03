import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let symbolName: String?
    let count: Int?
    let tagType: TagType

    init(
        title: String,
        isSelected: Bool,
        symbolName: String? = nil,
        count: Int? = nil,
        tagType: TagType = .neutral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.symbolName = symbolName
        self.count = count
        self.tagType = tagType
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.subheadline.weight(isSelected ? .semibold : .regular))
                if let count {
                    Text(String(count))
                        .font(AppFont.captionMedium)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(countBackground, in: Capsule())
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(background, in: Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : AppColors.borderSubtle, lineWidth: 1)
            )
            .foregroundStyle(foregroundColor)
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        isSelected ? tagType.bgColor : .clear
    }

    private var countBackground: Color {
        isSelected ? foregroundColor.opacity(0.16) : AppColors.bgElevated
    }

    private var foregroundColor: Color {
        isSelected ? tagType.textColor : AppColors.textSecondary
    }
}
