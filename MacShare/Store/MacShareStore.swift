import AppKit
import Foundation
import SwiftUI
import MacShareKit

@Observable
class MacShareStore: ShareExtensionDelegate {
    var discoveredDevices: [DiscoveredDevice] = []
    var activeTransfers: [ActiveTransfer] = []
    var recentTransfers: [TransferRecord] = []
    var incomingRequest: IncomingTransferRequest? = nil

    var appearanceMode: AppearanceMode = .dark
    var deviceName: String = ""
    var isDiscoverable: Bool = true
    var saveFolder: URL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
    var showMenuBarIcon: Bool = true
    var launchAtLogin: Bool = false

    var selectedSection: Section = .devices
    var transferFilter: TransferFilter = .all

    private let transferHistoryKey = "macShareTransferHistory"
    static let appearanceKey = "macShareAppearanceMode"
    private var cancelledTransferIDs: Set<String> = []
    private var deviceMap: [String: DiscoveredDevice] = [:]
    private var pendingOutgoingTransfer: PendingOutgoingTransfer?
    private var pendingIncomingRequests: [String: IncomingTransferRequest] = [:]

    init() {
        appearanceMode = Self.persistedAppearanceMode
        deviceName = Host.current().localizedName ?? "My Mac"
        loadTransferHistory()
        NearbyConnectionManager.shared.addShareExtensionDelegate(self)
        NearbyConnectionManager.shared.startDeviceDiscovery()
    }

    deinit {
        NearbyConnectionManager.shared.removeShareExtensionDelegate(self)
        NearbyConnectionManager.shared.stopDeviceDiscovery()
    }

    // MARK: - Appearance

    static var persistedAppearanceMode: AppearanceMode {
        UserDefaults.standard.string(forKey: appearanceKey)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .dark
    }

