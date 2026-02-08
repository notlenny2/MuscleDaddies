import Foundation
import FirebaseFirestore

struct Challenge: Codable, Identifiable {
    @DocumentID var id: String?
    var groupId: String
    var title: String
    var description: String
    var metric: String
    var startDate: Date
    var endDate: Date
    var participants: [String: Double] // userId: progressValue
    var winnerId: String?

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var isCompleted: Bool {
        Date() > endDate
    }
}
