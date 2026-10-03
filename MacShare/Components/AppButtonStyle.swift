import SwiftUI

struct AppButtonStyle: ButtonStyle {
    enum Variant {
        case primary, secondary, ghost, destructive, accent
    }

    enum Size {
        case small, regular, large
    }

    var variant: Variant = .primary
    var isCapsule: Bool = false
    var size: Size = .regular

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: minHeight)
            .background(background)
            .clipShape(shape)
            .overlay(shape.stroke(borderColor, lineWidth: borderWidth))
            .foregroundStyle(foreground)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var shape: AnyShape {
        isCapsule
            ? AnyShape(Capsule())
            : AnyShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
    }

    private var font: Font {
        switch size {
        case .small: return AppFont.footnote.weight(.semibold)
        case .regular: return AppFont.subheadline.weight(.semibold)
        case .large: return AppFont.body.weight(.semibold)
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 10
        case .regular: return 14
        case .large: return 18
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 4
        case .regular: return 7
        case .large: return 10
        }
    }

    private var minHeight: CGFloat {
        switch size {
        case .small: return 24
        case .regular: return 30
        case .large: return 38
        }
    }

    private var background: Color {
        switch variant {
        case .primary: return AppColors.buttonPrimaryBg
        case .secondary: return AppColors.buttonSecondaryBg
        case .ghost: return .clear
        case .destructive: return AppColors.tagDangerText.opacity(0.12)
        case .accent: return AppColors.accent
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary: return AppColors.buttonPrimaryText
        case .secondary, .ghost: return AppColors.textPrimary
        case .destructive: return AppColors.tagDangerText
        case .accent: return AppColors.textOnAccent
        }
    }

    private var borderColor: Color {
        variant == .secondary ? AppColors.buttonSecondaryBorder : .clear
    }

    private var borderWidth: CGFloat {
        variant == .secondary ? 1 : 0
    }
}

/// A refresh/scan button whose icon spins one full turn on every activation.
struct RefreshButton: View {
    let title: String
    var variant: AppButtonStyle.Variant = .secondary
    var size: AppButtonStyle.Size = .regular
    let action: () -> Void

    @State private var angle: Double = 0

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.6)) { angle += 360 }
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(.degrees(angle))
                Text(title)
            }
        }
        .buttonStyle(AppButtonStyle(variant: variant, isCapsule: true, size: size))
    }
}

// MARK: - AnyShape wrapper for type-erasing Capsule vs RoundedRectangle
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path

    init(_ shape: some Shape) {
        self._path = shape.path
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}
