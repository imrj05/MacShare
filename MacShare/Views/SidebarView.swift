import AppKit
import SwiftUI

struct SidebarView: View {
    @Environment(MacShareStore.self) private var store
    @State private var pendingURLs: [URL] = []
    @State private var showingDevicePicker = false
    @State private var showingNoDevicesAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
            sendButton
            navigation
            Spacer(minLength: AppStyle.Spacing.large)
            statusFooter
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.bgSidebar)
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

    // MARK: - Brand

    private var brand: some View {
        HStack(spacing: 11) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("Mac Share")
                    .font(AppFont.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text(String(localized: "Nearby transfer", comment: "Sidebar brand subtitle"))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, AppStyle.Layout.sidebarTopInset)
        .padding(.bottom, 22)
    }

    // MARK: - Primary action

    private var sendButton: some View {
        Button {
            chooseAndSend()
        } label: {
            Label(String(localized: "Send Files", comment: "Sidebar primary action"), systemImage: "paperplane.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(AppButtonStyle(variant: .primary, isCapsule: true, size: .large))
        .padding(.horizontal, 16)
        .padding(.bottom, AppStyle.Spacing.large)
    }

    // MARK: - Navigation

    private var navigation: some View {
        VStack(spacing: 3) {
            ForEach(Section.allCases) { section in
                SidebarRow(
                    title: section.title,
                    systemImage: section.sfSymbolName,
                    isSelected: store.selectedSection == section,
                    badge: badgeCount(for: section)
                ) {
                    store.selectedSection = section
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func badgeCount(for section: Section) -> Int? {
        switch section {
        case .devices:
            return store.discoveredDevices.isEmpty ? nil : store.discoveredDevices.count
        case .transfers:
            return store.recentTransfers.isEmpty ? nil : store.recentTransfers.count
        case .settings, .about:
            return nil
        }
    }

    // MARK: - Status footer

    private var statusFooter: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Circle()
                    .fill(store.isDiscoverable ? AppColors.tagSuccessText : AppColors.textTertiary)
                    .frame(width: 8, height: 8)
                Text(store.isDiscoverable
                     ? String(localized: "Visible to nearby devices", comment: "Visibility state")
                     : String(localized: "Hidden from nearby devices", comment: "Visibility state"))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }

            HStack(spacing: 6) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
                Text(deviceCountText)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppStyle.Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurface()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var deviceCountText: String {
        let count = store.discoveredDevices.count
        if count == 0 {
            return String(localized: "Searching for devices…", comment: "Sidebar device count")
        }
        return String(format: String(localized: "%d nearby", comment: "Sidebar device count"), count)
    }

    // MARK: - Actions

    private func chooseAndSend() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = String(localized: "Send", comment: "Open panel prompt")
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        guard urls.isEmpty == false else { return }

        pendingURLs = urls
        if store.discoveredDevices.isEmpty {
            showingNoDevicesAlert = true
        } else {
            showingDevicePicker = true
        }
    }
}

private struct SidebarRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .symbolEffect(.bounce, value: isSelected)

                Text(title)
                    .font(AppFont.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

                Spacer(minLength: 8)

                if let badge {
                    Text(String(badge))
                        .font(AppFont.captionMedium)
                        .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppColors.bgElevated, in: Capsule())
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 10)
            .frame(height: AppStyle.Layout.sidebarItemHeight)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
            .animation(.easeOut(duration: 0.16), value: isSelected)
            .animation(.snappy(duration: 0.25), value: badge)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var rowBackground: Color {
        if isSelected { return AppColors.selectionBg }
        if isHovering { return AppColors.bgHover }
        return .clear
    }
}
