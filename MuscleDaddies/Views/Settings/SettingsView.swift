import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var healthKitService: HealthKitService
    @AppStorage("unitsSystem") private var unitsSystemRaw: String = Constants.UnitsSystem.imperial.rawValue
    @State private var selectedTheme: Constants.CardTheme = .modern
    @State private var classTheme: Constants.ClassTheme = .fantasy
    @State private var selectedClass: Constants.MuscleClass = .warrior
    @State private var showHealthKitInfo = false
    @State private var showClassSuggest = false
    @State private var showClassSelect = false
    @State private var showSuggestedClassSheet = false
    @State private var suggestedClass: Constants.MuscleClass = .warrior
    @State private var pendingClassSelection: Constants.MuscleClass?
    @State private var displayNameDraft = ""
    @State private var tempDisplayName = ""
    @State private var demoXP: Double = 0
    @State private var showGuidedOnboarding = false

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
                                        .font(.pixel(14))
                                        .foregroundColor(.black)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.currentUser?.displayName ?? "")
                                    .font(.pixel(10))
                                    .foregroundColor(.white)
                                Text("Level \(authService.currentUser?.stats.level ?? 1)")
                                    .font(.secondary(15))
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.cardDarkGray)
                    }

                    Section("Display Name") {
                        TextField("Display Name", text: $displayNameDraft)
                            .textFieldStyle(.roundedBorder)

                        Button("Save Display Name") {
                            Task { await updateDisplayName() }
                        }
                        .foregroundColor(.cardGold)
                        .disabled(displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .listRowBackground(Color.cardDarkGray)

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
                                .font(.secondary(12))
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
                                pendingClassSelection = cls
                            } label: {
                                HStack {
                                    Text(cls.displayName)
                                        .font(.secondary(17))
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
                                        .font(.secondary(12))
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

                    // Units
                    Section("Units") {
                        Picker("Measurement System", selection: $unitsSystemRaw) {
                            ForEach(Constants.UnitsSystem.allCases, id: \.rawValue) { system in
                                Text(system.displayName).tag(system.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.cardDarkGray)
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

                    }

                    // Daddy Setup
                    Section("Daddy Setup") {
                        Button("Suggest Daddy for Me") {
                            suggestedClass = suggestClass()
                            showSuggestedClassSheet = true
                        }
                        .foregroundColor(.cardGold)
                        .listRowBackground(Color.cardDarkGray)

                        Button("Build Your Daddy") {
                            tempDisplayName = authService.currentUser?.displayName ?? ""
                            showClassSelect = true
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.cardDarkGray)

                        Button("Reset Priorities") {
                            Task { await resetPriorities() }
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.cardDarkGray)
                    }

#if DEBUG
                    Section("Demo Tools") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total XP")
                                .font(.secondary(12, weight: .semibold))
                                .foregroundColor(.gray)
                            Slider(value: $demoXP, in: 0...100_000, step: 100)
                                .tint(.cardGold)
                            Text("\(Int(demoXP)) XP")
                                .font(.secondary(12, weight: .semibold))
                                .foregroundColor(.white)
                            Button("Apply XP") {
                                Task { await applyDemoXP() }
                            }
                            .foregroundColor(.cardGold)
                        }
                        .listRowBackground(Color.cardDarkGray)

                        Button("Launch Onboarding") {
                            showGuidedOnboarding = true
                        }
                        .foregroundColor(.white)
                        .listRowBackground(Color.cardDarkGray)
                    }
#endif

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
                tempDisplayName = authService.currentUser?.displayName ?? ""
                displayNameDraft = authService.currentUser?.displayName ?? ""
                demoXP = authService.currentUser?.stats.totalXP ?? 0
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
            .sheet(isPresented: $showClassSuggest) {
                OnboardingView(displayName: $tempDisplayName, mode: .suggest)
            }
            .sheet(isPresented: $showClassSelect) {
                OnboardingView(displayName: $tempDisplayName, mode: .select)
            }
            .sheet(isPresented: $showSuggestedClassSheet) {
                suggestedClassSheet
            }
            .sheet(isPresented: Binding(
                get: { pendingClassSelection != nil },
                set: { if !$0 { pendingClassSelection = nil } }
            )) {
                if let cls = pendingClassSelection {
                    classConfirmSheet(for: cls)
                }
            }
            .fullScreenCover(isPresented: $showGuidedOnboarding) {
                GuidedOnboardingFlowView()
                    .environmentObject(authService)
                    .environmentObject(healthKitService)
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

    private func updateDisplayName() async {
        guard var user = authService.currentUser else { return }
        let trimmed = displayNameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        user.displayName = trimmed
        authService.currentUser = user
        try? await firestoreService.updateUser(user)
    }

    private func weight(for stat: Constants.PriorityStat, weights: Constants.ClassWeights) -> Double {
        switch stat {
        case .strength: return weights.strength
        case .speed: return weights.speed
        case .endurance: return weights.endurance
        case .intelligence: return weights.intelligence
        }
    }

    private var suggestedClassSheet: some View {
        let baseUser = authService.currentUser ?? AppUser(displayName: "Demo Daddy")
        var previewUser = baseUser
        previewUser.selectedClass = suggestedClass
        previewUser.classTheme = classTheme
        previewUser.selectedTheme = classTheme.cardTheme

        return NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Suggested Class")
                        .font(.pixel(12))
                        .foregroundColor(.white)

                    CharacterCardView(user: previewUser)
                        .padding(.horizontal)

                    StatRadarView(
                        strength: suggestedClass.weights.strength * 100,
                        speed: suggestedClass.weights.speed * 100,
                        endurance: suggestedClass.weights.endurance * 100,
                        intelligence: suggestedClass.weights.intelligence * 100,
                        size: 200
                    )
                    .padding(.vertical, 4)

                    Text(suggestedClass.flavorDescription)
                        .font(.secondary(12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            showSuggestedClassSheet = false
                        }
                        .foregroundColor(.gray)

                        Spacer()

                        Button("Confirm") {
                            selectedClass = suggestedClass
                            updateClass(suggestedClass)
                            showSuggestedClassSheet = false
                        }
                        .foregroundColor(.black)
                        .frame(width: 140, height: 44)
                        .background(Color.cardGold)
                        .cornerRadius(6)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 20)
            }
        }
    }

    private func classConfirmSheet(for cls: Constants.MuscleClass) -> some View {
        let baseUser = authService.currentUser ?? AppUser(displayName: "Demo Daddy")
        var previewUser = baseUser
        previewUser.selectedClass = cls
        previewUser.classTheme = classTheme
        previewUser.selectedTheme = classTheme.cardTheme

        return NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Confirm Class")
                        .font(.pixel(12))
                        .foregroundColor(.white)

                    CharacterCardView(user: previewUser)
                        .padding(.horizontal)

                    StatRadarView(
                        strength: cls.weights.strength * 100,
                        speed: cls.weights.speed * 100,
                        endurance: cls.weights.endurance * 100,
                        intelligence: cls.weights.intelligence * 100,
                        size: 200
                    )
                    .padding(.vertical, 4)

                    Text(cls.flavorDescription)
                        .font(.secondary(12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            pendingClassSelection = nil
                        }
                        .foregroundColor(.gray)

                        Spacer()

                        Button("Confirm") {
                            selectedClass = cls
                            updateClass(cls)
                            pendingClassSelection = nil
                        }
                        .foregroundColor(.black)
                        .frame(width: 140, height: 44)
                        .background(Color.cardGold)
                        .cornerRadius(6)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 20)
            }
        }
    }

    private func suggestClass() -> Constants.MuscleClass {
        let classes = Constants.MuscleClass.allCases.filter { $0.theme == classTheme }
        guard !classes.isEmpty else { return .warrior }
        let primary = authService.currentUser?.priorityPrimary ?? .strength
        let secondary = authService.currentUser?.prioritySecondary ?? .endurance

        let scored = classes.map { cls -> (Constants.MuscleClass, Double) in
            let w = cls.weights
            let score = weight(for: primary, weights: w) * 0.6
                + weight(for: secondary, weights: w) * 0.4
            return (cls, score)
        }
        return scored.max(by: { $0.1 < $1.1 })?.0 ?? classes[0]
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

    private func resetPriorities() async {
        guard var user = authService.currentUser else { return }
        user.priorityPrimary = .strength
        user.prioritySecondary = .endurance
        authService.currentUser = user
        try? await firestoreService.updateUser(user)
    }

    private func applyDemoXP() async {
        guard var user = authService.currentUser else { return }
        let levelInfo = StatCalculator.levelInfoFromXP(demoXP)
        user.stats.level = levelInfo.level
        user.stats.xpCurrent = levelInfo.xpCurrent
        user.stats.xpToNext = levelInfo.xpToNext
        user.stats.totalXP = demoXP
        authService.currentUser = user
        try? await firestoreService.updateUser(user)
    }

    private func isThemeUnlocked(_ theme: Constants.ClassTheme) -> Bool {
        let level = authService.currentUser?.stats.level ?? 1
        if let requiredLevel = theme.unlockLevel {
            return level >= requiredLevel
        }
        let totalXP = authService.currentUser?.stats.totalXP ?? 0
        return totalXP >= theme.unlockXP
    }

    private func themeBadge(_ theme: Constants.ClassTheme) -> some View {
        let unlocked = isThemeUnlocked(theme)
        return HStack(spacing: 6) {
            Text(theme.displayName)
                .font(.secondary(11, weight: .bold))
            if !unlocked {
                if let requiredLevel = theme.unlockLevel {
                    Text("🔒 LV \(requiredLevel)")
                        .font(.pixel(7))
                        .foregroundColor(.gray)
                } else {
                    Text("🔒 \(Int(theme.unlockXP)) XP")
                        .font(.pixel(7))
                        .foregroundColor(.gray)
                }
            } else {
                Text("Unlocked")
                    .font(.pixel(7))
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
                        .font(.pixel(12))
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
                            .font(.pixel(10))
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
                .font(.secondary(12, weight: .bold))
                .foregroundColor(.cardGold)
            Text(text)
                .font(.secondary(12))
                .foregroundColor(.gray)
        }
    }
}
