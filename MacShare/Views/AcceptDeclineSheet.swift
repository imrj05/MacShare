import SwiftUI

struct AcceptDeclineSheet: View {
    let request: IncomingTransferRequest
    let onAccept: () -> Void
    let onDecline: () -> Void

    var fileLabel: String {
        if request.files.count == 1 {
            return request.files[0].name
        }
        return String(format: String(localized: "%d files", comment: "File count"), request.files.count)
    }

    var totalSize: String {
        ByteCountFormatter.string(fromByteCount: request.totalBytes, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: AppStyle.Spacing.large) {
            VStack(spacing: AppStyle.Spacing.small) {
                IconTile(systemName: "arrow.down", size: 60, isPulsing: true)
                VStack(spacing: 4) {
                    Text(request.device.name)
                        .font(AppFont.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(String(format: String(localized: "wants to send %@ • %@", comment: "Incoming transfer subtitle"), fileLabel, totalSize))
                        .font(AppFont.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                ForEach(request.files.prefix(5)) { file in
                    HStack(spacing: AppStyle.Spacing.small) {
                        Image(systemName: file.sfSymbolName)
                            .font(AppFont.icon(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 22)
                        Text(file.name)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: AppStyle.Spacing.xSmall)
                        Text(file.formattedSize)
                            .font(AppFont.callout)
                            .foregroundStyle(AppColors.textSecondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 6)
                }
                if request.files.count > 5 {
                    Text("+" + String(request.files.count - 5) + " " + String(localized: "more", comment: "More files"))
                        .font(AppFont.callout)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(AppStyle.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurface(cornerRadius: AppStyle.Radius.panel)

            VStack(spacing: 4) {
                Text(String(localized: "PIN CODE", comment: "PIN label"))
                    .font(AppStyle.Typography.metadataEmphasis)
                    .foregroundStyle(AppColors.textSecondary)
                    .tracking(1.4)
                Text(request.pinCode)
                    .font(AppFont.pinCode)
                    .foregroundStyle(AppColors.textPrimary)
                    .contentTransition(.numericText())
            }

            HStack(spacing: AppStyle.Spacing.small) {
                Button {
                    onDecline()
                } label: {
                    Text(String(localized: "Decline", comment: "Decline button"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppButtonStyle(variant: .secondary, isCapsule: true, size: .large))

                Button {
                    onAccept()
                } label: {
                    Text(String(localized: "Accept", comment: "Accept button"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AppButtonStyle(variant: .primary, isCapsule: true, size: .large))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppStyle.Spacing.large)
        .frame(width: 380)
        .background(AppColors.bgBase)
    }
}
