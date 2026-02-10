import Foundation

class StatCalculator {
    /// Recalculate all stats for a user based on their workouts
    static func calculateStats(workouts: [Workout], recovery: RecoveryMetrics? = nil, selectedClass: Constants.MuscleClass? = nil) -> UserStats {
        let calculation = calculateStatPoints(workouts: workouts, recovery: recovery, selectedClass: selectedClass)
        let streak = calculateStreak(workouts: workouts).current
        let streakBoost = min(Double(streak) * 0.01, 0.25)
        let xpMultiplier = 1.0 + streakBoost
        let boostedXP = calculation.totalXP * xpMultiplier
        let levelInfo = levelFromXP(boostedXP)
        let hpInfo = healthFrom(workouts: workouts, recovery: recovery, level: levelInfo.level)

        return UserStats(
            strength: calculation.strength,
            speed: calculation.speed,
            endurance: calculation.endurance,
            intelligence: calculation.intelligence,
            level: levelInfo.level,
            xpCurrent: levelInfo.xpCurrent,
            xpToNext: levelInfo.xpToNext,
            totalXP: boostedXP,
            hpCurrent: hpInfo.current,
            hpMax: hpInfo.max,
            xpMultiplier: xpMultiplier
        )
    }

    static func xpForWorkout(_ workout: Workout) -> Double {
        workoutScore(workout)
    }

    static func levelInfoFromXP(_ totalXP: Double) -> (level: Int, xpCurrent: Double, xpToNext: Double) {
        levelFromXP(totalXP)
    }

    static func recalculateStatsWithXP(stats: UserStats) -> UserStats {
        var updated = stats
        let levelInfo = levelInfoFromXP(updated.totalXP)
        updated.level = levelInfo.level
        updated.xpCurrent = levelInfo.xpCurrent
        updated.xpToNext = levelInfo.xpToNext
        return updated
    }

    static func statXP(
        for workouts: [Workout],
        stat: Constants.PriorityStat,
        classWeights: Constants.ClassWeights,
        classMultiplier: Double
    ) -> Double {
        let statFactor: Double
        switch stat {
        case .strength: statFactor = classWeights.strength * classMultiplier
        case .speed: statFactor = classWeights.speed * classMultiplier
        case .endurance: statFactor = classWeights.endurance * classMultiplier
        case .intelligence: statFactor = classWeights.intelligence * classMultiplier
        }
        return workouts.reduce(0.0) { $0 + (workoutScore($1) * statFactor) }
    }

    static func overallXP(for workouts: [Workout], classWeights: Constants.ClassWeights) -> Double {
        let totalWeight = classWeights.strength + classWeights.speed + classWeights.endurance + classWeights.intelligence
        let normalized = totalWeight > 0 ? totalWeight / 1.0 : 1.0
        return workouts.reduce(0.0) { $0 + (workoutScore($1) * normalized) }
    }

