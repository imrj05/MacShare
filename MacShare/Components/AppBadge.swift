import SwiftUI

struct AppBadge: View {
    let title: String
    var tagType: TagType = .neutral
    var showDot: Bool = true

    var body: some View {
        HStack(spacing: 5) {
            if showDot {
                Circle()
                    .fill(tagType.textColor)
                    .frame(width: 6, height: 6)
            }
            Text(title)
                .font(AppFont.captionMedium)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(tagType.bgColor, in: Capsule())
        .foregroundStyle(tagType.textColor)
    }
}
