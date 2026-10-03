import SwiftUI

/// Semantic color tokens backed by asset-catalog color sets.
///
/// Asset colors are resolved by the system for the current appearance and refresh
/// automatically when the appearance changes — unlike a static dynamic `NSColor`,
/// which SwiftUI can resolve once and then cache.
enum AppColors {
    // MARK: - Surfaces
    static let bgBase = Color("bgBase")
    static let bgSidebar = Color("bgSidebar")
    static let bgCard = Color("bgCard")
    static let bgElevated = Color("bgElevated")
    static let bgOverlay = Color("bgOverlay")
    static let bgInput = Color("bgInput")
    static let bgHover = Color("bgHover")
    static let selectionBg = Color("selectionBg")

    static let borderSubtle = Color("borderSubtle")
    static let borderStrong = Color("borderStrong")

    // MARK: - Text
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary = Color("textTertiary")
    static let textOnAccent = Color("textOnAccent")

    // MARK: - Buttons
    static let buttonPrimaryBg = Color("buttonPrimaryBg")
    static let buttonPrimaryText = Color("buttonPrimaryText")
    static let buttonSecondaryBg = Color("buttonSecondaryBg")
    static let buttonSecondaryBorder = Color("buttonSecondaryBorder")

    // MARK: - Status Tags
    static let tagSuccessText = Color("tagSuccessText")
    static let tagSuccessBg = Color("tagSuccessBg")
    static let tagWarningText = Color("tagWarningText")
    static let tagWarningBg = Color("tagWarningBg")
    static let tagDangerText = Color("tagDangerText")
    static let tagDangerBg = Color("tagDangerBg")
    static let tagNeutralText = Color("tagNeutralText")
    static let tagNeutralBg = Color("tagNeutralBg")

    // MARK: - Accent
    static let accent = Color("accent")
    static let accentSoft = Color("accentSoft")
}
