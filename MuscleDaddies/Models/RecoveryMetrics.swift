import Foundation

struct RecoveryMetrics: Codable {
    var sleepMinutes7d: Double?
    var mindfulMinutes7d: Double?
    var hrvSDNN: Double?
    var restingHeartRate: Double?
    var heartRateRecovery1Min: Double?
    var capturedAt: Date?

    init(
        sleepMinutes7d: Double? = nil,
        mindfulMinutes7d: Double? = nil,
        hrvSDNN: Double? = nil,
        restingHeartRate: Double? = nil,
        heartRateRecovery1Min: Double? = nil,
        capturedAt: Date? = nil
    ) {
        self.sleepMinutes7d = sleepMinutes7d
        self.mindfulMinutes7d = mindfulMinutes7d
        self.hrvSDNN = hrvSDNN
        self.restingHeartRate = restingHeartRate
        self.heartRateRecovery1Min = heartRateRecovery1Min
        self.capturedAt = capturedAt
    }
}
