import Foundation
import FirebaseFirestore

@MainActor
class FirestoreService: ObservableObject {
    private lazy var db = Firestore.firestore()
    private var isDemoMode: Bool { !AppDelegate.firebaseConfigured }

    // MARK: - Demo Data

    static let demoMembers: [AppUser] = [
        AppUser(id: "demo", displayName: "Demo Daddy", groupId: "demo-group",
                stats: UserStats(strength: 42, speed: 35, endurance: 55, intelligence: 28, level: 12),
                currentStreak: 4, longestStreak: 14),
        AppUser(id: "demo2", displayName: "Iron Mike", groupId: "demo-group",
                stats: UserStats(strength: 72, speed: 28, endurance: 40, intelligence: 15, level: 18),
                currentStreak: 7, longestStreak: 21, selectedTheme: .pixel, classTheme: .sports, selectedClass: .powerForward),
        AppUser(id: "demo3", displayName: "Cardio Queen", groupId: "demo-group",
                stats: UserStats(strength: 20, speed: 65, endurance: 70, intelligence: 45, level: 15),
                currentStreak: 12, longestStreak: 30, selectedTheme: .trading, classTheme: .sports, selectedClass: .striker),
        AppUser(id: "demo4", displayName: "Zen Master", groupId: "demo-group",
                stats: UserStats(strength: 30, speed: 25, endurance: 35, intelligence: 80, level: 14),
                currentStreak: 0, longestStreak: 10, classTheme: .fantasy, selectedClass: .wizard),
    ]

    static let demoWorkouts: [Workout] = [
        Workout(id: "w1", userId: "demo", groupId: "demo-group", type: .strength, duration: 45, intensity: 4, createdAt: Date()),
        Workout(id: "w2", userId: "demo", groupId: "demo-group", type: .running, duration: 30, intensity: 3, createdAt: Date().addingTimeInterval(-86400)),
        Workout(id: "w3", userId: "demo", groupId: "demo-group", type: .yoga, duration: 20, intensity: 2, notes: "Morning flow", createdAt: Date().addingTimeInterval(-172800)),
    ]

    static let demoFeed: [FeedItem] = [
        FeedItem(groupId: "demo-group", userId: "demo2", userName: "Iron Mike", type: .workout,
                 content: "Iron Mike logged 60 min of Strength Training (Intensity: 5/5)",
                 createdAt: Date().addingTimeInterval(-3600)),
        FeedItem(groupId: "demo-group", userId: "demo3", userName: "Cardio Queen", type: .achievement,
                 content: "Cardio Queen unlocked Iron Will — 7-day streak!",
                 createdAt: Date().addingTimeInterval(-7200)),
        FeedItem(groupId: "demo-group", userId: "demo", userName: "Demo Daddy", type: .workout,
                 content: "Demo Daddy logged 45 min of Strength Training (Intensity: 4/5)",
                 createdAt: Date().addingTimeInterval(-10800)),
        FeedItem(groupId: "demo-group", userId: "demo4", userName: "Zen Master", type: .workout,
                 content: "Zen Master logged 30 min of Yoga (Intensity: 2/5)",
                 createdAt: Date().addingTimeInterval(-14400)),
    ]

    // MARK: - User

    func updateUser(_ user: AppUser) async throws {
        guard !isDemoMode, let uid = user.id else { return }
        try db.collection(Constants.Firestore.users).document(uid).setData(from: user, merge: true)
    }

    func getUser(uid: String) async throws -> AppUser? {
        if isDemoMode { return Self.demoMembers.first { $0.id == uid } }
        let doc = try await db.collection(Constants.Firestore.users).document(uid).getDocument()
        return try doc.data(as: AppUser.self)
    }

    // MARK: - Group

    func createGroup(name: String, createdBy: String) async throws -> WorkoutGroup {
        if isDemoMode {
            return WorkoutGroup(id: "demo-group", name: name, inviteCode: "DEMO42", createdBy: createdBy, memberIds: [createdBy])
        }
        let inviteCode = generateInviteCode()
        var group = WorkoutGroup(name: name, inviteCode: inviteCode, createdBy: createdBy, memberIds: [createdBy])
        let ref = try db.collection(Constants.Firestore.groups).addDocument(from: group)
        group.id = ref.documentID
        try await db.collection(Constants.Firestore.users).document(createdBy).updateData([
            "groupId": ref.documentID
        ])
        return group
    }

