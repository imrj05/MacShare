import AppKit
import MacShareKit
import SwiftUI

struct SettingsView: View {
    @Environment(MacShareStore.self) private var store
    @ObservedObject private var updater = UpdaterController.shared
    @State private var selectedPane: SettingsPane = .general
    @State private var copiedLink = false

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                    header
                    panePicker(proxy)
                    generalSection.id(SettingsPane.general)
                    deviceSection.id(SettingsPane.device)
                    visibilitySection.id(SettingsPane.visibility)
                    receivingSection.id(SettingsPane.receiving)
                    qrSection.id(SettingsPane.qr)
                }
                .padding(.horizontal, AppStyle.Layout.contentInset)
                .padding(.top, AppStyle.Layout.detailTopInset)
                .padding(.bottom, AppStyle.Spacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(AppColors.bgBase)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
            PageHeader(
                title: String(localized: "Settings", comment: "Settings title"),
                subtitle: String(localized: "Configure how Mac Share behaves on this Mac", comment: "Settings subtitle")
            )
            Spacer(minLength: AppStyle.Spacing.medium)
            AppBadge(title: "v\(appVersion)", tagType: .neutral, showDot: false)
        }
    }

    // MARK: - Pane picker

    private func panePicker(_ proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SettingsPane.allCases) { pane in
                    Button {
                        selectedPane = pane
                        withAnimation(.snappy(duration: 0.3)) {
                            proxy.scrollTo(pane, anchor: .top)
                        }
                    } label: {
                        Label(pane.title, systemImage: pane.icon)
                            .font(AppFont.subheadline.weight(.medium))
                            .foregroundStyle(selectedPane == pane ? AppColors.textOnAccent : AppColors.textSecondary)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 12)
                            .background(
                                selectedPane == pane ? AppColors.accent : AppColors.bgElevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(
                                        selectedPane == pane ? Color.clear : AppColors.borderSubtle,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Sections

    private var generalSection: some View {
        settingsSection(.general) {
            VStack(spacing: 0) {
                SettingsValueRow(
                    icon: "paintbrush",
                    title: String(localized: "Appearance", comment: "Appearance label"),
                    subtitle: String(localized: "Follow the system or choose a theme", comment: "Appearance help")
                ) {
                    appearancePicker
                        .frame(width: 220)
                }

                InsetCardDivider()

                SettingsToggleRow(
                    icon: "power",
                    title: String(localized: "Launch at Login", comment: "Launch at login toggle"),
                    subtitle: String(localized: "Start Mac Share automatically when you log in", comment: "Launch at login help"),
                    isOn: Binding(
                        get: { store.launchAtLogin },
                        set: { store.launchAtLogin = $0 }
                    )
                )

                InsetCardDivider()

                SettingsToggleRow(
                    icon: "menubar.rectangle",
                    title: String(localized: "Show Menu Bar Icon", comment: "Menu bar icon toggle"),
                    subtitle: String(localized: "Keep quick access in the menu bar", comment: "Menu bar icon help"),
                    isOn: Binding(
                        get: { store.showMenuBarIcon },
                        set: {
                            store.showMenuBarIcon = $0
                            AppDelegate.shared?.setMenuBarIconVisible($0)
                        }
                    )
                )

                InsetCardDivider()

                SettingsValueRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: String(localized: "Software Update", comment: "Updates label"),
                    subtitle: String(localized: "Mac Share \(updater.currentVersion)", comment: "Updates subtitle")
                ) {
                    Button {
                        updater.checkForUpdates()
                    } label: {
                        Label(String(localized: "Check Now", comment: "Check for updates button"), systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true, size: .small))
                    .disabled(!updater.canCheckForUpdates)
                }

                InsetCardDivider()

                SettingsToggleRow(
                    icon: "clock.arrow.circlepath",
                    title: String(localized: "Automatically Check for Updates", comment: "Auto update toggle"),
                    subtitle: String(localized: "Check for new versions in the background", comment: "Auto update help"),
                    isOn: Binding(
                        get: { updater.automaticallyChecksForUpdates },
                        set: { updater.automaticallyChecksForUpdates = $0 }
                    )
                )
            }
        }
    }

    private var deviceSection: some View {
        settingsSection(.device) {
            VStack(spacing: 0) {
                SettingsValueRow(
                    icon: "laptopcomputer",
                    title: String(localized: "Device Name", comment: "Device name label"),
                    subtitle: String(localized: "Shown to nearby Android devices", comment: "Device name help")
                ) {
                    TextField("", text: Binding(
                        get: { store.deviceName },
                        set: { store.deviceName = $0 }
                    ))
                    .textFieldStyle(.plain)
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, AppStyle.Spacing.small)
                    .frame(width: 230, height: 34)
                    .background(AppColors.bgInput, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )
                }

                InsetCardDivider()

                SettingsInfoRow(
                    icon: "info.circle",
                    text: String(localized: "Changing the device name updates what nearby devices show in their Quick Share list.", comment: "Device name footer")
                )
            }
        }
    }

    private var visibilitySection: some View {
        settingsSection(.visibility) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "eye",
                    title: String(localized: "Visible to Nearby Devices", comment: "Visibility toggle"),
                    subtitle: String(localized: "Allow Android devices on your network to discover this Mac", comment: "Visibility help"),
                    isOn: Binding(
                        get: { store.isDiscoverable },
                        set: { store.isDiscoverable = $0 }
                    )
                )

                InsetCardDivider()

                SettingsInfoRow(
                    icon: "lock.shield",
                    text: String(localized: "When visible, your Mac appears to everyone on your local network. Mac Share never talks to Google servers.", comment: "Visibility footer")
                )
            }
        }
    }

    private var receivingSection: some View {
        settingsSection(.receiving) {
            VStack(spacing: 0) {
                SettingsValueRow(
                    icon: "folder",
                    title: String(localized: "Save To", comment: "Save to label"),
                    subtitle: store.saveFolder.path
                ) {
                    Button {
                        chooseSaveFolder()
                    } label: {
                        Label(String(localized: "Choose…", comment: "Choose folder button"), systemImage: "folder")
                    }
                    .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true, size: .small))
                }

                InsetCardDivider()

                SettingsToggleRow(
                    icon: "checkmark.circle",
                    title: String(localized: "Ask Before Accepting", comment: "Ask before accepting toggle"),
                    subtitle: String(localized: "Incoming transfers always require your approval", comment: "Ask before accepting help"),
                    isOn: .constant(true)
                )
                .disabled(true)
                .opacity(0.6)
            }
        }
    }

    private var qrSection: some View {
        settingsSection(.qr) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                HStack(alignment: .center, spacing: AppStyle.Spacing.large) {
                    IconTile(systemName: "qrcode", size: 84)

                    VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                        Text(String(localized: "Pair with Android", comment: "QR section title"))
                            .font(AppFont.headline)
                            .foregroundStyle(AppColors.textPrimary)

                        Text(String(localized: "Scan this code with Google Files or Quick Share on Android to connect instantly.", comment: "QR section help"))
                            .font(AppFont.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            copyPairingLink()
                        } label: {
                            Label(
                                copiedLink
                                    ? String(localized: "Copied", comment: "Copied button")
                                    : String(localized: "Copy Pairing Link", comment: "Copy pairing link button"),
                                systemImage: copiedLink ? "checkmark" : "doc.on.doc"
                            )
                        }
                        .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true))
                    }

                    Spacer(minLength: 0)
                }

                SettingsInfoRow(
                    icon: "qrcode.viewfinder",
                    text: String(localized: "The pairing link contains a temporary public key. Regenerating it invalidates the previous QR code.", comment: "QR footer")
                )
            }
            .padding(AppStyle.Spacing.medium)
        }
    }

    // MARK: - Section wrapper

    private func settingsSection<Content: View>(_ pane: SettingsPane, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(spacing: AppStyle.Spacing.xSmall) {
                Image(systemName: pane.icon)
                    .font(AppFont.icon(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                SectionLabel(pane.title)
            }

            AppCard(padding: 0) {
                content()
            }
        }
    }

    // MARK: - Appearance picker

    private var appearancePicker: some View {
        HStack(spacing: 3) {
            ForEach(AppearanceMode.allCases) { mode in
                let isSelected = store.appearanceMode == mode
                Button {
                    store.appearanceMode = mode
                    store.applyAppearance()
                } label: {
                    Text(mode.title)
                        .font(AppFont.captionMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            isSelected ? AppColors.bgCard : Color.clear,
                            in: RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous)
                        )
                        .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                        .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(AppColors.bgElevated, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control + 3, style: .continuous))
    }

    // MARK: - Actions

    private func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = String(localized: "Choose", comment: "Choose folder prompt")
        if panel.runModal() == .OK, let url = panel.url {
            store.saveFolder = url
        }
    }

    private func copyPairingLink() {
        let key = NearbyConnectionManager.shared.generateQrCodeKey()
        let link = "https://quickshare.google/qrcode#key=\(key)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link, forType: .string)

        withAnimation(.easeOut(duration: 0.15)) {
            copiedLink = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.15)) {
                copiedLink = false
            }
        }
    }

}

