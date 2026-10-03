import Foundation
import SwiftUI

struct DiscoveredDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let deviceType: DeviceType
    var isBusy: Bool = false

    var sfSymbolName: String {
        switch deviceType {
        case .phone: return "iphone"
        case .tablet: return "ipad"
        case .computer: return "laptopcomputer"
        case .unknown: return "desktopcomputer"
        }
    }
}

enum DeviceType {
    case phone, tablet, computer, unknown
}

enum IncomingTransferDecision {
    case pending
    case accepted
    case declined
}

struct IncomingTransferRequest: Identifiable, Equatable {
    static func == (lhs: IncomingTransferRequest, rhs: IncomingTransferRequest) -> Bool {
        lhs.id == rhs.id
    }
    let id = UUID()
    let transferID: String
    let device: DiscoveredDevice
    let files: [FileInfo]
    let pinCode: String
    let totalBytes: Int64
    var decision: IncomingTransferDecision = .pending
    var countdownRemaining: TimeInterval = 30

    var displayName: String {
        if files.count == 1 {
            return files[0].name
        }
        if files.count > 1 {
            return String(format: String(localized: "%d files", comment: "File count"), files.count)
        }
        return String(localized: "Link", comment: "URL transfer")
    }
}

struct FileInfo: Identifiable {
    let id = UUID().uuidString
    let name: String
    let size: Int64
    var savedURL: URL? = nil

    var sfSymbolName: String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case let e where ["jpg", "jpeg", "png", "gif", "bmp", "webp", "heic", "svg"].contains(e):
            return "photo"
        case let e where ["mp4", "mov", "avi", "mkv", "webm"].contains(e):
            return "video"
        case let e where ["mp3", "wav", "flac", "aac", "ogg", "m4a"].contains(e):
            return "music.note"
        case let e where ["pdf", "doc", "docx", "txt", "rtf"].contains(e):
            return "doc"
        case let e where ["zip", "tar", "gz", "rar", "7z"].contains(e):
            return "archivebox"
        default:
            return "doc.badge.gearshape"
        }
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