    /// Calculate current streak from workouts
    static func calculateStreak(workouts: [Workout]) -> (current: Int, longest: Int) {
        let sorted = workouts.sorted { $0.createdAt > $1.createdAt }
        guard !sorted.isEmpty else { return (0, 0) }

        let calendar = Calendar.current
        var workoutDays = Set<DateComponents>()
        for workout in sorted {
            let components = calendar.dateComponents([.year, .month, .day], from: workout.createdAt)
            workoutDays.insert(components)
        }

        let sortedDays = workoutDays.compactMap { calendar.date(from: $0) }.sorted(by: >)
        guard !sortedDays.isEmpty else { return (0, 0) }

        // Current streak
        var currentStreak = 0
        let today = calendar.startOfDay(for: Date())
        var checkDate = today

        // Allow today or yesterday as start
        let firstDay = calendar.startOfDay(for: sortedDays[0])
        if firstDay != today && firstDay != calendar.date(byAdding: .day, value: -1, to: today) {
            // Last workout was more than 1 day ago, streak is 0
            currentStreak = 0
        } else {
            checkDate = firstDay
            for day in sortedDays {
                let dayStart = calendar.startOfDay(for: day)
                if dayStart == checkDate {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else if dayStart < checkDate {
                    break
                }
            }
        }

        // Longest streak
        var longestStreak = 0
        var tempStreak = 1
        for i in 0..<(sortedDays.count - 1) {
            let current = calendar.startOfDay(for: sortedDays[i])
            let next = calendar.startOfDay(for: sortedDays[i + 1])
            let diff = calendar.dateComponents([.day], from: next, to: current).day ?? 0
            if diff == 1 {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        longestStreak = max(longestStreak, tempStreak)

        return (currentStreak, max(longestStreak, currentStreak))
    }

    // MARK: - Individual stat calculations

    private static func calculateStatPoints(workouts: [Workout], recovery: RecoveryMetrics?, selectedClass: Constants.MuscleClass?) -> (strength: Double, speed: Double, endurance: Double, intelligence: Double, totalXP: Double) {
        let recent = recentWorkouts(workouts, days: 30)
        guard !recent.isEmpty else { return (0, 0, 0, 0, 0) }

        var strengthPoints: Double = 0
        var speedPoints: Double = 0
        var endurancePoints: Double = 0
        var intelligencePoints: Double = 0
        var totalXP: Double = 0
        let classWeights = selectedClass?.weights ?? Constants.ClassWeights(strength: 0.25, speed: 0.25, endurance: 0.25, intelligence: 0.25)
        let classModifiers = (
            strength: 0.85 + classWeights.strength * 0.6,
            speed: 0.85 + classWeights.speed * 0.6,
            endurance: 0.85 + classWeights.endurance * 0.6,
            intelligence: 0.85 + classWeights.intelligence * 0.6
        )

        for workout in recent {
            let score = workoutScore(workout)
            let weights = statWeights(for: workout.type, intensity: workout.intensity)

            strengthPoints += score * weights.strength * classModifiers.strength
            speedPoints += score * weights.speed * classModifiers.speed
            endurancePoints += score * weights.endurance * classModifiers.endurance
            intelligencePoints += score * weights.intelligence * classModifiers.intelligence
            totalXP += score
        }

        // Consistency/variety bonuses push recovery (intelligence) without inflating other stats.
        intelligencePoints += consistencyBonus(workouts: recent)
        intelligencePoints += varietyBonus(workouts: recent)

        intelligencePoints += recoveryBonusPoints(recovery)

        let strength = normalize(points: strengthPoints)
        let speed = normalize(points: speedPoints)
        let endurance = normalize(points: endurancePoints)
        let intelligence = normalize(points: intelligencePoints)

        return (strength, speed, endurance, intelligence, totalXP)
    }

    private static func workoutScore(_ workout: Workout) -> Double {
        let minutes = max(Double(workout.duration), 1)

        let energyKcal = workout.energyBurned ?? estimateEnergyKcal(workout: workout)
        let distanceMeters = workout.distance ?? estimateDistanceMeters(workout: workout)
        let mph = milesPerHour(distanceMeters: distanceMeters, minutes: minutes)
        let rpe = min(max(Double(workout.intensity) * 2.0, 1.0), 10.0)
        let hr = workout.averageHeartRate ?? workout.estimatedHeartRate ?? 130.0

        switch xpCategory(for: workout) {
        case .endurance:
            return max(0, energyKcal * 1.0)
        case .speed:
            return max(0, minutes * (mph / 7.5) * 10.0)
        case .strength:
            return max(0, minutes * (hr / 140.0) * (rpe / 10.0) * 14.0)
        case .recovery:
            return max(0, minutes * 4.0)
        }
    }

    private static func statWeights(for type: Constants.WorkoutType, intensity: Int) -> (strength: Double, speed: Double, endurance: Double, intelligence: Double) {
        switch type {
        case .strength:
            return (0.7, 0.1, 0.2, 0.0)
        case .running:
            return (0.1, 0.5, 0.4, 0.0)
        case .cycling:
            return (0.05, 0.4, 0.55, 0.0)
        case .hiit:
            return (0.4, 0.4, 0.2, 0.0)
        case .swimming:
            return (0.1, 0.3, 0.6, 0.0)
        case .walking:
            return intensity <= 2 ? (0.0, 0.1, 0.4, 0.5) : (0.05, 0.2, 0.6, 0.15)
        case .yoga, .stretching, .meditation:
            return (0.0, 0.0, 0.1, 0.9)
        case .other:
            return (0.2, 0.3, 0.5, 0.0)
        }
    }

    private static func heartRateFactor(bpm: Double?) -> Double {
        guard let bpm, bpm > 0 else { return 0.5 }
        // Normalize 90-170 bpm into 0-2 range, clamp outside.
        let normalized = (bpm - 90.0) / 80.0
        return min(max(normalized * 2.0, 0.0), 2.0)
    }

    private static func strengthLoadFactor(workout: Workout) -> Double {
        guard workout.type == .strength,
              let reps = workout.strengthReps,
              let weightKg = workout.strengthWeightKg,
              reps > 0, weightKg > 0 else { return 0 }

        // Epley 1RM estimate: weight * (1 + reps/30)
        let oneRM = weightKg * (1.0 + Double(reps) / 30.0)
        let normalized = min(oneRM / 200.0, 2.0) // 200kg => factor 1.0, capped at 2.0
        return max(normalized, 0.2)
    }

    private enum XPCategory {
        case endurance, speed, strength, recovery
    }

    private static func xpCategory(for workout: Workout) -> XPCategory {
        switch workout.type {
        case .strength:
            return .strength
        case .hiit:
            return .strength
        case .yoga, .stretching, .meditation:
            return .recovery
        case .walking:
            return .recovery
        case .running, .cycling, .swimming:
            return workout.intensity >= 4 ? .speed : .endurance
        case .other:
            return .endurance
        }
    }

    private static func milesPerHour(distanceMeters: Double, minutes: Double) -> Double {
        guard minutes > 0 else { return 0 }
        let miles = distanceMeters / 1609.34
        let hours = minutes / 60.0
        return hours > 0 ? miles / hours : 0
    }

    static func estimateEnergyKcal(workout: Workout) -> Double {
        let minutes = max(Double(workout.duration), 1)
        let intensityFactor = Double(workout.intensity) * 2.5 // 2.5-12.5
        let baseRate = 4.0 + intensityFactor // 6.5-16.5 kcal/min
        return baseRate * minutes
    }

    static func estimateDistanceMeters(workout: Workout) -> Double {
        let minutes = max(Double(workout.duration), 1)
        switch workout.type {
        case .running:
            return minutes * 150 // ~9 km/h
        case .cycling:
            return minutes * 350 // ~21 km/h
        case .walking:
            return minutes * 80 // ~4.8 km/h
        default:
            return 0
        }
    }

    private static func normalize(points: Double) -> Double {
        guard points > 0 else { return 0 }
        let scale = log1p(1000.0)
        return min(99, (log1p(points) / scale) * 99.0)
    }

    private static func consistencyBonus(workouts: [Workout]) -> Double {
        let calendar = Calendar.current
        var weeklyDays: [Int] = []
        let weeks = 4
        for week in 0..<weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -(week - 1), to: Date())!
            let weekWorkouts = workouts.filter { $0.createdAt >= weekStart && $0.createdAt < weekEnd }
            let uniqueDays = Set(weekWorkouts.map { calendar.startOfDay(for: $0.createdAt) }).count
            weeklyDays.append(uniqueDays)
        }
        let avgDays = Double(weeklyDays.reduce(0, +)) / Double(max(weeklyDays.count, 1))
        switch avgDays {
        case 4...6: return 60
        case 3...7: return 40
        case 2...: return 20
        default: return avgDays * 10
        }
    }

    private static func varietyBonus(workouts: [Workout]) -> Double {
        let workoutTypes = Set(workouts.map { $0.type })
        return min(Double(workoutTypes.count) / 6.0, 1.0) * 40
    }

    private static func recoveryBonusPoints(_ recovery: RecoveryMetrics?) -> Double {
        guard let recovery else { return 0 }

        var score: Double = 0

        if let sleepMinutes = recovery.sleepMinutes7d {
            let sleepHours = sleepMinutes / 60.0
            let delta = abs(sleepHours - 8.0)
            let sleepScore = max(0.0, 1.0 - min(delta / 3.5, 1.0))
            score += sleepScore * 70.0
        }

        if let mindfulMinutes = recovery.mindfulMinutes7d {
            let mindfulScore = min(mindfulMinutes / 25.0, 1.0)
            score += mindfulScore * 10.0
        }

        if let hrv = recovery.hrvSDNN {
            let hrvScore = min(max((hrv - 25.0) / 75.0, 0.0), 1.0)
            score += hrvScore * 15.0
        }

        if let restingHR = recovery.restingHeartRate {
            let rhrScore = min(max((90.0 - restingHR) / 45.0, 0.0), 1.0)
            score += rhrScore * 15.0
        }

        if let hrr = recovery.heartRateRecovery1Min {
            let hrrScore = min(max((hrr - 10.0) / 35.0, 0.0), 1.0)
            score += hrrScore * 10.0
        }

        return score
    }

    private static func levelFromXP(_ totalXP: Double) -> (level: Int, xpCurrent: Double, xpToNext: Double) {
        var level = 1
        var remaining = max(0, totalXP)
        var next = xpForLevel(level)

        while remaining >= next && level < 99 {
            remaining -= next
            level += 1
            next = xpForLevel(level)
        }

        return (level, remaining, next)
    }

    private static func xpForLevel(_ level: Int) -> Double {
        let base = 100.0
        let growth = 1.15
        return base * pow(growth, Double(max(level - 1, 0)))
    }

    private static func healthFrom(workouts: [Workout], recovery: RecoveryMetrics?, level: Int) -> (current: Double, max: Double) {
        let last7 = recentWorkouts(workouts, days: 7)
        let load = last7.reduce(0.0) { $0 + workoutScore($1) }
        let loadNorm = min(log1p(load) / log1p(2000.0), 1.0)

        let recoveryScore = recoveryScoreNormalized(recovery)
        let novice = max(0.0, min(1.0, 1.0 - (Double(level - 1) / 24.0)))

        let base = 100.0
        let penalty = loadNorm * (40.0 - 12.0 * novice)
        let bonus = recoveryScore * (35.0 + 6.0 * novice)
        let current = min(max((55.0 + 5.0 * novice) + bonus - penalty, 10.0 + 5.0 * novice), 100.0)

        return (current, base)
    }

    private static func recoveryScoreNormalized(_ recovery: RecoveryMetrics?) -> Double {
        guard let recovery else { return 0.5 }

        var scores: [Double] = []

        if let sleepMinutes = recovery.sleepMinutes7d {
            let sleepHours = sleepMinutes / 60.0
            let delta = abs(sleepHours - 8.0)
            let sleepScore = max(0.0, 1.0 - min(delta / 3.5, 1.0))
            scores.append(sleepScore)
        }

        if let mindfulMinutes = recovery.mindfulMinutes7d {
            scores.append(min(mindfulMinutes / 25.0, 1.0) * 0.5)
        }

        if let hrv = recovery.hrvSDNN {
            scores.append(min(max((hrv - 25.0) / 75.0, 0.0), 1.0))
        }

        if let restingHR = recovery.restingHeartRate {
            scores.append(min(max((90.0 - restingHR) / 45.0, 0.0), 1.0))
        }

        if let hrr = recovery.heartRateRecovery1Min {
            scores.append(min(max((hrr - 10.0) / 35.0, 0.0), 1.0))
        }

        guard !scores.isEmpty else { return 0.5 }
        let avg = scores.reduce(0, +) / Double(scores.count)
        return min(max(avg, 0.2), 1.0)
    }

    private static func recentWorkouts(_ workouts: [Workout], days: Int) -> [Workout] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return workouts.filter { $0.createdAt >= cutoff }
    }
}
