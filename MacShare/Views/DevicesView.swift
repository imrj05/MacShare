import AppKit
import SwiftUI

struct DevicesView: View {
    @Environment(MacShareStore.self) private var store
    @State private var pendingURLs: [URL] = []
    @State private var showingDevicePicker = false
    @State private var showingNoDevicesAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                header

                if store.discoveredDevices.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 240), spacing: AppStyle.Spacing.medium)],
                        spacing: AppStyle.Spacing.medium
                    ) {
                        ForEach(store.discoveredDevices) { device in
                            DeviceCard(device: device) {
                                chooseFiles(for: device)
                            }
                            .transition(.scale(scale: 0.96).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.discoveredDevices)
                }
            }
            .padding(.horizontal, AppStyle.Layout.contentInset)
            .padding(.top, AppStyle.Layout.detailTopInset)
            .padding(.bottom, AppStyle.Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.bgBase)
        .sheet(isPresented: $showingDevicePicker) {
            DevicePickerSheet(
                devices: store.discoveredDevices,
                fileCount: pendingURLs.count,
                onCancel: {
                    pendingURLs = []
                    showingDevicePicker = false
                },
                onSend: { device in
                    store.sendFiles(pendingURLs, to: device)
                    pendingURLs = []
                    showingDevicePicker = false
                }
            )
        }
        .alert(
            String(localized: "No devices found", comment: "Devices empty state"),
            isPresented: $showingNoDevicesAlert
        ) {
            Button(String(localized: "OK", comment: "Alert button"), role: .cancel) {
                pendingURLs = []
            }
        } message: {
            Text(String(localized: "Make sure your Android device is visible and on the same Wi-Fi network.", comment: "No devices alert"))
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
            PageHeader(title: String(localized: "Devices", comment: "Devices page title"), subtitle: devicesSubtitle)

            Spacer(minLength: AppStyle.Spacing.medium)

            HStack(spacing: AppStyle.Spacing.xSmall) {
                RefreshButton(title: String(localized: "Scan", comment: "Scan button"), variant: .secondary) {
                    store.refreshDiscovery()
                }

                Button {
                    chooseFilesForHeaderSend()
                } label: {
                    Label(String(localized: "Send", comment: "Send button"), systemImage: "paperplane.fill")
                }
                .buttonStyle(AppButtonStyle(variant: .primary, isCapsule: true))
            }
        }
    }

    private var devicesSubtitle: String {
        let count = store.discoveredDevices.count
        if count == 0 {
            return String(localized: "Searching your network for nearby devices", comment: "Devices subtitle")
        }
        return String(format: String(localized: "%d devices ready to receive", comment: "Devices subtitle"), count)
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.medium) {
            IconTile(systemName: "antenna.radiowaves.left.and.right", size: 68)

            VStack(spacing: 6) {
                Text(String(localized: "No devices nearby", comment: "Devices empty title"))
                    .font(AppFont.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(String(localized: "Open Google Files or Quick Share on your Android device and keep both devices on the same Wi-Fi network.", comment: "Devices empty description"))
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            RefreshButton(title: String(localized: "Scan Again", comment: "Scan again button"), variant: .primary) {
                store.refreshDiscovery()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private func chooseFilesForHeaderSend() {
        let urls = chooseFiles()
        guard urls.count > 0 else { return }
        pendingURLs = urls
        if store.discoveredDevices.isEmpty {
            showingNoDevicesAlert = true
        } else {
            showingDevicePicker = true
        }
    }

    private func chooseFiles(for device: DiscoveredDevice) {
        let urls = chooseFiles()
        guard urls.count > 0 else { return }
        store.sendFiles(urls, to: device)
    }

    private func chooseFiles() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = String(localized: "Send", comment: "Open panel prompt")
        return panel.runModal() == .OK ? panel.urls : []
    }
}

struct DeviceCard: View {
    let device: DiscoveredDevice
    var onSend: () -> Void

    @State private var isHovering = false

    var body: some View {
        AppCard(padding: 20) {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                HStack(alignment: .top) {
                    IconTile(systemName: device.sfSymbolName, size: 52)
                    Spacer(minLength: AppStyle.Spacing.xSmall)
                    if device.isBusy {
                        AppBadge(title: String(localized: "Sending", comment: "Device busy"), tagType: .warning)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(device.name)
                        .font(AppFont.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(deviceTypeLabel)
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if device.isBusy {
                    HStack(spacing: AppStyle.Spacing.xSmall) {
                        ProgressView()
                            .controlSize(.small)
                        Text(String(localized: "Sending…", comment: "Device busy"))
                            .font(AppFont.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 34)
                } else {
                    Button {
                        onSend()
                    } label: {
                        Label(String(localized: "Send", comment: "Send to device"), systemImage: "paperplane.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true, size: .regular))
                }
            }
            .animation(.easeOut(duration: 0.2), value: device.isBusy)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                .strokeBorder(isHovering ? AppColors.borderStrong : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.01 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var deviceTypeLabel: String {
        switch device.deviceType {
        case .phone: return String(localized: "Phone", comment: "Device type")
        case .tablet: return String(localized: "Tablet", comment: "Device type")
        case .computer: return String(localized: "Computer", comment: "Device type")
        case .unknown: return String(localized: "Device", comment: "Device type")
        }
    }
}

struct DevicePickerSheet: View {
    let devices: [DiscoveredDevice]
    let fileCount: Int
    let onCancel: () -> Void
    let onSend: (DiscoveredDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Choose a device", comment: "Device picker title"))
                        .font(AppFont.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(String(fileCount) + " " + String(localized: "file(s)", comment: "Selected file count"))
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Button(String(localized: "Cancel", comment: "Cancel button")) {
                    onCancel()
                }
                .buttonStyle(AppButtonStyle(variant: .ghost, isCapsule: true))
            }

            if devices.isEmpty {
                VStack(spacing: AppStyle.Spacing.small) {
                    IconTile(systemName: "antenna.radiowaves.left.and.right", size: 56)
                    Text(String(localized: "No Nearby Devices", comment: "Device picker empty title"))
                        .font(AppFont.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(String(localized: "Make sure the Android device is visible and on the same Wi-Fi network.", comment: "Device picker empty description"))
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(devices) { device in
                            Button {
                                onSend(device)
                            } label: {
                                DevicePickerRow(device: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 340)
            }
        }
        .padding(AppStyle.Spacing.large)
        .frame(width: 420)
        .background(AppColors.bgBase)
    }
}

struct DevicePickerRow: View {
    let device: DiscoveredDevice

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            IconTile(systemName: device.sfSymbolName, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(AppFont.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                Text(deviceTypeLabel)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "paperplane.fill")
                .font(AppFont.icon(size: 13, weight: .medium))
                .foregroundStyle(AppColors.accent)
        }
        .padding(.horizontal, AppStyle.Spacing.small)
        .padding(.vertical, 9)
        .background(isHovering ? AppColors.bgElevated : AppColors.bgCard, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var deviceTypeLabel: String {
        switch device.deviceType {
        case .phone: return String(localized: "Phone", comment: "Device type")
        case .tablet: return String(localized: "Tablet", comment: "Device type")
        case .computer: return String(localized: "Computer", comment: "Device type")
        case .unknown: return String(localized: "Device", comment: "Device type")
        }
    }
}
