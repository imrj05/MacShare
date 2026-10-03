import AppKit
import SwiftUI

struct AboutView: View {
    @State private var showingLicense = false

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.1"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                PageHeader(
                    title: String(localized: "About", comment: "About page title"),
                    subtitle: String(localized: "Mac Share for nearby transfers", comment: "About subtitle")
                )

                heroCard
                featureGrid
                resourcesSection
                footer
            }
            .padding(.horizontal, AppStyle.Layout.contentInset)
            .padding(.top, AppStyle.Layout.detailTopInset)
            .padding(.bottom, AppStyle.Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.bgBase)
        .sheet(isPresented: $showingLicense) {
            LicenseSheet()
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        AppCard(padding: 28) {
            VStack(spacing: AppStyle.Spacing.medium) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )

                VStack(spacing: 4) {
                    Text("Mac Share")
                        .font(AppFont.title)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text(String(localized: "Share files with nearby Android devices over your local network — without an account, a cloud service, or an internet connection.", comment: "About tagline"))
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AppStyle.Spacing.xSmall) {
                    AppBadge(title: String(localized: "Wi-Fi LAN", comment: "About badge"), tagType: .neutral, showDot: false)
                    AppBadge(title: String(localized: "No Account", comment: "About badge"), tagType: .neutral, showDot: false)
                    AppBadge(title: String(localized: "Private", comment: "About badge"), tagType: .success, showDot: false)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Features

    private var featureGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 240), spacing: AppStyle.Spacing.medium)],
            spacing: AppStyle.Spacing.medium
        ) {
            AboutFeatureCard(
                icon: "wifi",
                title: String(localized: "Local Network", comment: "About feature"),
                subtitle: String(localized: "Devices connect directly over your Wi-Fi LAN.", comment: "About feature detail")
            )
            AboutFeatureCard(
                icon: "lock.shield",
                title: String(localized: "Private by Default", comment: "About feature"),
                subtitle: String(localized: "No account, no tracking, and no Google servers involved.", comment: "About feature detail")
            )
            AboutFeatureCard(
                icon: "bolt.horizontal",
                title: String(localized: "Fast Transfers", comment: "About feature"),
                subtitle: String(localized: "Peer-to-peer transfer keeps files on your local network.", comment: "About feature detail")
            )
            AboutFeatureCard(
                icon: "chevron.left.forwardslash.chevron.right",
                title: String(localized: "Open Source", comment: "About feature"),
                subtitle: String(localized: "Released under the MIT License.", comment: "About feature detail")
            )
        }
    }

    // MARK: - Resources

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            SectionLabel(String(localized: "Resources", comment: "About resources section"))

            AppCard(padding: 0) {
                VStack(spacing: 0) {
                    AboutLinkRow(
                        icon: "link",
                        title: String(localized: "GitHub Repository", comment: "About link"),
                        subtitle: "github.com/imrj05/MacShare",
                        url: URL(string: "https://github.com/imrj05/MacShare")
                    )

                    InsetCardDivider(horizontalInset: AppStyle.Spacing.medium)

                    AboutLinkRow(
                        icon: "doc.text",
                        title: String(localized: "Protocol Documentation", comment: "About link"),
                        subtitle: "PROTOCOL.md",
                        url: URL(string: "https://github.com/imrj05/MacShare/blob/main/PROTOCOL.md")
                    )

                    InsetCardDivider(horizontalInset: AppStyle.Spacing.medium)

                    AboutLinkRow(
                        icon: "checkmark.seal",
                        title: String(localized: "License", comment: "About link"),
                        subtitle: "MIT LICENSE",
                        action: { showingLicense = true },
                        trailingIcon: "chevron.right"
                    )
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.xSmall) {
            Image(systemName: "sparkles")
                .font(AppFont.icon(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)

            Text(String(localized: "Built natively for macOS with SwiftUI.", comment: "About footer"))
                .font(AppFont.caption)
                .foregroundStyle(AppColors.textTertiary)

            Spacer(minLength: AppStyle.Spacing.small)

            Text(String(localized: "Licensed under the MIT License", comment: "About footer license"))
                .font(AppFont.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, 2)
    }
}

// MARK: - Cards

private struct AboutFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        AppCard(padding: AppStyle.Spacing.medium) {
            HStack(alignment: .top, spacing: AppStyle.Spacing.small) {
                IconTile(systemName: icon, size: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFont.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct AboutLinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var url: URL? = nil
    var action: (() -> Void)? = nil
    var trailingIcon: String = "arrow.up.right"

    @State private var isHovering = false

    var body: some View {
        Group {
            if let url {
                Link(destination: url) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else if let action {
                Button {
                    action()
                } label: {
                    rowContent
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            IconTile(systemName: icon, size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: AppStyle.Spacing.small)

            Image(systemName: trailingIcon)
                .font(AppFont.icon(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
        .background(
            isHovering ? AppColors.bgHover : Color.clear,
            in: RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.panel, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private struct LicenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private let licenseText = """
MIT License

Copyright (c) 2026 Rajeshwar Kashyap

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: AppStyle.Spacing.small) {
                IconTile(systemName: "checkmark.seal", size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "MIT License", comment: "License title"))
                        .font(AppFont.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(String(localized: "Copyright (c) 2026 Rajeshwar Kashyap", comment: "License subtitle"))
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: AppStyle.Spacing.small)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(AppButtonStyle(variant: .ghost, size: .small))
                .help("Close")
            }
            .padding(AppStyle.Spacing.medium)

            InsetCardDivider(horizontalInset: 0)

            ScrollView {
                Text(licenseText)
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppStyle.Spacing.large)
            }

            InsetCardDivider(horizontalInset: 0)

            HStack {
                Text(String(localized: "Licensed under the MIT License.", comment: "License footer"))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: AppStyle.Spacing.small)

                Button {
                    copyLicense()
                } label: {
                    Label(
                        copied
                            ? String(localized: "Copied", comment: "Copied")
                            : String(localized: "Copy License", comment: "Copy license button"),
                        systemImage: copied ? "checkmark" : "doc.on.doc"
                    )
                }
                .buttonStyle(AppButtonStyle(variant: copied ? .secondary : .primary, isCapsule: true))
            }
            .padding(AppStyle.Spacing.medium)
        }
        .frame(width: 560, height: 520)
        .background(AppColors.bgBase)
    }

    private func copyLicense() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(licenseText, forType: .string)

        withAnimation(.easeOut(duration: 0.15)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.15)) {
                copied = false
            }
        }
    }
}
