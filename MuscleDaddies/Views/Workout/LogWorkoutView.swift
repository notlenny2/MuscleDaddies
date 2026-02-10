import SwiftUI
import UIKit

struct LogWorkoutView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var healthKitService: HealthKitService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("unitsSystem") private var unitsSystemRaw: String = Constants.UnitsSystem.imperial.rawValue

    @State private var selectedType: Constants.WorkoutType = .strength
    @State private var duration: Int = 30
    @State private var intensity: Int = 3
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var strengthExercise: String = ""
    @State private var strengthReps: Int = 8
    @State private var strengthWeight: Double = 135
    @State private var strengthUnit: StrengthUnit = .lb
    @State private var distance: Double = 3.0
    @State private var distanceUnit: DistanceUnit = .mi
    @State private var newAchievements: [Achievement] = []
    @State private var showAchievementCelebration = false

    enum StrengthUnit: String, CaseIterable {
        case lb = "lb"
        case kg = "kg"
    }

    enum DistanceUnit: String, CaseIterable {
        case mi = "mi"
        case km = "km"
    }

    private var preferredStrengthUnit: StrengthUnit {
        unitsSystemRaw == Constants.UnitsSystem.metric.rawValue ? .kg : .lb
    }

    private var preferredDistanceUnit: DistanceUnit {
        unitsSystemRaw == Constants.UnitsSystem.metric.rawValue ? .km : .mi
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Workout Type
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WORKOUT TYPE")
                                .font(.pixel(8))
                                .foregroundColor(.gray)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(Constants.WorkoutType.allCases, id: \.rawValue) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 22))
                                            Text(type.displayName)
                                                .font(.pixel(7))
                                        }
                                        .foregroundColor(selectedType == type ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 70)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(selectedType == type ? Color.cardGold : Color.cardDarkGray)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // Duration
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DURATION")
                                .font(.pixel(8))
                                .foregroundColor(.gray)

                            HStack(spacing: 16) {
                                ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                                    Button {
                                        duration = mins
                                    } label: {
                                        Text("\(mins)m")
                                            .font(.pixel(9))
                                            .foregroundColor(duration == mins ? .black : .white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 40)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(duration == mins ? Color.cardGold : Color.cardDarkGray)
                                            )
                                    }
                                }
                            }

                            Stepper("Custom: \(duration) min", value: $duration, in: 5...300, step: 5)
                                .font(.secondary(13))
                                .foregroundColor(.white)
                                .tint(.cardGold)
                        }

                        // Intensity
                        VStack(alignment: .leading, spacing: 10) {
                            Text("INTENSITY")
                                .font(.pixel(8))
                                .foregroundColor(.gray)

                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { level in
                                    Button {
                                        intensity = level
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(intensityEmoji(level))
                                                .font(.system(size: 24))
                                            Text(intensityLabel(level))
                                                .font(.secondary(9, weight: .medium))
                                                .foregroundColor(intensity == level ? .black : .gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(intensity == level ? Color.cardGold : Color.cardDarkGray)
                                        )
                                    }
                                }
                            }
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NOTES (OPTIONAL)")
                                .font(.pixel(8))
                                .foregroundColor(.gray)

                            TextField("How was it?", text: $notes, axis: .vertical)
                                .lineLimit(3...5)
                                .textFieldStyle(.roundedBorder)
                        }

        if selectedType == .strength {
            VStack(alignment: .leading, spacing: 10) {
                Text("STRENGTH SET (OPTIONAL)")
                    .font(.secondary(12, weight: .bold))
                    .foregroundColor(.gray)

                                TextField("Exercise (e.g., Bench Press)", text: $strengthExercise)
                                    .textFieldStyle(.roundedBorder)

                                HStack(spacing: 12) {
                                    Stepper("Reps: \(strengthReps)", value: $strengthReps, in: 1...30)
                                        .font(.secondary(13))
                                        .foregroundColor(.white)

                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    Stepper("Weight: \(Int(strengthWeight))", value: $strengthWeight, in: 5...800, step: 5)
                                        .font(.secondary(13))
                                        .foregroundColor(.white)

                                    Picker("Unit", selection: $strengthUnit) {
                                        ForEach(StrengthUnit.allCases, id: \.rawValue) { unit in
                                            Text(unit.rawValue.uppercased()).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                }

                                Text("Tip: enter your best working set for the day.")
                                    .font(.secondary(11))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }

                        if selectedType == .running || selectedType == .cycling || selectedType == .swimming || selectedType == .walking {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DISTANCE (OPTIONAL)")
                                    .font(.secondary(12, weight: .bold))
                                    .foregroundColor(.gray)

                                HStack(spacing: 12) {
                                    Stepper("Distance: \(String(format: "%.1f", distance))", value: $distance, in: 0.1...50, step: 0.5)
                                        .font(.secondary(13))
                                        .foregroundColor(.white)

                                    Picker("Unit", selection: $distanceUnit) {
                                        ForEach(DistanceUnit.allCases, id: \.rawValue) { unit in
                                            Text(unit.rawValue.uppercased()).tag(unit)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 120)
                                }

                                Text("Track your distance for better stats.")
                                    .font(.secondary(11))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }

                        // Save button
                        Button {
                            Task { await saveWorkout() }
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("LOG WORKOUT")
                                    .font(.pixel(11))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.cardGold)
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                        .disabled(isSaving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cardGold)
                }
            }
            .overlay {
                if showAchievementCelebration && !newAchievements.isEmpty {
                    AchievementCelebrationOverlay(achievements: newAchievements)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            applyPreferredUnitIfNeeded()
        }
        .onChange(of: unitsSystemRaw) { _, _ in
            applyPreferredUnitIfNeeded()
        }
    }

    private func saveWorkout() async {
        guard let user = authService.currentUser, let uid = user.id else { return }
        isSaving = true

        let workout = Workout(
            userId: uid,
            groupId: user.groupId,
            type: selectedType,
            duration: duration,
            intensity: intensity,
            distance: distanceInKm(),
            estimatedHeartRate: estimateHeartRate(),
            strengthExercise: selectedType == .strength && !strengthExercise.isEmpty ? strengthExercise : nil,
            strengthReps: selectedType == .strength ? strengthReps : nil,
            strengthWeightKg: selectedType == .strength ? strengthWeightKg() : nil,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            _ = try await firestoreService.logWorkout(workout)

            // Post to feed
            if let groupId = user.groupId {
                let feedItem = FeedItem(
                    groupId: groupId,
                    userId: uid,
                    userName: user.displayName,
                    type: .workout,
                    content: "\(user.displayName) logged \(duration) min of \(selectedType.displayName) (Intensity: \(intensity)/5)"
                )
                try? await firestoreService.postFeedItem(feedItem)
            }

            // Recalculate stats
            let allWorkouts = try await firestoreService.getWorkouts(userId: uid)
            var updatedUser = user
            let recovery = healthKitService.isAuthorized ? await healthKitService.fetchRecoveryMetrics() : nil
            if let recovery, let uid = user.id {
                try? await firestoreService.saveRecoveryMetrics(userId: uid, metrics: recovery)
            }
            updatedUser.stats = StatCalculator.calculateStats(workouts: allWorkouts, recovery: recovery, selectedClass: updatedUser.selectedClass)
            let streak = StatCalculator.calculateStreak(workouts: allWorkouts)
            updatedUser.currentStreak = streak.current
            updatedUser.longestStreak = streak.longest
            updatedUser.lastWorkoutDate = Date()

            // Track time-based achievements
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 7 {
                updatedUser.earlyWorkouts += 1
                print("⏰ Early workout logged! Total: \(updatedUser.earlyWorkouts)")
            }
            if hour >= 20 { // 8pm in 24-hour format
                updatedUser.lateWorkouts += 1
                print("🌙 Late workout logged! Total: \(updatedUser.lateWorkouts)")
            }

            // Track cumulative metrics
            updatedUser.totalWorkoutMinutes += duration
            if let distKm = distanceInKm() {
                updatedUser.totalDistanceKm += distKm
                print("📏 Distance tracked: \(String(format: "%.2f", distKm)) km (Total: \(String(format: "%.2f", updatedUser.totalDistanceKm)) km)")
            }

            try await firestoreService.updateUser(updatedUser)
            authService.currentUser = updatedUser

            // Check for newly unlocked achievements
            let unlockedAchievements = try await firestoreService.checkAndUnlockAchievements(userId: uid, user: updatedUser)

            print("🏆 Achievement Check Complete:")
            print("   - Checked for user: \(uid)")
            print("   - Total workouts: \(allWorkouts.count)")
            print("   - Current streak: \(updatedUser.currentStreak)")
            print("   - Newly unlocked: \(unlockedAchievements.count)")
            for ach in unlockedAchievements {
                print("   - ✅ \(ach.achievementType.displayName)")
            }

            // Apply XP bonuses from achievements
            if !unlockedAchievements.isEmpty {
                let totalXPBonus = unlockedAchievements.reduce(0) { $0 + $1.achievementType.xpBonus }
                updatedUser.stats.xpCurrent += totalXPBonus
                updatedUser.stats.totalXP += totalXPBonus
                print("   💰 Total XP Bonus: +\(Int(totalXPBonus)) XP")

                // Recalculate level in case XP bonus causes level up
                updatedUser.stats = StatCalculator.recalculateStatsWithXP(stats: updatedUser.stats)
                try? await firestoreService.updateUser(updatedUser)
                authService.currentUser = updatedUser
            }

            // Post achievement unlocks to feed
            if let groupId = user.groupId {
                for achievement in unlockedAchievements {
                    let feedItem = FeedItem(
                        groupId: groupId,
                        userId: uid,
                        userName: user.displayName,
                        type: .achievement,
                        content: "\(user.displayName) unlocked \(achievement.achievementType.displayName) — \(achievement.achievementType.description)!"
                    )
                    try? await firestoreService.postFeedItem(feedItem)
                }
            }

            // Show celebration if achievements were unlocked
            if !unlockedAchievements.isEmpty {
                print("🎉 Showing celebration for \(unlockedAchievements.count) achievement(s)")
                newAchievements = unlockedAchievements
                showAchievementCelebration = true

                // Trigger success haptic
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.success)

                // Auto-dismiss celebration after 3 seconds, then dismiss workout sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showAchievementCelebration = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            } else {
                print("ℹ️ No new achievements unlocked")
                dismiss()
            }
        } catch {
            print("Failed to save workout: \(error)")
        }

        isSaving = false
    }

    private func intensityEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "😌"
        case 2: return "🙂"
        case 3: return "😤"
        case 4: return "🔥"
        case 5: return "💀"
        default: return "😤"
        }
    }

    private func intensityLabel(_ level: Int) -> String {
        switch level {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Medium"
        case 4: return "Hard"
        case 5: return "Max"
        default: return "Medium"
        }
    }

    private func strengthWeightKg() -> Double? {
        guard selectedType == .strength else { return nil }
        switch strengthUnit {
        case .kg: return strengthWeight
        case .lb: return strengthWeight * 0.45359237
        }
    }

    private func distanceInKm() -> Double? {
        guard selectedType == .running || selectedType == .cycling || selectedType == .swimming || selectedType == .walking else { return nil }
        guard distance > 0 else { return nil }
        switch distanceUnit {
        case .km: return distance
        case .mi: return distance * 1.60934
        }
    }

    private func applyPreferredUnitIfNeeded() {
        // Apply strength unit preference
        let preferredStrength = preferredStrengthUnit
        if strengthUnit != preferredStrength {
            strengthWeight = convertWeight(strengthWeight, from: strengthUnit, to: preferredStrength)
            strengthUnit = preferredStrength
        }

        // Apply distance unit preference
        let preferredDistance = preferredDistanceUnit
        if distanceUnit != preferredDistance {
            distance = convertDistance(distance, from: distanceUnit, to: preferredDistance)
            distanceUnit = preferredDistance
        }
    }

    private func convertWeight(_ value: Double, from: StrengthUnit, to: StrengthUnit) -> Double {
        guard from != to else { return value }
        switch (from, to) {
        case (.lb, .kg): return value * 0.45359237
        case (.kg, .lb): return value / 0.45359237
        default: return value
        }
    }

    private func convertDistance(_ value: Double, from: DistanceUnit, to: DistanceUnit) -> Double {
        guard from != to else { return value }
        switch (from, to) {
        case (.mi, .km): return value * 1.60934
        case (.km, .mi): return value / 1.60934
        default: return value
        }
    }

    private func estimateHeartRate() -> Double? {
        guard !healthKitService.isAuthorized else { return nil }
        let base: Double
        switch intensity {
        case 1: base = 100
        case 2: base = 115
        case 3: base = 130
        case 4: base = 150
        case 5: base = 165
        default: base = 130
        }
        return base + (selectedType == .hiit ? 10 : 0)
    }
}

