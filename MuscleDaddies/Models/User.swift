import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var avatarURL: String?
    var joinedAt: Date
    var groupId: String?
    var fcmToken: String?
    var stats: UserStats
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?
    var selectedTheme: Constants.CardTheme
    var classTheme: Constants.ClassTheme
    var selectedClass: Constants.MuscleClass
    var priorityPrimary: Constants.PriorityStat
    var prioritySecondary: Constants.PriorityStat
    var heightCm: Double?
    var weightKg: Double?
    var heightCategory: Constants.HeightCategory?
    var bodyType: Constants.BodyType?
    var goals: UserGoals?
    var pokesSent: Int

    init(
        id: String? = nil,
        displayName: String,
        avatarURL: String? = nil,
        joinedAt: Date = Date(),
        groupId: String? = nil,
        fcmToken: String? = nil,
        stats: UserStats = UserStats(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastWorkoutDate: Date? = nil,
        selectedTheme: Constants.CardTheme = .modern,
        classTheme: Constants.ClassTheme = .fantasy,
        selectedClass: Constants.MuscleClass = .warrior,
        priorityPrimary: Constants.PriorityStat = .strength,
        prioritySecondary: Constants.PriorityStat = .endurance,
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        heightCategory: Constants.HeightCategory? = nil,
        bodyType: Constants.BodyType? = nil,
        goals: UserGoals? = nil,
        pokesSent: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.joinedAt = joinedAt
        self.groupId = groupId
        self.fcmToken = fcmToken
        self.stats = stats
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.selectedTheme = selectedTheme
        self.classTheme = classTheme
        self.selectedClass = selectedClass
        self.priorityPrimary = priorityPrimary
        self.prioritySecondary = prioritySecondary
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.heightCategory = heightCategory
        self.bodyType = bodyType
        self.goals = goals
        self.pokesSent = pokesSent
    }

    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case avatarURL
        case joinedAt
        case groupId
        case fcmToken
        case stats
        case currentStreak
        case longestStreak
        case lastWorkoutDate
        case selectedTheme
        case classTheme
        case selectedClass
        case priorityPrimary
        case prioritySecondary
        case heightCm
        case weightKg
        case heightCategory
        case bodyType
        case goals
        case pokesSent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? Date()
        groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        stats = try container.decodeIfPresent(UserStats.self, forKey: .stats) ?? UserStats()
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        lastWorkoutDate = try container.decodeIfPresent(Date.self, forKey: .lastWorkoutDate)
        selectedTheme = try container.decodeIfPresent(Constants.CardTheme.self, forKey: .selectedTheme) ?? .modern
        classTheme = try container.decodeIfPresent(Constants.ClassTheme.self, forKey: .classTheme) ?? .fantasy
        selectedClass = try container.decodeIfPresent(Constants.MuscleClass.self, forKey: .selectedClass) ?? .warrior
        priorityPrimary = try container.decodeIfPresent(Constants.PriorityStat.self, forKey: .priorityPrimary) ?? .strength
        prioritySecondary = try container.decodeIfPresent(Constants.PriorityStat.self, forKey: .prioritySecondary) ?? .endurance
        heightCm = try container.decodeIfPresent(Double.self, forKey: .heightCm)
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        heightCategory = try container.decodeIfPresent(Constants.HeightCategory.self, forKey: .heightCategory)
        bodyType = try container.decodeIfPresent(Constants.BodyType.self, forKey: .bodyType)
        goals = try container.decodeIfPresent(UserGoals.self, forKey: .goals)
        pokesSent = try container.decodeIfPresent(Int.self, forKey: .pokesSent) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try container.encode(stats, forKey: .stats)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encodeIfPresent(lastWorkoutDate, forKey: .lastWorkoutDate)
        try container.encode(selectedTheme, forKey: .selectedTheme)
        try container.encode(classTheme, forKey: .classTheme)
        try container.encode(selectedClass, forKey: .selectedClass)
        try container.encode(priorityPrimary, forKey: .priorityPrimary)
        try container.encode(prioritySecondary, forKey: .prioritySecondary)
        try container.encodeIfPresent(heightCm, forKey: .heightCm)
        try container.encodeIfPresent(weightKg, forKey: .weightKg)
        try container.encodeIfPresent(heightCategory, forKey: .heightCategory)
        try container.encodeIfPresent(bodyType, forKey: .bodyType)
        try container.encodeIfPresent(goals, forKey: .goals)
        try container.encode(pokesSent, forKey: .pokesSent)
    }
}

