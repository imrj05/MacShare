import SwiftUI

struct TransferProgressCard: View {
    @Environment(MacShareStore.self) private var store
    let transfer: ActiveTransfer

    var progressFraction: Double {
        transfer.totalBytes > 0 ? min(max(transfer.progress, 0), 1) : 0
    }

    var percentString: String {
        String(Int((progressFraction * 100).rounded())) + "%"
    }

    var peerLine: String {
        let base = transfer.direction == .incoming
            ? String(format: String(localized: "From %@", comment: "Transfer source"), transfer.peerName)
            : String(format: String(localized: "To %@", comment: "Transfer destination"), transfer.peerName)
        guard transfer.fileCount > 1 else { return base }
        return base + " · " + String(format: String(localized: "%d files", comment: "File count"), transfer.fileCount)
    }

    var speedString: String {
        ByteCountFormatter.string(fromByteCount: Int64(transfer.speedBytesPerSec), countStyle: .file) + "/s"
    }

    var etaString: String {
        guard transfer.etaSeconds > 0 else { return "" }
        let minutes = Int(transfer.etaSeconds) / 60
        let seconds = Int(transfer.etaSeconds) % 60
        return String(format: String(localized: "%d:%02d", comment: "ETA format mm:ss"), minutes, seconds)
    }

    var byteProgressString: String {
        let transferred = ByteCountFormatter.string(fromByteCount: transfer.bytesTransferred, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: transfer.totalBytes, countStyle: .file)
        return String(format: String(localized: "%@ of %@", comment: "Transfer progress"), transferred, total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppStyle.Spacing.small) {
            HStack(spacing: AppStyle.Spacing.xSmall) {
                Image(systemName: transfer.direction == .incoming ? "arrow.down" : "arrow.up")
                    .font(AppFont.icon(size: 12, weight: .semibold))
                    .foregroundStyle(transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText)
                    .frame(width: 28, height: 28)
                    .background(
                        (transfer.direction == .incoming ? AppColors.accent : AppColors.tagSuccessText).opacity(0.14),
                        in: RoundedRectangle(cornerRadius: AppStyle.Radius.chip, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(transfer.filename)
                        .font(AppFont.callout.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(peerLine)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppStyle.Spacing.xSmall)

                Text(percentString)
                    .font(AppFont.captionMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.25), value: progressFraction)

                Button {
                    store.cancelTransfer(id: transfer.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(AppFont.icon(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 22, height: 22)
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
                        .frame(width: max(4, proxy.size.width * progressFraction))
                        .animation(.easeInOut(duration: 0.3), value: progressFraction)
                }
            }
            .frame(height: 6)

            HStack(spacing: AppStyle.Spacing.xSmall) {
                Text(transfer.statusText)
                    .font(AppStyle.Typography.metadata)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: AppStyle.Spacing.xSmall)

                if let pinCode = transfer.pinCode {
                    Text(String(format: String(localized: "PIN %@", comment: "Transfer PIN"), pinCode))
                        .font(AppStyle.Typography.metadataEmphasis)
                        .foregroundStyle(AppColors.accent)
                        .monospacedDigit()
                }
            }

            HStack {
                Text(transfer.speedBytesPerSec > 0 ? speedString : byteProgressString)
                    .font(AppStyle.Typography.metadata)
                    .foregroundStyle(AppColors.textTertiary)
                    .monospacedDigit()
                Spacer()
                if etaString.count > 0 {
                    Text(etaString)
                        .font(AppStyle.Typography.metadata)
                        .foregroundStyle(AppColors.textTertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(AppStyle.Spacing.medium)
        .appSurface()
    }
}