    func joinGroup(inviteCode: String, userId: String) async throws -> WorkoutGroup? {
        if isDemoMode {
            return WorkoutGroup(id: "demo-group", name: "Demo Group", inviteCode: inviteCode, createdBy: "demo", memberIds: ["demo", userId])
        }
        let snapshot = try await db.collection(Constants.Firestore.groups)
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        var group = try doc.data(as: WorkoutGroup.self)
        if !group.memberIds.contains(userId) {
            group.memberIds.append(userId)
            try db.collection(Constants.Firestore.groups).document(doc.documentID).setData(from: group)
        }
        try await db.collection(Constants.Firestore.users).document(userId).updateData([
            "groupId": doc.documentID
        ])
        return group
    }

    func getGroup(groupId: String) async throws -> WorkoutGroup? {
        if isDemoMode {
            return WorkoutGroup(id: "demo-group", name: "Muscle Daddies", inviteCode: "DEMO42", createdBy: "demo",
                                memberIds: Self.demoMembers.compactMap { $0.id })
        }
        let doc = try await db.collection(Constants.Firestore.groups).document(groupId).getDocument()
        return try doc.data(as: WorkoutGroup.self)
    }

    func getGroupMembers(groupId: String) async throws -> [AppUser] {
        if isDemoMode { return Self.demoMembers }
        guard let group = try await getGroup(groupId: groupId) else { return [] }
        var members: [AppUser] = []
        for memberId in group.memberIds {
            if let user = try await getUser(uid: memberId) {
                members.append(user)
            }
        }
        return members
    }

    // MARK: - Workouts

    func logWorkout(_ workout: Workout) async throws -> Workout {
        if isDemoMode { var w = workout; w.id = UUID().uuidString; return w }
        var workout = workout
        let ref = try db.collection(Constants.Firestore.workouts).addDocument(from: workout)
        workout.id = ref.documentID
        return workout
    }

