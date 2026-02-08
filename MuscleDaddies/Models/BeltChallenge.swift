import Foundation
import FirebaseFirestore

struct BeltChallenge: Codable, Identifiable {
    enum Status: String, Codable {
        case pending
        case active
        case declined
        case completed
        case expired
    }

    enum BeltStat: String, CaseIterable, Codable {
        case strength
        case speed
        case endurance
        case intelligence
        case overall

        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .speed: return "Speed"
            case .endurance: return "Endurance"
            case .intelligence: return "Mobility"
            case .overall: return "Overall"
            }
        }
    }

    @DocumentID var id: String?
    var groupId: String
    var challengerId: String
    var opponentId: String
    var stat: BeltStat
    var status: Status
    var durationDays: Int
    var startDate: Date?
    var endDate: Date?
    var createdAt: Date
    var acceptedAt: Date?
    var winnerId: String?
    var challengerScore: Double?
    var opponentScore: Double?

    var isActive: Bool {
        guard status == .active, let startDate, let endDate else { return false }
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

struct BeltHolders: Codable {
    var strengthHolderId: String?
    var speedHolderId: String?
    var enduranceHolderId: String?
    var intelligenceHolderId: String?
    var overallHolderId: String?
    var updatedAt: Date?
}
