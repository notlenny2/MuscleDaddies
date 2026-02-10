import SwiftUI

struct XPRecoveryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var healthKitService: HealthKitService

    @State private var workouts: [Workout] = []
    @State private var recovery: RecoveryMetrics?
    @State private var recoveryHistory: [RecoveryMetrics] = []
    @State private var isLoading = true
    @State private var xpDays: Int = 14
    @State private var infoTitle: String = ""
    @State private var infoMessage: String = ""
    @State private var showInfo = false
    @State private var recoveryDays: Int = 14

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.cardGold)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            xpOverviewCard
                            recoveryCard
                            recoveryHistoryCard
                            hpCard
                            xpHistoryCard
                        }
                        .padding()
                    }
                    .refreshable { await loadData() }
                }
            }
            .navigationTitle("Progress")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await loadData() }
            .alert(infoTitle, isPresented: $showInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(infoMessage)
            }
        }
    }

    private var xpOverviewCard: some View {
        let user = authService.currentUser
        let streak = user?.currentStreak ?? 0
        let streakBoost = user?.stats.xpMultiplier ?? (1.0 + min(Double(streak) * 0.01, 0.25))

        return card {
            VStack(alignment: .leading, spacing: 12) {
                headerRow(
                    title: "XP Overview",
                    icon: "sparkles",
                    infoText: "XP is based on workout effort (energy, distance, heart rate) and volume. Streaks boost XP up to 25%."
                )

                if let stats = user?.stats {
                    ProgressBar(
                        label: "XP",
                        progress: stats.xpProgress,
                        valueText: "\(Int(stats.xpCurrent))/\(Int(stats.xpToNext))",
                        color: .cardGold
                    )

                    HStack(spacing: 12) {
                        statPill(label: "Level", value: "\(stats.level)", color: .cardGold)
                        statPill(label: "Streak", value: "\(streak)d", color: .orange)
                        statPill(label: "Boost", value: "+\(Int((streakBoost - 1.0) * 100))%", color: .statPurple)
                    }
                } else {
                    Text("No XP data yet.")
                        .font(.secondary(17))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var recoveryCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                headerRow(
                    title: "Recovery Signals",
                    icon: "heart.fill",
                    infoText: "Recovery uses recent sleep, mindfulness, HRV, resting HR, and heart‑rate recovery when available."
                )

                if let recovery {
                    VStack(spacing: 8) {
                        recoveryRow(label: "Sleep (avg 7d)", value: formatMinutes(recovery.sleepMinutes7d))
                        recoveryRow(label: "Mindful (avg 7d)", value: formatMinutes(recovery.mindfulMinutes7d))
                        recoveryRow(label: "HRV (SDNN)", value: formatValue(recovery.hrvSDNN, suffix: "ms"))
                        recoveryRow(label: "Resting HR", value: formatValue(recovery.restingHeartRate, suffix: "bpm"))
                        recoveryRow(label: "HRR 1‑min", value: formatValue(recovery.heartRateRecovery1Min, suffix: "bpm"))
                    }
                } else {
                    Text(healthKitService.isAuthorized ? "No recovery data yet." : "Authorize HealthKit to see recovery data.")
                        .font(.secondary(17))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var recoveryHistoryCard: some View {
        let series = recoverySeries(days: recoveryDays)
        return card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    headerRow(
                        title: "Recovery History",
                        icon: "waveform.path.ecg",
                        infoText: "Daily recovery score derived from sleep and heart metrics. Higher is better."
                    )
                    Spacer()
                    Picker("Range", selection: $recoveryDays) {
                        Text("14d").tag(14)
                        Text("30d").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 130)
                }

                if series.isEmpty {
                    Text("No recovery history yet.")
                        .font(.secondary(17))
                        .foregroundColor(.gray)
                } else {
                    DailyRecoveryChart(series: series)
                        .frame(height: 120)
                }
            }
        }
    }

    private var hpCard: some View {
        let stats = authService.currentUser?.stats
        return card {
            VStack(alignment: .leading, spacing: 12) {
                headerRow(
                    title: "HP & Load",
                    icon: "bolt.heart",
                    infoText: "HP drops with high 7‑day training load and rises with recovery. Low HP means your body needs rest."
                )

                if let stats {
                    let hpRatio = stats.hpMax > 0 ? stats.hpCurrent / stats.hpMax : 0
                    let hpColor: Color = hpRatio < 0.35 ? .statRed : (hpRatio < 0.6 ? .orange : .statGreen)
                    ProgressBar(
                        label: "HP",
                        progress: hpRatio,
                        valueText: "\(Int(stats.hpCurrent))/\(Int(stats.hpMax))",
                        color: hpColor
                    )

                    let load = recentLoadScore()
                    HStack(spacing: 12) {
                        statPill(label: "7d Load", value: "\(Int(load))", color: .statBlue)
                        statPill(label: "Recovery", value: "\(Int(stats.intelligence))", color: .statPurple)
                    }
                } else {
                    Text("No HP data yet.")
                        .font(.secondary(17))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var xpHistoryCard: some View {
        let series = dailyXPSeries(days: xpDays)
        return card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    headerRow(
                        title: "XP History",
                        icon: "chart.bar.fill",
                        infoText: "Daily XP from workouts. The view reflects your streak boost."
                    )
                    Spacer()
                    Picker("Range", selection: $xpDays) {
                        Text("14d").tag(14)
                        Text("30d").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 130)
                }
                HStack {
                    Text("Multiplier: x\(String(format: "%.2f", authService.currentUser?.stats.xpMultiplier ?? 1.0))")
                        .font(.pixel(7))
                        .foregroundColor(.gray)
                    Spacer()
                }

                if series.isEmpty {
                    Text("No recent workouts.")
                        .font(.secondary(17))
                        .foregroundColor(.gray)
                } else {
                    DailyXPChart(series: series)
                        .frame(height: 120)
                }
            }
        }
    }

    private func loadData() async {
        guard let uid = authService.currentUser?.id else {
            isLoading = false
            return
        }
        isLoading = true

        do {
            let since = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            workouts = try await firestoreService.getWorkouts(userId: uid, since: since)
        } catch {
            workouts = []
        }

        recoveryHistory = (try? await firestoreService.getRecoveryMetrics(userId: uid, days: max(recoveryDays, 30))) ?? []
        if healthKitService.isAuthorized {
            recovery = await healthKitService.fetchRecoveryMetrics()
        }

        isLoading = false
    }

    private func dailyXPSeries(days: Int) -> [(Date, Double)] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end

        var dayMap: [Date: Double] = [:]
        for i in 0..<days {
            if let day = calendar.date(byAdding: .day, value: i, to: start) {
                dayMap[day] = 0
            }
        }

        let streakBoost = currentStreakBoost()
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.createdAt)
            if day >= start && day <= end {
                let base = StatCalculator.xpForWorkout(workout)
                dayMap[day, default: 0] += base * (1.0 + streakBoost)
            }
        }

        return dayMap.keys.sorted().map { ($0, dayMap[$0] ?? 0) }
    }

    private func recoverySeries(days: Int) -> [(Date, Double)] {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end

        var dayMap: [Date: Double] = [:]
        for i in 0..<days {
            if let day = calendar.date(byAdding: .day, value: i, to: start) {
                dayMap[day] = 0
            }
        }

        for metric in recoveryHistory {
            guard let capturedAt = metric.capturedAt else { continue }
            let day = calendar.startOfDay(for: capturedAt)
            if day >= start && day <= end {
                dayMap[day, default: 0] = recoveryScore(metric)
            }
        }

        return dayMap.keys.sorted().map { ($0, dayMap[$0] ?? 0) }
    }

    private func recoveryScore(_ metric: RecoveryMetrics) -> Double {
        var scores: [Double] = []
        if let sleepMinutes = metric.sleepMinutes7d {
            let sleepHours = sleepMinutes / 60.0
            let delta = abs(sleepHours - 8.0)
            let sleepScore = max(0.0, 1.0 - min(delta / 4.0, 1.0))
            scores.append(sleepScore)
        }
        if let mindfulMinutes = metric.mindfulMinutes7d {
            scores.append(min(mindfulMinutes / 20.0, 1.0))
        }
        if let hrv = metric.hrvSDNN {
            scores.append(min(max((hrv - 20.0) / 80.0, 0.0), 1.0))
        }
        if let restingHR = metric.restingHeartRate {
            scores.append(min(max((90.0 - restingHR) / 40.0, 0.0), 1.0))
        }
        if let hrr = metric.heartRateRecovery1Min {
            scores.append(min(max((hrr - 10.0) / 30.0, 0.0), 1.0))
        }
        guard !scores.isEmpty else { return 0 }
        let avg = scores.reduce(0, +) / Double(scores.count)
        return avg * 100.0
    }

    private func recentLoadScore() -> Double {
        let last7 = workouts.filter { $0.createdAt >= Date().daysAgo(7) }
        return last7.reduce(0.0) { $0 + StatCalculator.xpForWorkout($1) }
    }

    private func currentStreakBoost() -> Double {
        let streak = StatCalculator.calculateStreak(workouts: workouts).current
        return min(Double(streak) * 0.01, 0.25)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cardDarkGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }

    private func headerRow(title: String, icon: String, infoText: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cardGold)
            Text(title)
                .font(.pixel(10))
                .foregroundColor(.white)
            if let infoText {
                Button {
                    infoTitle = title
                    infoMessage = infoText
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.pixel(10))
                .foregroundColor(color)
            Text(label)
                .font(.pixel(7))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.2))
        )
    }

    private func recoveryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.secondary(12, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.pixel(8))
                .foregroundColor(.white)
        }
    }

    private func formatMinutes(_ minutes: Double?) -> String {
        guard let minutes else { return "—" }
        if minutes >= 60 {
            return String(format: "%.1fh", minutes / 60.0)
        }
        return String(format: "%.0fm", minutes)
    }

    private func formatValue(_ value: Double?, suffix: String) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f%@", value, suffix)
    }
}