    func getWorkouts(userId: String, limit: Int = 50) async throws -> [Workout] {
        if isDemoMode { return Self.demoWorkouts.filter { $0.userId == userId } }
        let snapshot = try await db.collection(Constants.Firestore.workouts)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Workout.self) }
    }

    func getWorkouts(userId: String, since date: Date) async throws -> [Workout] {
        if isDemoMode { return Self.demoWorkouts.filter { $0.userId == userId && $0.createdAt >= date } }
        let snapshot = try await db.collection(Constants.Firestore.workouts)
            .whereField("userId", isEqualTo: userId)
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: date))
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Workout.self) }
    }

    func getGroupWorkouts(groupId: String, limit: Int = 50) async throws -> [Workout] {
        if isDemoMode { return Self.demoWorkouts }
        let snapshot = try await db.collection(Constants.Firestore.workouts)
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Workout.self) }
    }

    /// Backfill missing workout metrics (energy/distance) with estimates
    func backfillWorkoutMetrics(userId: String, since date: Date? = nil) async -> Int {
        guard !isDemoMode else { return 0 }
        let since = date ?? Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()

        let workouts = (try? await getWorkouts(userId: userId, since: since)) ?? []
        guard !workouts.isEmpty else { return 0 }

        var updatedCount = 0
        for workout in workouts {
            guard let id = workout.id else { continue }

            var updates: [String: Any] = [:]

            if workout.energyBurned == nil {
                let estimatedEnergy = StatCalculator.estimateEnergyKcal(workout: workout)
                updates["energyBurned"] = estimatedEnergy
            }

            if workout.distance == nil {
                let estimatedDistance = StatCalculator.estimateDistanceMeters(workout: workout)
                if estimatedDistance > 0 {
                    updates["distance"] = estimatedDistance
                }
            }

            guard !updates.isEmpty else { continue }

            do {
                try await db.collection(Constants.Firestore.workouts).document(id).updateData(updates)
                updatedCount += 1
            } catch {
                continue
            }
        }

        return updatedCount
    }

    // MARK: - Feed

    func postFeedItem(_ item: FeedItem) async throws {
        if isDemoMode { return }
        try db.collection(Constants.Firestore.feed).addDocument(from: item)
    }

    func getFeed(groupId: String, limit: Int = 50) async throws -> [FeedItem] {
        if isDemoMode { return Self.demoFeed }
        let snapshot = try await db.collection(Constants.Firestore.feed)
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FeedItem.self) }
    }

    func addReaction(feedItemId: String, reaction: String, userId: String) async throws {
        if isDemoMode { return }
        let ref = db.collection(Constants.Firestore.feed).document(feedItemId)
        try await ref.updateData([
            "reactions.\(reaction)": FieldValue.arrayUnion([userId])
        ])
    }

    func removeReaction(feedItemId: String, reaction: String, userId: String) async throws {
        if isDemoMode { return }
        let ref = db.collection(Constants.Firestore.feed).document(feedItemId)
        try await ref.updateData([
            "reactions.\(reaction)": FieldValue.arrayRemove([userId])
        ])
    }

    func addComment(feedItemId: String, comment: FeedComment) async throws {
        if isDemoMode { return }
        let ref = db.collection(Constants.Firestore.feed).document(feedItemId)
        let commentData: [String: Any] = [
            "id": comment.id,
            "userId": comment.userId,
            "userName": comment.userName,
            "text": comment.text,
            "createdAt": Timestamp(date: comment.createdAt)
        ]
        try await ref.updateData([
            "comments": FieldValue.arrayUnion([commentData])
        ])
    }

    // MARK: - Recovery Metrics

    func saveRecoveryMetrics(userId: String, metrics: RecoveryMetrics) async throws {
        if isDemoMode { return }
        let date = metrics.capturedAt ?? Date()
        let dayKey = DateFormatter.dayKey.string(from: date)

        var data: [String: Any] = [
            "userId": userId,
            "capturedAt": Timestamp(date: date),
            "dayKey": dayKey
        ]
        if let v = metrics.sleepMinutes7d { data["sleepMinutes7d"] = v }
        if let v = metrics.mindfulMinutes7d { data["mindfulMinutes7d"] = v }
        if let v = metrics.hrvSDNN { data["hrvSDNN"] = v }
        if let v = metrics.restingHeartRate { data["restingHeartRate"] = v }
        if let v = metrics.heartRateRecovery1Min { data["heartRateRecovery1Min"] = v }

        let ref = db.collection(Constants.Firestore.recovery)
            .document(userId)
            .collection("daily")
            .document(dayKey)

        try await ref.setData(data, merge: true)
    }

    func getRecoveryMetrics(userId: String, days: Int = 30) async throws -> [RecoveryMetrics] {
        if isDemoMode { return [] }
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let snapshot = try await db.collection(Constants.Firestore.recovery)
            .document(userId)
            .collection("daily")
            .whereField("capturedAt", isGreaterThanOrEqualTo: Timestamp(date: since))
            .order(by: "capturedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            let metrics = RecoveryMetrics(
                sleepMinutes7d: data["sleepMinutes7d"] as? Double,
                mindfulMinutes7d: data["mindfulMinutes7d"] as? Double,
                hrvSDNN: data["hrvSDNN"] as? Double,
                restingHeartRate: data["restingHeartRate"] as? Double,
                heartRateRecovery1Min: data["heartRateRecovery1Min"] as? Double,
                capturedAt: (data["capturedAt"] as? Timestamp)?.dateValue()
            )
            return metrics
        }
    }

    // MARK: - Challenges

    func createChallenge(_ challenge: Challenge) async throws {
        if isDemoMode { return }
        try db.collection(Constants.Firestore.challenges).addDocument(from: challenge)
    }

    func getChallenges(groupId: String) async throws -> [Challenge] {
        if isDemoMode { return [] }
        let snapshot = try await db.collection(Constants.Firestore.challenges)
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "endDate", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Challenge.self) }
    }

    // MARK: - Achievements

    func unlockAchievement(userId: String, achievement: Achievement) async throws {
        if isDemoMode { return }
        try db.collection(Constants.Firestore.achievements)
            .document(userId)
            .collection("unlocked")
            .document(achievement.achievementType.rawValue)
            .setData(from: achievement)
    }

    func getAchievements(userId: String) async throws -> [Achievement] {
        if isDemoMode { return [Achievement(achievementType: .firstBlood), Achievement(achievementType: .ironWill)] }
        let snapshot = try await db.collection(Constants.Firestore.achievements)
            .document(userId)
            .collection("unlocked")
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Achievement.self) }
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

private extension DateFormatter {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
