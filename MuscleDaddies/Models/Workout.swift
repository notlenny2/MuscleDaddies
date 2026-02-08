import Foundation
import FirebaseFirestore

struct Workout: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var groupId: String?
    var type: Constants.WorkoutType
    var source: WorkoutSource
    var duration: Int // minutes
    var intensity: Int // 1-5
    var energyBurned: Double? // kilocalories
    var distance: Double? // meters
    var averageHeartRate: Double? // bpm
    var estimatedHeartRate: Double?
    var strengthExercise: String?
    var strengthReps: Int?
    var strengthWeightKg: Double?
    var notes: String?
    var createdAt: Date
    var healthKitUUID: String?

    enum WorkoutSource: String, Codable {
        case healthkit, manual
    }

    init(
        id: String? = nil,
        userId: String,
        groupId: String? = nil,
        type: Constants.WorkoutType,
        source: WorkoutSource = .manual,
        duration: Int,
        intensity: Int,
        energyBurned: Double? = nil,
        distance: Double? = nil,
        averageHeartRate: Double? = nil,
        estimatedHeartRate: Double? = nil,
        strengthExercise: String? = nil,
        strengthReps: Int? = nil,
        strengthWeightKg: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        healthKitUUID: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.type = type
        self.source = source
        self.duration = duration
        self.intensity = intensity
        self.energyBurned = energyBurned
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.estimatedHeartRate = estimatedHeartRate
        self.strengthExercise = strengthExercise
        self.strengthReps = strengthReps
        self.strengthWeightKg = strengthWeightKg
        self.notes = notes
        self.createdAt = createdAt
        self.healthKitUUID = healthKitUUID
    }
}
