import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var healthKitService: HealthKitService
    @State private var selectedTheme: Constants.CardTheme = .modern
    @State private var classTheme: Constants.ClassTheme = .fantasy
    @State private var selectedClass: Constants.MuscleClass = .warrior
    @State private var showHealthKitInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                List {
                    // Profile
                    Section {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardGold)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(authService.currentUser?.displayName.prefix(1).uppercased() ?? "?"))
                                        .font(.system(size: 22, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.currentUser?.displayName ?? "")
                                    .font(.system(.headline, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("Level \(authService.currentUser?.stats.level ?? 1)")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.cardDarkGray)
                    }

                    // Class Theme
                    Section("Class Theme") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                themeBadge(.fantasy)
                                themeBadge(.sports)
                                themeBadge(.scifi)
                            }
                            .padding(.bottom, 6)

                            Picker("Class Theme", selection: $classTheme) {
                                ForEach(Constants.ClassTheme.allCases, id: \.rawValue) { theme in
                                    Text(theme.displayName).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Fantasy is default. Earn XP to unlock Sports and Sci‑Fi.")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color.cardDarkGray)
                        .onChange(of: classTheme) { _, newTheme in
                            guard isThemeUnlocked(newTheme) else {
                                classTheme = .fantasy
                                return
                            }
                            let available = Constants.MuscleClass.allCases.filter { $0.theme == newTheme }
                            if let first = available.first {
                                selectedClass = first
                                updateClass(first)
                            }
                            updateClassTheme(newTheme)
                            selectedTheme = newTheme.cardTheme
                            updateTheme(selectedTheme)
                        }
                    }

                    Section("Class") {
                        ForEach(Constants.MuscleClass.allCases.filter { $0.theme == classTheme }, id: \.rawValue) { cls in
                            Button {
                                selectedClass = cls
                                updateClass(cls)
                            } label: {
                                HStack {
                                    Text(cls.displayName)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedClass == cls {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.cardGold)
                                    }
                                }
                            }
                            .listRowBackground(Color.cardDarkGray)
                        }
                    }

                    // HealthKit
                    Section("Health Data") {
                        if healthKitService.isAvailable {
                            HStack {
                                Label("Apple Health", systemImage: "heart.fill")
                                    .foregroundColor(.white)
                                Spacer()
                                if healthKitService.isAuthorized {
                                    Text("Connected")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.green)
                                } else {
                                    Button("Connect") {
                                        showHealthKitInfo = true
                                    }
                                    .foregroundColor(.cardGold)
                                }
                            }
                            .listRowBackground(Color.cardDarkGray)
                        }
                    }

                    // Navigation
                    Section {
                        NavigationLink(destination: WorkoutHistoryView()) {
                            Label("Workout History", systemImage: "clock.fill")
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.cardDarkGray)

                        NavigationLink(destination: AchievementsView()) {
                            Label("Achievements", systemImage: "star.fill")
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.cardDarkGray)

                        NavigationLink(destination: ChallengeView()) {
                            Label("Challenges", systemImage: "trophy.fill")
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.cardDarkGray)
                    }

                    // Sign Out
                    Section {
                        Button(role: .destructive) {
                            authService.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .listRowBackground(Color.cardDarkGray)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                classTheme = authService.currentUser?.classTheme ?? .fantasy
                selectedClass = authService.currentUser?.selectedClass ?? .warrior
                let derivedTheme = classTheme.cardTheme
                selectedTheme = derivedTheme
                if authService.currentUser?.selectedTheme != derivedTheme {
                    updateTheme(derivedTheme)
                }
            }
            .sheet(isPresented: $showHealthKitInfo) {
                HealthKitEducationView {
                    Task {
                        _ = await healthKitService.requestAuthorization()
                    }
                }
            }
        }
    }

    private func updateTheme(_ theme: Constants.CardTheme) {
        guard var user = authService.currentUser else { return }
        user.selectedTheme = theme
        authService.currentUser = user
        Task {
            try? await firestoreService.updateUser(user)
        }
    }

    private func updateClassTheme(_ theme: Constants.ClassTheme) {
        guard var user = authService.currentUser else { return }
        user.classTheme = theme
        authService.currentUser = user
        Task {
            try? await firestoreService.updateUser(user)
        }
    }

    private func updateClass(_ cls: Constants.MuscleClass) {
        guard var user = authService.currentUser else { return }
        user.selectedClass = cls
        authService.currentUser = user
        Task {
            let workouts = try? await firestoreService.getWorkouts(userId: user.id ?? "")
            let recovery = healthKitService.isAuthorized ? await healthKitService.fetchRecoveryMetrics() : nil
            if let workouts {
                user.stats = StatCalculator.calculateStats(workouts: workouts, recovery: recovery, selectedClass: cls)
                authService.currentUser = user
            }
            try? await firestoreService.updateUser(user)
        }
    }

    private func isThemeUnlocked(_ theme: Constants.ClassTheme) -> Bool {
        let totalXP = authService.currentUser?.stats.totalXP ?? 0
        return totalXP >= theme.unlockXP
    }

    private func themeBadge(_ theme: Constants.ClassTheme) -> some View {
        let unlocked = isThemeUnlocked(theme)
        return HStack(spacing: 6) {
            Text(theme.displayName)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            if !unlocked {
                Text("🔒 \(Int(theme.unlockXP)) XP")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.gray)
            } else {
                Text("Unlocked")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cardDarkGray.opacity(0.6))
        )
    }
}

private struct HealthKitEducationView: View {
    var onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.cardGold)

                    Text("Connect Apple Health")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 10) {
                        infoRow(title: "Workouts", text: "Import workouts, energy, distance, and heart‑rate data.")
                        infoRow(title: "Recovery", text: "Use sleep, HRV, and resting HR to power recovery and HP.")
                        infoRow(title: "Privacy", text: "We only read health data. You can disconnect anytime.")
                    }
                    .padding(.horizontal, 24)

                    Button {
                        onContinue()
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.cardGold)
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 40)

                    Button("Not Now") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoRow(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cardGold)
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