// MARK: - Achievement Celebration Overlay
private struct AchievementCelebrationOverlay: View {
    let achievements: [Achievement]
    @State private var animate = false
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ForEach(achievements) { achievement in
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.cardGold.opacity(0.2))
                                .frame(width: 100, height: 100)
                            Image(systemName: achievement.achievementType.icon)
                                .font(.system(size: 44))
                                .foregroundColor(.cardGold)
                        }
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .opacity(animate ? 1.0 : 0.0)

                        Text(achievement.achievementType.displayName)
                            .font(.pixel(14))
                            .foregroundColor(.white)

                        Text(achievement.achievementType.description)
                            .font(.secondary(13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Text("+\(Int(achievement.achievementType.xpBonus)) XP")
                                .font(.pixel(12))
                                .foregroundColor(.cardGold)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cardGold)
                        }
                        .padding(.top, 4)

                        Text("UNLOCKED")
                            .font(.pixel(10))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.cardGold)
                            .cornerRadius(4)

                        // Share button
                        if let userName = authService.currentUser?.displayName {
                            ShareLink(item: shareText(for: achievement, userName: userName)) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.secondary(12, weight: .bold))
                                .foregroundColor(.cardGold)
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cardDarkGray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cardGold.opacity(0.6), lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 40)

            ConfettiView()
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animate = true
            }
        }
    }

    private func shareText(for achievement: Achievement, userName: String) -> String {
        let xpBonus = Int(achievement.achievementType.xpBonus)
        return """
        🏆 Achievement Unlocked!

        \(achievement.achievementType.displayName)
        \(achievement.achievementType.description)

        +\(xpBonus) XP earned by \(userName)

        💪 Muscle Daddies
        """
    }
}

private struct ConfettiView: View {
    @State private var animate = false

    private let colors: [Color] = [
        .cardGold, .orange, .statGreen, .statBlue, .statPurple, .white
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<60, id: \.self) { i in
                let size = CGFloat(Int.random(in: 4...10))
                let x = CGFloat(Int.random(in: 0...Int(geo.size.width)))
                let y = CGFloat(Int.random(in: -50...0))
                RoundedRectangle(cornerRadius: 1)
                    .fill(colors[i % colors.count])
                    .frame(width: size, height: size * 1.6)
                    .position(x: x, y: animate ? geo.size.height + 40 : y)
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeIn(duration: Double.random(in: 1.2...2.2))
                        .delay(Double.random(in: 0...0.4)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
