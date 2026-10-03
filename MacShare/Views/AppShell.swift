import AppKit
import SwiftUI

struct AppShell: View {
    @Environment(MacShareStore.self) private var store
    @State private var activeRequest: IncomingTransferRequest?

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(width: AppStyle.Layout.sidebarWidth)

            Rectangle()
                .fill(AppColors.borderSubtle)
                .frame(width: 1)

            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.bgBase)
        .frame(
            minWidth: AppStyle.Layout.sidebarWidth + AppStyle.Layout.detailMinWidth,
            minHeight: AppStyle.Layout.detailMinHeight
        )
        .onChange(of: store.incomingRequest) {
            activeRequest = store.incomingRequest
        }
        .sheet(item: $activeRequest) { request in
            AcceptDeclineSheet(request: request) {
                store.acceptIncomingTransfer()
                activeRequest = nil
            } onDecline: {
                store.declineIncomingTransfer()
                activeRequest = nil
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch store.selectedSection {
        case .devices:
            DevicesView()
        case .transfers:
            TransfersView()
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        }
    }
}

struct MenuBarPopoverView: View {
    @Environment(MacShareStore.self) private var store
    let onOpenMain: () -> Void
    let onOpenSettings: () -> Void

    @State private var pendingURLs: [URL] = []
    @State private var showingDevicePicker = false
    @State private var isDropTarget = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(AppColors.borderSubtle)
            ScrollView {
                VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
                    dropZone
                    if store.activeTransfers.isEmpty == false {
                        activeTransfersSection
                    }
                    if store.discoveredDevices.isEmpty == false {
                        devicesSection
                    }
                    if store.recentTransfers.isEmpty == false {
                        recentTransfersSection
                    }
                }
                .padding(AppStyle.Spacing.medium)
            }
            .frame(maxHeight: 430)
            Divider().overlay(AppColors.borderSubtle)
            footer
        }
        .frame(width: 360)
        .background(AppColors.bgBase)
        .confirmationDialog(
            String(localized: "Send to Nearby Device", comment: "Menu bar device picker title"),
            isPresented: $showingDevicePicker,
            titleVisibility: .visible
        ) {
            ForEach(store.discoveredDevices) { device in
                Button(device.name) {
                    store.sendFiles(pendingURLs, to: device)
                    pendingURLs = []
                }
            }
            Button(String(localized: "Cancel", comment: "Cancel"), role: .cancel) {
                pendingURLs = []
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text("Mac Share")
                .font(AppFont.headline)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(store.isDiscoverable ? AppColors.tagSuccessText : AppColors.textTertiary)
                    .frame(width: 7, height: 7)
                Text(store.isDiscoverable ? String(localized: "Visible", comment: "Visibility state") : String(localized: "Hidden", comment: "Visibility state"))
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(AppColors.bgElevated, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Mac Share Settings")
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
    }

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isDropTarget ? AppColors.accent : AppColors.textSecondary)

            Text(String(localized: "Drop files to send", comment: "Menu bar drop zone"))
                .font(AppFont.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            isDropTarget ? AppColors.accentSoft : AppColors.bgCard,
            in: RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.card, style: .continuous)
                .strokeBorder(
                    isDropTarget ? AppColors.accent : AppColors.borderStrong,
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            handleDrop(urls)
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }

    private var activeTransfersSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
            SectionLabel(String(localized: "In Progress", comment: "Menu bar active transfers"))
            VStack(spacing: 6) {
                ForEach(store.activeTransfers.prefix(3)) { transfer in
                    MenuBarActiveTransferRow(transfer: transfer)
                }
            }
        }
    }

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
            SectionLabel(String(localized: "Nearby Devices", comment: "Menu bar nearby devices"))

            VStack(spacing: 4) {
                ForEach(store.discoveredDevices.prefix(4)) { device in
                    Button {
                        chooseFiles(for: device)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: device.sfSymbolName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppColors.accent)
                                .frame(width: 24, height: 24)
                                .background(AppColors.accentSoft, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                            VStack(alignment: .leading, spacing: 1) {
                                Text(device.name)
                                    .font(AppFont.subheadline.weight(.medium))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(deviceTypeLabel(device))
                                    .font(AppFont.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "paperplane")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppColors.bgCard, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentTransfersSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
            SectionLabel(String(localized: "Recent Transfers", comment: "Menu bar recent transfers"))

            VStack(spacing: 4) {
                ForEach(store.recentTransfers.prefix(3)) { transfer in
                    HStack(spacing: 10) {
                        Image(systemName: transfer.direction == .incoming ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(transfer.filename)
                                .font(AppFont.subheadline.weight(.medium))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                            Text(transfer.peerName + " • " + ByteCountFormatter.string(fromByteCount: transfer.totalBytes, countStyle: .file))
                                .font(AppFont.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()

                        Text(transfer.status.rawValue.capitalized)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(AppColors.bgCard, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: AppStyle.Spacing.xSmall) {
            Button {
                onOpenMain()
            } label: {
                Label(String(localized: "Open Mac Share", comment: "Menu bar open button"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AppButtonStyle(variant: .primary, isCapsule: true, size: .regular))

            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(AppColors.bgElevated, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Quit Mac Share")
        }
        .padding(.horizontal, AppStyle.Spacing.medium)
        .padding(.vertical, AppStyle.Spacing.small)
    }

    private func handleDrop(_ urls: [URL]) -> Bool {
        let validURLs = urls.filter { $0.isFileURL || $0.scheme == "http" || $0.scheme == "https" }
        guard validURLs.isEmpty == false else { return false }

        pendingURLs = validURLs

        if store.discoveredDevices.count == 1, let device = store.discoveredDevices.first {
            store.sendFiles(validURLs, to: device)
            pendingURLs = []
        } else if store.discoveredDevices.isEmpty == false {
            showingDevicePicker = true
        } else {
            store.selectedSection = .devices
            onOpenMain()
        }
        return true
    }

    private func chooseFiles(for device: DiscoveredDevice) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        if panel.runModal() == .OK {
            store.sendFiles(panel.urls, to: device)
        }
    }

    private func deviceTypeLabel(_ device: DiscoveredDevice) -> String {
        switch device.deviceType {
        case .phone: return String(localized: "Phone", comment: "Device type")
        case .tablet: return String(localized: "Tablet", comment: "Device type")
        case .computer: return String(localized: "Computer", comment: "Device type")
        case .unknown: return String(localized: "Device", comment: "Device type")
        }
    }
}

/// Compact live progress row shown in the menu bar popover.
private struct MenuBarActiveTransferRow: View {
    @Environment(MacShareStore.self) private var store
    let transfer: ActiveTransfer

    private var progress: Double {
        min(max(transfer.progress, 0), 1)
    }

    private var percentString: String {
        String(Int(progress * 100)) + "%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Image(systemName: transfer.direction == .incoming ? "arrow.down" : "arrow.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText)
                    .frame(width: 24, height: 24)
                    .background(
                        (transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText).opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                    )

                Text(transfer.filename)
                    .font(AppFont.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(percentString)
                    .font(AppFont.captionMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: progress)

                Button {
                    store.cancelTransfer(id: transfer.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 20, height: 20)
                        .background(AppColors.bgElevated, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(String(localized: "Cancel transfer", comment: "Cancel transfer help"))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.bgElevated)
                    Capsule()
                        .fill(AppColors.accent)
                        .frame(width: max(3, proxy.size.width * CGFloat(progress)))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(AppColors.bgCard, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
    }
}
