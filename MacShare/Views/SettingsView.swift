import AppKit
import SwiftUI

struct SettingsView: View {
    @Environment(MacShareStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                PageHeader(
                    title: String(localized: "Settings", comment: "Settings title"),
                    subtitle: String(localized: "Configure how Mac Share behaves on this Mac", comment: "Settings subtitle")
                )

                section(String(localized: "General", comment: "Settings section")) {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                        VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
                            Text(String(localized: "Appearance", comment: "Appearance picker"))
                                .font(AppFont.body)
                                .foregroundStyle(AppColors.textPrimary)
                            appearancePicker
                        }

                        SettingsToggleRow(
                            title: String(localized: "Launch at Login", comment: "Launch at login toggle"),
                            isOn: Binding(
                                get: { store.launchAtLogin },
                                set: { store.launchAtLogin = $0 }
                            )
                        )

                        SettingsToggleRow(
                            title: String(localized: "Show Menu Bar Icon", comment: "Menu bar icon toggle"),
                            isOn: Binding(
                                get: { store.showMenuBarIcon },
                                set: {
                                    store.showMenuBarIcon = $0
                                    AppDelegate.shared?.setMenuBarIconVisible($0)
                                }
                            )
                        )
                    }
                }

                section(String(localized: "Device", comment: "Settings section")) {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
                        Text(String(localized: "Device Name", comment: "Device name label"))
                            .font(AppFont.body)
                            .foregroundStyle(AppColors.textPrimary)

                        TextField("", text: Binding(
                            get: { store.deviceName },
                            set: { store.deviceName = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(AppFont.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.horizontal, AppStyle.Spacing.small)
                        .frame(height: 34)
                        .background(AppColors.bgInput, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                        )

                        Text(String(localized: "This name is shown to nearby devices.", comment: "Device name help"))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                section(String(localized: "Visibility", comment: "Settings section")) {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                        SettingsToggleRow(
                            title: String(localized: "Visible to nearby devices", comment: "Visibility toggle"),
                            isOn: Binding(
                                get: { store.isDiscoverable },
                                set: { store.isDiscoverable = $0 }
                            )
                        )
                        Text(String(localized: "When visible, your Mac appears to everyone on your local network.", comment: "Visibility help"))
                            .font(AppFont.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                section(String(localized: "Receiving", comment: "Settings section")) {
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                        HStack(spacing: AppStyle.Spacing.small) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Save to", comment: "Save to label"))
                                    .font(AppFont.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(store.saveFolder.lastPathComponent)
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer(minLength: AppStyle.Spacing.small)
                            Button {
                                chooseSaveFolder()
                            } label: {
                                Label(String(localized: "Choose…", comment: "Choose folder button"), systemImage: "folder")
                            }
                            .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true))
                        }

                        SettingsToggleRow(
                            title: String(localized: "Ask before accepting", comment: "Ask before accepting toggle"),
                            isOn: .constant(true)
                        )
                        .disabled(true)
                        .opacity(0.6)
                    }
                }

                section(String(localized: "QR Code", comment: "Settings section")) {
                    HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
                        IconTile(systemName: "qrcode", size: 76)
                            .foregroundStyle(AppColors.textPrimary)

                        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
                            Text(String(localized: "Scan with Google Files or Quick Share on Android", comment: "QR help text"))
                                .font(AppFont.body)
                                .foregroundStyle(AppColors.textPrimary)
                            Button {
                                // Pairing link will be wired when the QR generator is shared with the app target.
                            } label: {
                                Label(String(localized: "Copy Link", comment: "Copy link button"), systemImage: "doc.on.doc")
                            }
                            .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true))
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, AppStyle.Layout.contentInset)
            .padding(.top, AppStyle.Layout.detailTopInset)
            .padding(.bottom, AppStyle.Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.bgBase)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            SectionLabel(title)
            AppCard { content() }
        }
    }

    private var appearancePicker: some View {
        HStack(spacing: 3) {
            ForEach(AppearanceMode.allCases) { mode in
                let isSelected = store.appearanceMode == mode
                Button {
                    store.appearanceMode = mode
                    store.applyAppearance()
                } label: {
                    Text(mode.title)
                        .font(AppFont.subheadline.weight(.semibold))
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
        .frame(maxWidth: 320)
    }

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
}

private struct SettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .toggleStyle(.switch)
        .tint(AppColors.accent)
    }
}