private struct DailyXPChart: View {
    let series: [(Date, Double)]
    private let segments = 5

    var body: some View {
        let maxValue = max(series.map { $0.1 }.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(series.indices, id: \.self) { index in
                let value = series[index].1
                let ratio = value / maxValue
                let filled = Int(ratio * Double(segments))
                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        ForEach((0..<segments).reversed(), id: \.self) { i in
                            Rectangle()
                                .fill(i < filled ? Color.cardGold : Color.white.opacity(0.06))
                                .frame(height: 14)
                        }
                    }

                    Text(shortDay(series[index].0))
                        .font(.pixel(6))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

private struct DailyRecoveryChart: View {
    let series: [(Date, Double)]
    private let segments = 5

    var body: some View {
        let maxValue = max(series.map { $0.1 }.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(series.indices, id: \.self) { index in
                let value = series[index].1
                let ratio = value / maxValue
                let filled = Int(ratio * Double(segments))
                VStack(spacing: 4) {
                    VStack(spacing: 2) {
                        ForEach((0..<segments).reversed(), id: \.self) { i in
                            Rectangle()
                                .fill(i < filled ? Color.statPurple : Color.white.opacity(0.06))
                                .frame(height: 14)
                        }
                    }

                    Text(shortDay(series[index].0))
                        .font(.pixel(6))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func shortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
