import Foundation
import FirebaseFirestore

struct Achievement: Codable, Identifiable {
    @DocumentID var id: String?
    var achievementType: Constants.AchievementType
    var unlockedAt: Date

    init(achievementType: Constants.AchievementType, unlockedAt: Date = Date()) {
        self.achievementType = achievementType
        self.unlockedAt = unlockedAt
    }
}