// MARK: - Pane

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general, device, visibility, receiving, qr

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return String(localized: "General", comment: "Settings pane")
        case .device: return String(localized: "Device", comment: "Settings pane")
        case .visibility: return String(localized: "Visibility", comment: "Settings pane")
        case .receiving: return String(localized: "Receiving", comment: "Settings pane")
        case .qr: return String(localized: "QR Code", comment: "Settings pane")
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .device: return "laptopcomputer"
        case .visibility: return "eye"
        case .receiving: return "tray.and.arrow.down"
        case .qr: return "qrcode"
        }
    }
}

// MARK: - Rows

private struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            IconTile(systemName: icon, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }
}

private struct SettingsValueRow<Trailing: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let trailing: Trailing

    init(icon: String, title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
            SettingsRowLabel(icon: icon, title: title, subtitle: subtitle)
            Spacer(minLength: AppStyle.Spacing.small)
            trailing
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
            SettingsRowLabel(icon: icon, title: title, subtitle: subtitle)
            Spacer(minLength: AppStyle.Spacing.small)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(AppColors.accent)
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
    }
}

private struct SettingsInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppStyle.Spacing.xSmall) {
            Image(systemName: icon)
                .font(AppFont.icon(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.top, 1)
            Text(text)
                .font(AppFont.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
    }
}
