import Foundation

enum TransferDirection: String, Codable {
    case incoming
    case outgoing
}

enum TransferStatus: String, Codable {
    case active
    case completed
    case failed
    case declined
    case cancelled
}

struct TransferRecord: Identifiable, Codable {
    let id: String
    let filename: String
    let fileCount: Int
    let totalBytes: Int64
    let direction: TransferDirection
    let peerName: String
    let peerIcon: String
    let timestamp: Date
    let status: TransferStatus
    var savedPath: URL?

    init(
        id: String,
        filename: String,
        fileCount: Int,
        totalBytes: Int64,
        direction: TransferDirection,
        peerName: String,
        peerIcon: String,
        timestamp: Date,
        status: TransferStatus,
        savedPath: URL? = nil
    ) {
        self.id = id
        self.filename = filename
        self.fileCount = fileCount
        self.totalBytes = totalBytes
        self.direction = direction
        self.peerName = peerName
        self.peerIcon = peerIcon
        self.timestamp = timestamp
        self.status = status
        self.savedPath = savedPath
    }
}
