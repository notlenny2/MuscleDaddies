import Foundation

struct CharacterCard {
    let user: AppUser

    var strengthDisplay: Int { min(99, Int(user.stats.strength)) }
    var speedDisplay: Int { min(99, Int(user.stats.speed)) }
    var enduranceDisplay: Int { min(99, Int(user.stats.endurance)) }
    var intelligenceDisplay: Int { min(99, Int(user.stats.intelligence)) }
    var levelDisplay: Int { user.stats.level }
    var overallDisplay: Int { min(99, Int(user.stats.overall)) }
    var xpCurrentDisplay: Int { max(0, Int(user.stats.xpCurrent.rounded())) }
    var xpToNextDisplay: Int { max(1, Int(user.stats.xpToNext.rounded())) }
    var xpProgress: Double { user.stats.xpProgress }
    var hpCurrentDisplay: Int { max(0, Int(user.stats.hpCurrent.rounded())) }
    var hpMaxDisplay: Int { max(1, Int(user.stats.hpMax.rounded())) }
    var hpProgress: Double {
        guard user.stats.hpMax > 0 else { return 0 }
        return min(max(user.stats.hpCurrent / user.stats.hpMax, 0), 1)
    }

    var title: String {
        let level = user.stats.level
        switch level {
        case 0..<5: return "Couch Potato"
        case 5..<10: return "Gym Curious"
        case 10..<20: return "Regular"
        case 20..<30: return "Dedicated"
        case 30..<40: return "Athlete"
        case 40..<50: return "Muscle Daddy"
        default: return "Legendary Daddy"
        }
    }

    var dominantStat: Constants.StatCategory {
        let stats: [(Constants.StatCategory, Double)] = [
            (.strength, user.stats.strength),
            (.speed, user.stats.speed),
            (.endurance, user.stats.endurance),
            (.intelligence, user.stats.intelligence)
        ]
        return stats.max(by: { $0.1 < $1.1 })?.0 ?? .strength
    }
}
