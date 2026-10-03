import AppKit
import SwiftUI

struct TransfersView: View {
    @Environment(MacShareStore.self) private var store
    @State private var searchQuery = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                header

                if store.activeTransfers.isEmpty == false {
                    activeSection
                }

                listSection
            }
            .padding(.horizontal, AppStyle.Layout.contentInset)
            .padding(.top, AppStyle.Layout.detailTopInset)
            .padding(.bottom, AppStyle.Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.bgBase)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.medium) {
            HStack(alignment: .center, spacing: AppStyle.Spacing.medium) {
                PageHeader(title: String(localized: "Transfers", comment: "Transfers page title"), subtitle: transfersSubtitle)
                Spacer(minLength: AppStyle.Spacing.medium)
                searchField
            }

            filterRow
        }
    }

    private var transfersSubtitle: String {
        let count = visibleTransfers.count
        if count == 0 {
            return String(localized: "Files you send or receive will appear here", comment: "Transfers subtitle")
        }
        return String(format: String(localized: "%d transfers", comment: "Transfers subtitle"), count)
    }

    private var searchField: some View {
        HStack(spacing: AppStyle.Spacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)

            TextField(String(localized: "Search transfers", comment: "Search placeholder"), text: $searchQuery)
                .textFieldStyle(.plain)
                .font(AppFont.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            if searchQuery.isEmpty == false {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppStyle.Spacing.small)
        .frame(width: 220, height: 32)
        .background(AppColors.bgInput, in: Capsule())
        .overlay(Capsule().strokeBorder(AppColors.borderSubtle, lineWidth: 1))
    }

    private var filterRow: some View {
        HStack(spacing: AppStyle.Spacing.xSmall) {
            ForEach(TransferFilter.allCases) { filter in
                FilterChip(
                    title: filter.title,
                    isSelected: store.transferFilter == filter,
                    symbolName: filter.sfSymbolName,
                    count: count(for: filter),
                    tagType: filter.tagType
                ) {
                    store.transferFilter = filter
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func count(for filter: TransferFilter) -> Int? {
        let all = store.recentTransfers
        switch filter {
        case .all: return all.isEmpty ? nil : all.count
        case .completed: return all.filter { $0.status == .completed }.count
        case .failed: return all.filter { $0.status == .failed }.count
        case .declined: return all.filter { $0.status == .declined }.count
        case .cancelled: return all.filter { $0.status == .cancelled }.count
        }
    }

    // MARK: - Active transfers

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            SectionLabel(String(localized: "In Progress", comment: "Active transfers section"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppStyle.Spacing.small) {
                    ForEach(store.activeTransfers) { transfer in
                        TransferProgressCard(transfer: transfer)
                            .frame(width: 320)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private var listSection: some View {
        if visibleTransfers.isEmpty {
            if store.activeTransfers.isEmpty {
                emptyState
            }
        } else {
            VStack(alignment: .leading, spacing: AppStyle.Spacing.large) {
                ForEach(groupedTransfers) { group in
                    VStack(alignment: .leading, spacing: AppStyle.Spacing.xSmall) {
                        SectionLabel(group.label)

                        AppCard(padding: 6) {
                            VStack(spacing: 2) {
                                ForEach(group.items) { transfer in
                                    TransferRowView(transfer: transfer)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppStyle.Spacing.medium) {
            IconTile(systemName: "tray", size: 68)
            VStack(spacing: 6) {
                Text(String(localized: "No Transfers", comment: "Transfers empty title"))
                    .font(AppFont.title3)
                    .foregroundStyle(AppColors.textPrimary)
                Text(String(localized: "Files you send or receive will appear here.", comment: "Transfers empty description"))
                    .font(AppFont.body)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 380)
    }

    private var visibleTransfers: [TransferRecord] {
        let base = store.filteredTransfers
        guard searchQuery.isEmpty == false else { return base }
        return base.filter { transfer in
            transfer.filename.localizedCaseInsensitiveContains(searchQuery) ||
            transfer.peerName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private struct TransferGroup: Identifiable {
        let id = UUID()
        let label: String
        let items: [TransferRecord]
    }

    private var groupedTransfers: [TransferGroup] {
        let grouped = Dictionary(grouping: visibleTransfers) { record in
            Calendar.current.isDate(record.timestamp, inSameDayAs: Date())
                ? String(localized: "Today", comment: "Date group")
                : Calendar.current.isDate(record.timestamp, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
                ? String(localized: "Yesterday", comment: "Date group")
                : record.timestamp.formatted(date: .abbreviated, time: .omitted)
        }
        return grouped.map { TransferGroup(label: $0.key, items: $0.value) }
            .sorted { $0.label < $1.label }
    }
}

struct TransferRowView: View {
    @Environment(MacShareStore.self) private var store
    let transfer: TransferRecord

    @State private var isHovering = false

    private var directionLabel: String {
        if transfer.direction == .incoming {
            return String(format: String(localized: "Received from %@", comment: "Incoming transfer detail"), transfer.peerName)
        }
        return String(format: String(localized: "Sent to %@", comment: "Outgoing transfer detail"), transfer.peerName)
    }

    var body: some View {
        HStack(spacing: AppStyle.Spacing.small) {
            Image(systemName: transfer.direction == .incoming ? "arrow.down" : "arrow.up")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText)
                .frame(width: 32, height: 32)
                .background(
                    (transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText).opacity(0.14),
                    in: RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.filename)
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(directionLabel)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppStyle.Spacing.small)

            Text(ByteCountFormatter.string(fromByteCount: transfer.totalBytes, countStyle: .file))
                .font(AppFont.caption)
                .foregroundStyle(AppColors.textTertiary)
                .monospacedDigit()

            statusBadge
        }
        .padding(.horizontal, AppStyle.Spacing.small)
        .padding(.vertical, 9)
        .background(isHovering ? AppColors.bgElevated : Color.clear, in: RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.Radius.control, style: .continuous))
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            if transfer.status == .completed, let path = transfer.savedPath {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([path])
                } label: {
                    Label(String(localized: "Show in Finder", comment: "Context menu"), systemImage: "folder")
                }
            }
            Button(role: .destructive) {
                store.removeTransferRecord(id: transfer.id)
            } label: {
                Label(String(localized: "Remove", comment: "Context menu"), systemImage: "trash")
            }
        }
    }

    private var statusBadge: some View {
        switch transfer.status {
        case .completed:
            AppBadge(title: String(localized: "Completed", comment: "Transfer status"), tagType: .success, showDot: false)
        case .failed:
            AppBadge(title: String(localized: "Failed", comment: "Transfer status"), tagType: .danger, showDot: false)
        case .declined:
            AppBadge(title: String(localized: "Declined", comment: "Transfer status"), tagType: .neutral, showDot: false)
        case .active:
            AppBadge(title: String(localized: "Active", comment: "Transfer status"), tagType: .warning, showDot: false)
        case .cancelled:
            AppBadge(title: String(localized: "Cancelled", comment: "Transfer status"), tagType: .neutral, showDot: false)
        }
    }
}
