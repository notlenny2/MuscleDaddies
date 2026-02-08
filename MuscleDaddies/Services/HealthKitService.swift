import Foundation
import HealthKit
import CoreLocation

@MainActor
class HealthKitService: ObservableObject {
    @Published var isAuthorized = false

    private let healthStore = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()
    private let workoutRouteType = HKSeriesType.workoutRoute()

    private let quantityTypes: Set<HKQuantityType> = {
        let ids: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned, .basalEnergyBurned, .heartRate,
            .restingHeartRate, .heartRateVariabilitySDNN,
            .walkingHeartRateAverage, .heartRateRecoveryOneMinute,
            .vo2Max, .distanceWalkingRunning, .distanceCycling,
            .stepCount, .flightsClimbed, .appleExerciseTime, .appleStandTime
        ]
        return Set(ids.compactMap { HKQuantityType.quantityType(forIdentifier: $0) })
    }()

    private let categoryTypes: Set<HKCategoryType> = {
        let ids: [HKCategoryTypeIdentifier] = [.sleepAnalysis, .mindfulSession]
        return Set(ids.compactMap { HKCategoryType.categoryType(forIdentifier: $0) })
    }()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        var typesToRead: Set<HKObjectType> = [workoutType, workoutRouteType]
        typesToRead.formUnion(quantityTypes)
        typesToRead.formUnion(categoryTypes)

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    func fetchRecentWorkouts(since date: Date) async -> [Workout] {
        guard isAuthorized else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let hkWorkouts = samples as? [HKWorkout], error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                Task {
                    var workouts: [Workout] = []
                    workouts.reserveCapacity(hkWorkouts.count)
                    for hk in hkWorkouts {
                        let energy = hk.totalEnergyBurned?.doubleValue(for: .kilocalorie())
                        let distance = hk.totalDistance?.doubleValue(for: .meter())
                        let avgHR = await self.fetchAverageHeartRate(for: hk)

                        let workout = Workout(
                            userId: "", // Will be set by caller
                            type: Self.mapWorkoutType(hk.workoutActivityType),
                            source: .healthkit,
                            duration: Int(hk.duration / 60),
                            intensity: Self.estimateIntensity(hk),
                            energyBurned: energy,
                            distance: distance,
                            averageHeartRate: avgHR,
                            createdAt: hk.startDate,
                            healthKitUUID: hk.uuid.uuidString
                        )
                        workouts.append(workout)
                    }
                    continuation.resume(returning: workouts)
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Recovery Metrics

    func fetchRecoveryMetrics() async -> RecoveryMetrics {
        guard isAuthorized else { return RecoveryMetrics() }

        let since = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let sleepSamples = await fetchCategorySamples(identifier: .sleepAnalysis, since: since)
        let mindfulSamples = await fetchCategorySamples(identifier: .mindfulSession, since: since)

        let sleepMinutes = totalSleepMinutes(samples: sleepSamples)
        let mindfulMinutes = mindfulSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60.0 }

        let hrvSample = await fetchMostRecentQuantitySample(identifier: .heartRateVariabilitySDNN)
        let restingHRSample = await fetchMostRecentQuantitySample(identifier: .restingHeartRate)
        let hrrSample = await fetchMostRecentQuantitySample(identifier: .heartRateRecoveryOneMinute)

        let hrvMs = hrvSample?.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let restingHR = restingHRSample?.quantity.doubleValue(for: bpmUnit)
        let hrr1min = hrrSample?.quantity.doubleValue(for: bpmUnit)

        return RecoveryMetrics(
            sleepMinutes7d: sleepMinutes / 7.0,
            mindfulMinutes7d: mindfulMinutes / 7.0,
            hrvSDNN: hrvMs,
            restingHeartRate: restingHR,
            heartRateRecovery1Min: hrr1min,
            capturedAt: Date()
        )
    }

    private func totalSleepMinutes(samples: [HKCategorySample]) -> Double {
        var asleepValues: Set<Int> = [HKCategoryValueSleepAnalysis.asleep.rawValue]
        if #available(iOS 16.0, *) {
            asleepValues.insert(HKCategoryValueSleepAnalysis.asleepCore.rawValue)
            asleepValues.insert(HKCategoryValueSleepAnalysis.asleepDeep.rawValue)
            asleepValues.insert(HKCategoryValueSleepAnalysis.asleepREM.rawValue)
            asleepValues.insert(HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue)
        }

        return samples.reduce(0.0) { total, sample in
            guard asleepValues.contains(sample.value) else { return total }
            return total + sample.endDate.timeIntervalSince(sample.startDate) / 60.0
        }
    }

    // MARK: - Heart Rate

    private func fetchAverageHeartRate(for workout: HKWorkout) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, _ in
                guard let avg = statistics?.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                let unit = HKUnit.count().unitDivided(by: .minute())
                continuation.resume(returning: avg.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Generic Quantity/Category Queries

    func fetchQuantitySamples(
        identifier: HKQuantityTypeIdentifier,
        since date: Date,
        limit: Int = HKObjectQueryNoLimit
    ) async -> [HKQuantitySample] {
        guard isAuthorized, let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: samples)
            }
            healthStore.execute(query)
        }
    }

    func fetchCategorySamples(
        identifier: HKCategoryTypeIdentifier,
        since date: Date,
        limit: Int = HKObjectQueryNoLimit
    ) async -> [HKCategorySample] {
        guard isAuthorized, let type = HKCategoryType.categoryType(forIdentifier: identifier) else { return [] }

        let predicate = HKQuery.predicateForSamples(withStart: date, end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: samples)
            }
            healthStore.execute(query)
        }
    }

    func fetchMostRecentQuantitySample(
        identifier: HKQuantityTypeIdentifier
    ) async -> HKQuantitySample? {
        let samples = await fetchQuantitySamples(identifier: identifier, since: Date.distantPast, limit: 1)
        return samples.first
    }

    // MARK: - Workout Routes

    func fetchWorkoutRoutes(for workout: HKWorkout) async -> [HKWorkoutRoute] {
        guard isAuthorized else { return [] }

        let predicate = HKQuery.predicateForObjects(from: workout)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutRouteType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let routes = samples as? [HKWorkoutRoute], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: routes)
            }
            healthStore.execute(query)
        }
    }

    func fetchRouteLocations(route: HKWorkoutRoute) async -> [CLLocation] {
        guard isAuthorized else { return [] }

        return await withCheckedContinuation { continuation in
            var collected: [CLLocation] = []
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let locations = locations {
                    collected.append(contentsOf: locations)
                }
                if done || error != nil {
                    continuation.resume(returning: collected)
                }
            }
            healthStore.execute(query)
        }
    }

    /// Sync HealthKit workouts to Firestore, skipping duplicates
    func syncWorkouts(userId: String, groupId: String?, firestoreService: FirestoreService) async -> Int {
        guard isAuthorized else { return 0 }

        let since = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let hkWorkouts = await fetchRecentWorkouts(since: since)
        guard !hkWorkouts.isEmpty else { return 0 }

        // Get existing HealthKit UUIDs to deduplicate
        let existing = try? await firestoreService.getWorkouts(userId: userId, since: since)
        let existingUUIDs = Set((existing ?? []).compactMap { $0.healthKitUUID })

        var synced = 0
        for var workout in hkWorkouts {
            guard let uuid = workout.healthKitUUID, !existingUUIDs.contains(uuid) else { continue }
            workout.userId = userId
            workout.groupId = groupId
            _ = try? await firestoreService.logWorkout(workout)
            synced += 1
        }
        return synced
    }

    static func mapWorkoutType(_ activityType: HKWorkoutActivityType) -> Constants.WorkoutType {
        switch activityType {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return .strength
        case .running:
            return .running
        case .cycling:
            return .cycling
        case .yoga:
            return .yoga
        case .highIntensityIntervalTraining:
            return .hiit
        case .swimming:
            return .swimming
        case .walking, .hiking:
            return .walking
        case .mindAndBody, .flexibility:
            return .stretching
        default:
            return .other
        }
    }

    private static func estimateIntensity(_ workout: HKWorkout) -> Int {
        // Estimate intensity based on workout type and duration
        let minutes = workout.duration / 60
        switch workout.workoutActivityType {
        case .highIntensityIntervalTraining: return 5
        case .running: return minutes > 45 ? 4 : 3
        case .traditionalStrengthTraining: return 4
        case .cycling: return 3
        case .swimming: return 4
        case .yoga, .flexibility: return 2
        case .walking: return 1
        default: return 3
        }
    }
}