    /// Drives appearance through AppKit so custom dynamic colors and SwiftUI
    /// semantic colors always agree. A nil value restores the real System look.
    func applyAppearance() {
        UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.appearanceKey)
        let appearance = appearanceMode.nsAppearance
        NSApp.appearance = appearance
        for window in NSApp.windows {
            window.appearance = appearance
        }
    }

    // MARK: - ShareExtensionDelegate

    func addDevice(device: RemoteDeviceInfo) {
        let discovered = DiscoveredDevice(
            id: device.id ?? UUID().uuidString,
            name: device.name,
            deviceType: mapDeviceType(device.type)
        )
        DispatchQueue.main.async {
            self.deviceMap[discovered.id] = discovered
            self.discoveredDevices = Array(self.deviceMap.values)
        }
    }

    func removeDevice(id: String) {
        DispatchQueue.main.async {
            self.deviceMap.removeValue(forKey: id)
            self.discoveredDevices = Array(self.deviceMap.values)
        }
    }

    func startTransferWithQrCode(device: RemoteDeviceInfo) {
        // QR pairing is still handled by the Share Extension. In the main
        // app, make sure the device is visible in the Devices tab.
        selectedSection = .devices
    }

    func connectionWasEstablished(pinCode: String) {
        DispatchQueue.main.async {
            guard let id = self.pendingOutgoingTransfer?.id,
                  let index = self.activeTransfers.firstIndex(where: { $0.id == id }) else { return }
            self.activeTransfers[index].pinCode = pinCode
            self.activeTransfers[index].statusText = String(localized: "Waiting for approval", comment: "Transfer status")
        }
    }

    func connectionFailed(with error: Error) {
        DispatchQueue.main.async {
            self.finishOutgoingTransfer(status: .failed)
        }
    }

    func transferAccepted() {
        DispatchQueue.main.async {
            guard let id = self.pendingOutgoingTransfer?.id,
                  let index = self.activeTransfers.firstIndex(where: { $0.id == id }) else { return }
            self.activeTransfers[index].statusText = String(localized: "Sending", comment: "Transfer status")
        }
    }

    func transferProgress(progress: Double) {
        DispatchQueue.main.async {
            guard let pending = self.pendingOutgoingTransfer,
                  let index = self.activeTransfers.firstIndex(where: { $0.id == pending.id }) else { return }

            let elapsed = max(Date().timeIntervalSince(pending.startedAt), 0.1)
            let transferred = Int64(Double(pending.totalBytes) * progress)
            let speed = Double(transferred) / elapsed
            let remaining = max(Double(pending.totalBytes - transferred), 0)

            self.activeTransfers[index].progress = progress
            self.activeTransfers[index].bytesTransferred = transferred
            self.activeTransfers[index].speedBytesPerSec = speed
            self.activeTransfers[index].etaSeconds = speed > 0 ? remaining / speed : 0
        }
    }

    func transferFinished() {
        DispatchQueue.main.async {
            self.finishOutgoingTransfer(status: .completed)
        }
    }

    func refreshDiscovery() {
        NearbyConnectionManager.shared.stopDeviceDiscovery()
        discoveredDevices = []
        deviceMap.removeAll()
        NearbyConnectionManager.shared.startDeviceDiscovery()
    }

    // MARK: - Outgoing transfers

    func sendFiles(_ urls: [URL], to device: DiscoveredDevice) {
        guard pendingOutgoingTransfer == nil else { return }
        let validURLs = urls.filter { $0.isFileURL || $0.scheme == "http" || $0.scheme == "https" }
        guard validURLs.count > 0 else { return }

        let totalBytes = validURLs.reduce(Int64(0)) { partialResult, url in
            partialResult + fileSize(for: url)
        }
        let transferID = UUID().uuidString
        let transfer = ActiveTransfer(
            id: transferID,
            filename: Self.displayName(for: validURLs),
            fileCount: validURLs.count,
            totalBytes: totalBytes,
            direction: .outgoing,
            peerName: device.name
        )

        activeTransfers.append(transfer)
        pendingOutgoingTransfer = PendingOutgoingTransfer(
            id: transferID,
            device: device,
            urls: validURLs,
            totalBytes: totalBytes,
            startedAt: Date()
        )
        setDevice(device.id, busy: true)
        NearbyConnectionManager.shared.startOutgoingTransfer(deviceID: device.id, delegate: self, urls: validURLs)
    }

    /// Cancels an in-flight transfer in either direction.
    func cancelTransfer(id: String) {
        guard activeTransfers.contains(where: { $0.id == id }) else { return }
        cancelledTransferIDs.insert(id)
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            activeTransfers[index].statusText = String(localized: "Cancelling…", comment: "Transfer status")
        }
        if let pending = pendingOutgoingTransfer, pending.id == id {
            NearbyConnectionManager.shared.cancelOutgoingTransfer(id: pending.device.id)
            return
        }
        NearbyConnectionManager.shared.cancelIncomingTransfer(id: id)
    }

    private func finishOutgoingTransfer(status: TransferStatus) {
        guard let pending = pendingOutgoingTransfer else { return }
        pendingOutgoingTransfer = nil
        activeTransfers.removeAll { $0.id == pending.id }
        setDevice(pending.device.id, busy: false)

        let finalStatus: TransferStatus = cancelledTransferIDs.remove(pending.id) != nil ? .cancelled : status

        let record = TransferRecord(
            id: pending.id,
            filename: Self.displayName(for: pending.urls),
            fileCount: pending.urls.count,
            totalBytes: pending.totalBytes,
            direction: .outgoing,
            peerName: pending.device.name,
            peerIcon: pending.device.sfSymbolName,
            timestamp: Date(),
            status: finalStatus
        )
        addTransferRecord(record)
    }

    private func setDevice(_ id: String, busy: Bool) {
        if var device = deviceMap[id] {
            device.isBusy = busy
            deviceMap[id] = device
        }
        discoveredDevices = Array(deviceMap.values).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func fileSize(for url: URL) -> Int64 {
        guard url.isFileURL else { return 0 }
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func displayName(for urls: [URL]) -> String {
        if urls.count == 1 {
            return urls[0].isFileURL ? urls[0].lastPathComponent : (urls[0].host ?? urls[0].absoluteString)
        }
        return String(format: String(localized: "%d files", comment: "File count"), urls.count)
    }

    // MARK: - Helpers

    private func mapDeviceType(_ type: RemoteDeviceInfo.DeviceType) -> DeviceType {
        switch type {
        case .phone: return .phone
        case .tablet: return .tablet
        case .computer: return .computer
        case .unknown: return .unknown
        }
    }

    // MARK: - Incoming Transfers

    func presentIncomingRequest(_ request: IncomingTransferRequest) {
        pendingIncomingRequests[request.transferID] = request
        incomingRequest = request
    }

    func acceptIncomingTransfer() {
        respondToIncoming(transferID: incomingRequest?.transferID, accept: true)
    }

    func declineIncomingTransfer() {
        respondToIncoming(transferID: incomingRequest?.transferID, accept: false)
    }

    func acceptIncomingTransfer(id: String) {
        respondToIncoming(transferID: id, accept: true)
    }

    func declineIncomingTransfer(id: String) {
        respondToIncoming(transferID: id, accept: false)
    }

    private func respondToIncoming(transferID: String?, accept: Bool) {
        guard let transferID else { return }
        if var request = pendingIncomingRequests[transferID] {
            request.decision = accept ? .accepted : .declined
            pendingIncomingRequests[transferID] = request

            if accept {
                selectedSection = .transfers
                activeTransfers.append(ActiveTransfer(
                    id: transferID,
                    filename: request.displayName,
                    fileCount: request.files.count,
                    totalBytes: request.totalBytes,
                    direction: .incoming,
                    peerName: request.device.name,
                    statusText: String(localized: "Receiving", comment: "Transfer status")
                ))
            }
        }
        NearbyConnectionManager.shared.submitUserConsent(transferID: transferID, accept: accept)
        if incomingRequest?.transferID == transferID {
            incomingRequest = nil
        }
    }

    func updateIncomingTransfer(id: String, progress: Double) {
        guard let index = activeTransfers.firstIndex(where: { $0.id == id }) else { return }
        activeTransfers[index].progress = progress
        activeTransfers[index].bytesTransferred = Int64(Double(activeTransfers[index].totalBytes) * progress)
        activeTransfers[index].statusText = String(localized: "Receiving", comment: "Transfer status")
    }

    func finishIncomingTransfer(id: String, error: Error?) {
        let request = pendingIncomingRequests.removeValue(forKey: id)
        var active: ActiveTransfer? = nil
        if let index = activeTransfers.firstIndex(where: { $0.id == id }) {
            active = activeTransfers.remove(at: index)
        }

        // If we have neither a pending request nor an active card there is nothing
        // to finalize — but still clear any matching consent prompt.
        guard request != nil || active != nil else {
            if incomingRequest?.transferID == id {
                incomingRequest = nil
            }
            return
        }

        let status: TransferStatus
        if cancelledTransferIDs.remove(id) != nil {
            status = .cancelled
        } else if error != nil {
            status = .failed
        } else if request?.decision == .declined {
            status = .declined
        } else {
            status = .completed
        }

        let record = TransferRecord(
            id: id,
            filename: request?.displayName ?? active?.filename ?? String(localized: "Transfer", comment: "Fallback transfer name"),
            fileCount: request?.files.count ?? active?.fileCount ?? 0,
            totalBytes: request?.totalBytes ?? active?.totalBytes ?? 0,
            direction: .incoming,
            peerName: request?.device.name ?? active?.peerName ?? "",
            peerIcon: request?.device.sfSymbolName ?? "desktopcomputer",
            timestamp: Date(),
            status: status,
            savedPath: request?.files.first?.savedURL
        )
        addTransferRecord(record)
        if incomingRequest?.transferID == id {
            incomingRequest = nil
        }
    }

    // MARK: - Transfer History

    func addTransferRecord(_ record: TransferRecord) {
        recentTransfers.insert(record, at: 0)
        saveTransferHistory()
    }

    func removeTransferRecord(id: String) {
        recentTransfers.removeAll { $0.id == id }
        saveTransferHistory()
    }

    var filteredTransfers: [TransferRecord] {
        switch transferFilter {
        case .all: return recentTransfers
        case .completed: return recentTransfers.filter { $0.status == .completed }
        case .failed: return recentTransfers.filter { $0.status == .failed }
        case .declined: return recentTransfers.filter { $0.status == .declined }
        case .cancelled: return recentTransfers.filter { $0.status == .cancelled }
        }
    }

    // MARK: - Persistence

    private func saveTransferHistory() {
        let data = try? JSONEncoder().encode(recentTransfers)
        if let data {
            UserDefaults.standard.set(data, forKey: transferHistoryKey)
        }
    }

    private func loadTransferHistory() {
        guard let data = UserDefaults.standard.data(forKey: transferHistoryKey),
              let records = try? JSONDecoder().decode([TransferRecord].self, from: data) else {
            return
        }
        recentTransfers = records
    }
}

// MARK: - Pending transfer

private struct PendingOutgoingTransfer {
    let id: String
    let device: DiscoveredDevice
    let urls: [URL]
    let totalBytes: Int64
    let startedAt: Date
}

// MARK: - Active Transfer

struct ActiveTransfer: Identifiable {
    let id: String
    let filename: String
    let fileCount: Int
    let totalBytes: Int64
    let direction: TransferDirection
    let peerName: String
    var progress: Double = 0
    var bytesTransferred: Int64 = 0
    var speedBytesPerSec: Double = 0
    var etaSeconds: Double = 0
    var pinCode: String?
    var statusText: String = "Connecting"
}

// MARK: - Enums

enum Section: String, CaseIterable, Identifiable, Hashable {
    case devices
    case transfers
    case settings
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .devices: return String(localized: "Devices", comment: "Sidebar section")
        case .transfers: return String(localized: "Transfers", comment: "Sidebar section")
        case .settings: return String(localized: "Settings", comment: "Sidebar section")
        case .about: return String(localized: "About", comment: "Sidebar section")
        }
    }

    var sfSymbolName: String {
        switch self {
        case .devices: return "antenna.radiowaves.left.and.right"
        case .transfers: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return String(localized: "System", comment: "Appearance mode")
        case .light: return String(localized: "Light", comment: "Appearance mode")
        case .dark: return String(localized: "Dark", comment: "Appearance mode")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

enum TransferFilter: String, CaseIterable, Identifiable {
    case all, completed, failed, declined, cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return String(localized: "All", comment: "Transfer filter")
        case .completed: return String(localized: "Completed", comment: "Transfer filter")
        case .failed: return String(localized: "Failed", comment: "Transfer filter")
        case .declined: return String(localized: "Declined", comment: "Transfer filter")
        case .cancelled: return String(localized: "Cancelled", comment: "Transfer filter")
        }
    }

    var sfSymbolName: String? {
        switch self {
        case .all: return nil
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .declined: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        }
    }

    var tagType: TagType {
        switch self {
        case .all: return .neutral
        case .completed: return .success
        case .failed: return .danger
        case .declined: return .neutral
        case .cancelled: return .neutral
        }
    }
}