struct UserGoals: Codable {
    var targetSpeedMph: Double?
    var targetWeeklyDistanceMiles: Double?
    var targetStrengthChecksPerLevel: Int?

    init(
        targetSpeedMph: Double? = nil,
        targetWeeklyDistanceMiles: Double? = nil,
        targetStrengthChecksPerLevel: Int? = nil
    ) {
        self.targetSpeedMph = targetSpeedMph
        self.targetWeeklyDistanceMiles = targetWeeklyDistanceMiles
        self.targetStrengthChecksPerLevel = targetStrengthChecksPerLevel
    }
}

struct UserStats: Codable {
    var strength: Double
    var speed: Double
    var endurance: Double
    var intelligence: Double
    var level: Int
    var xpCurrent: Double
    var xpToNext: Double
    var totalXP: Double
    var hpCurrent: Double
    var hpMax: Double
    var xpMultiplier: Double

    init(
        strength: Double = 0,
        speed: Double = 0,
        endurance: Double = 0,
        intelligence: Double = 0,
        level: Int = 1,
        xpCurrent: Double = 0,
        xpToNext: Double = 100,
        totalXP: Double = 0,
        hpCurrent: Double = 100,
        hpMax: Double = 100,
        xpMultiplier: Double = 1.0
    ) {
        self.strength = strength
        self.speed = speed
        self.endurance = endurance
        self.intelligence = intelligence
        self.level = level
        self.xpCurrent = xpCurrent
        self.xpToNext = xpToNext
        self.totalXP = totalXP
        self.hpCurrent = hpCurrent
        self.hpMax = hpMax
        self.xpMultiplier = xpMultiplier
    }

    var overall: Double {
        (strength + speed + endurance + intelligence) / 4.0
    }

    var xpProgress: Double {
        guard xpToNext > 0 else { return 0 }
        return min(max(xpCurrent / xpToNext, 0), 1)
    }

    enum CodingKeys: String, CodingKey {
        case strength, speed, endurance, intelligence, level, xpCurrent, xpToNext, totalXP, hpCurrent, hpMax, xpMultiplier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strength = try container.decodeIfPresent(Double.self, forKey: .strength) ?? 0
        speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? 0
        endurance = try container.decodeIfPresent(Double.self, forKey: .endurance) ?? 0
        intelligence = try container.decodeIfPresent(Double.self, forKey: .intelligence) ?? 0
        level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        xpCurrent = try container.decodeIfPresent(Double.self, forKey: .xpCurrent) ?? 0
        xpToNext = try container.decodeIfPresent(Double.self, forKey: .xpToNext) ?? 100
        totalXP = try container.decodeIfPresent(Double.self, forKey: .totalXP) ?? 0
        hpCurrent = try container.decodeIfPresent(Double.self, forKey: .hpCurrent) ?? 100
        hpMax = try container.decodeIfPresent(Double.self, forKey: .hpMax) ?? 100
        xpMultiplier = try container.decodeIfPresent(Double.self, forKey: .xpMultiplier) ?? 1.0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(strength, forKey: .strength)
        try container.encode(speed, forKey: .speed)
        try container.encode(endurance, forKey: .endurance)
        try container.encode(intelligence, forKey: .intelligence)
        try container.encode(level, forKey: .level)
        try container.encode(xpCurrent, forKey: .xpCurrent)
        try container.encode(xpToNext, forKey: .xpToNext)
        try container.encode(totalXP, forKey: .totalXP)
        try container.encode(hpCurrent, forKey: .hpCurrent)
        try container.encode(hpMax, forKey: .hpMax)
        try container.encode(xpMultiplier, forKey: .xpMultiplier)
    }
}
