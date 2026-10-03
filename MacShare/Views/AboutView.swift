import SwiftUI

struct AboutView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppStyle.Spacing.xLarge) {
                VStack(spacing: AppStyle.Spacing.medium) {
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    VStack(spacing: 5) {
                        Text("Mac Share")
                            .font(AppFont.largeTitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Version " + appVersion + " (" + buildNumber + ")")
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(String(localized: "Share files with nearby Android devices over your local network.", comment: "About tagline"))
                        .font(AppFont.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                }
                .padding(.top, AppStyle.Spacing.xLarge)

                VStack(spacing: AppStyle.Spacing.xSmall) {
                    linkRow(
                        title: String(localized: "GitHub Repository", comment: "About link"),
                        subtitle: "github.com/imrj05/MacShare",
                        symbol: "link",
                        url: URL(string: "https://github.com/imrj05/MacShare")
                    )
                    linkRow(
                        title: String(localized: "Protocol Documentation", comment: "About link"),
                        subtitle: "PROTOCOL.md",
                        symbol: "doc.text",
                        url: URL(string: "https://github.com/imrj05/MacShare/blob/main/PROTOCOL.md")
                    )
                }
                .frame(maxWidth: 460)

                Text(String(localized: "Licensed under the Unlicense", comment: "About license"))
                    .font(AppStyle.Typography.metadata)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.bottom, AppStyle.Spacing.xLarge)
            }
            .padding(.horizontal, AppStyle.Layout.contentInset)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.bgBase)
    }

    @ViewBuilder
    private func linkRow(title: String, subtitle: String, symbol: String, url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                HStack(spacing: AppStyle.Spacing.small) {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 34, height: 34)
                        .background(AppColors.accentSoft, in: RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(AppFont.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(subtitle)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer(minLength: AppStyle.Spacing.xSmall)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, AppStyle.Spacing.small)
                .padding(.vertical, 10)
                .appSurface(cornerRadius: AppStyle.Radius.panel)
                .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}
