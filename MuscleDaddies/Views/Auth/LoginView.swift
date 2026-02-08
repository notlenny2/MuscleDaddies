import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showOnboarding = false
    @State private var displayName = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.cardDark, Color(red: 0.15, green: 0.05, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo / Title
                VStack(spacing: 12) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(colors: [.statRed, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    Text("MUSCLE\nDADDIES")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom)
                        )

                    Text("Turn your workouts into an RPG")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    let appleRequest = authService.handleSignInWithApple()
                    request.requestedScopes = appleRequest.requestedScopes
                    request.nonce = appleRequest.nonce
                }
                onCompletion: { result in
                    Task {
                        await authService.handleSignInWithAppleCompletion(result: result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 54)
                .cornerRadius(4)
                .padding(.horizontal, 40)

                if let error = authService.error {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(displayName: $displayName, mode: .suggest)
        }
        .onChange(of: authService.isAuthenticated) { _, isAuth in
            if isAuth && authService.currentUser == nil {
                showOnboarding = true
            }
        }
    }
}

struct OnboardingView: View {
    enum ClassSelectionMode {
        case suggest
        case select
    }

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var healthKitService: HealthKitService
    @Binding var displayName: String
    @Environment(\.dismiss) private var dismiss
    @State private var classTheme: Constants.ClassTheme = .fantasy
    @State private var selectedClass: Constants.MuscleClass = .warrior
    @State private var primaryPriority: Constants.PriorityStat = .strength
    @State private var secondaryPriority: Constants.PriorityStat = .endurance
    @State private var heightCmText: String = ""
    @State private var weightKgText: String = ""
    @State private var heightCategory: Constants.HeightCategory = .medium
    @State private var bodyType: Constants.BodyType = .medium
    @State private var targetSpeedMph: String = ""
    @State private var targetWeeklyDistanceMiles: String = ""
    @State private var strengthChecksPerLevel: Int = 1
    let mode: ClassSelectionMode

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cardDark, Color(red: 0.12, green: 0.05, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("MUSCLE DADDIES")
                                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(2)

                            Text("Create Your Card")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold)
                        }
                        .padding(.top, 10)

                        HStack(spacing: 8) {
                            Text("STEP 1")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold)
                            Text("Profile")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("•")
                                .foregroundColor(.gray)
                            Text("STEP 2")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(.cardGold.opacity(0.7))
                            Text("Class")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Name")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            TextField("Display Name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Theme (Unlocks)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            HStack(spacing: 10) {
                                themeBadge(.fantasy, totalXP: 0)
                                themeBadge(.sports, totalXP: 0)
                                themeBadge(.scifi, totalXP: 0)
                            }

                            Text("Fantasy is default. Other themes unlock with XP.")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Priorities (Pick Top 2)")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            priorityPicker(title: "Primary", selection: $primaryPriority, excludes: nil)
                            priorityPicker(title: "Secondary", selection: $secondaryPriority, excludes: primaryPriority)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Body Basics")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            if healthKitService.isAuthorized {
                                Button {
                                    Task {
                                        let hw = await healthKitService.fetchMostRecentHeightWeight()
                                        if let h = hw.heightCm { heightCmText = String(format: "%.0f", h) }
                                        if let w = hw.weightKg { weightKgText = String(format: "%.1f", w) }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                        Text("Pull Height/Weight from Apple Health")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.cardGold)
                                }
                            } else {
                                Text("Apple Health not connected — you can enter body type instead.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.gray)
                            }

                            HStack(spacing: 10) {
                                TextField("Height (cm)", text: $heightCmText)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Weight (kg)", text: $weightKgText)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack(spacing: 10) {
                                heightPicker(title: "Height", selection: $heightCategory)
                                bodyTypePicker(title: "Body", selection: $bodyType)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goals")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            TextField("Target Speed (mph)", text: $targetSpeedMph)
                                .textFieldStyle(.roundedBorder)

                            TextField("Weekly Distance Goal (miles)", text: $targetWeeklyDistanceMiles)
                                .textFieldStyle(.roundedBorder)

                            Stepper("Strength Checks per Level: \(strengthChecksPerLevel)", value: $strengthChecksPerLevel, in: 0...3)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(mode == .suggest ? "Suggested Class" : "Select Your Class")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)

                            let options = mode == .suggest ? classOptions() : allAvailableClasses()
                            ForEach(options, id: \.self) { cls in
                                Button {
                                    selectedClass = cls
                                } label: {
                                    HStack {
                                        Text(cls.displayName)
                                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedClass == cls {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.cardGold)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedClass == cls ? Color.cardGold.opacity(0.18) : Color.cardDarkGray)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(selectedClass == cls ? Color.cardGold.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardDarkGray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        Button {
                            Task {
                                let heightCm = Double(heightCmText)
                                let weightKg = Double(weightKgText)
                                let goals = UserGoals(
                                    targetSpeedMph: Double(targetSpeedMph),
                                    targetWeeklyDistanceMiles: Double(targetWeeklyDistanceMiles),
                                    targetStrengthChecksPerLevel: strengthChecksPerLevel
                                )
                                await authService.applyOnboardingUpdates(
                                    displayName: displayName,
                                    classTheme: classTheme,
                                    selectedClass: selectedClass,
                                    priorityPrimary: primaryPriority,
                                    prioritySecondary: secondaryPriority,
                                    heightCm: heightCm,
                                    weightKg: weightKg,
                                    heightCategory: heightCm != nil ? nil : heightCategory,
                                    bodyType: weightKg != nil ? nil : bodyType,
                                    goals: goals
                                )
                                dismiss()
                            }
                        } label: {
                            Text("Forge My Card")
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.cardGold)
                                .cornerRadius(4)
                                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                        }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: primaryPriority) { _, _ in
            if let first = classOptions().first { selectedClass = first }
        }
        .onChange(of: secondaryPriority) { _, _ in
            if let first = classOptions().first { selectedClass = first }
        }
        .onAppear {
            if let user = authService.currentUser {
                displayName = user.displayName
                classTheme = user.classTheme
                selectedClass = user.selectedClass
                primaryPriority = user.priorityPrimary
                secondaryPriority = user.prioritySecondary
                if let h = user.heightCm { heightCmText = String(format: "%.0f", h) }
                if let w = user.weightKg { weightKgText = String(format: "%.1f", w) }
                if let hc = user.heightCategory { heightCategory = hc }
                if let bt = user.bodyType { bodyType = bt }
                if let g = user.goals {
                    if let v = g.targetSpeedMph { targetSpeedMph = String(format: "%.1f", v) }
                    if let v = g.targetWeeklyDistanceMiles { targetWeeklyDistanceMiles = String(format: "%.0f", v) }
                    if let v = g.targetStrengthChecksPerLevel { strengthChecksPerLevel = v }
                }
            }
            if mode == .suggest, let first = classOptions().first {
                selectedClass = first
            }
        }
    }
}

private extension OnboardingView {
    func themeBadge(_ theme: Constants.ClassTheme, totalXP: Double) -> some View {
        let unlocked = totalXP >= theme.unlockXP
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

    func priorityPicker(title: String, selection: Binding<Constants.PriorityStat>, excludes: Constants.PriorityStat?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)

            HStack(spacing: 8) {
                ForEach(Constants.PriorityStat.allCases, id: \.rawValue) { stat in
                    let isDisabled = excludes == stat
                    Button {
                        if !isDisabled { selection.wrappedValue = stat }
                    } label: {
                        Text(stat.displayName.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(selection.wrappedValue == stat ? .black : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selection.wrappedValue == stat ? Color.cardGold : Color.cardDark)
                            )
                            .opacity(isDisabled ? 0.4 : 1)
                    }
                    .disabled(isDisabled)
                }
            }
        }
    }

    func heightPicker(title: String, selection: Binding<Constants.HeightCategory>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
            Picker(title, selection: selection) {
                ForEach(Constants.HeightCategory.allCases, id: \.rawValue) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.cardGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func bodyTypePicker(title: String, selection: Binding<Constants.BodyType>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
            Picker(title, selection: selection) {
                ForEach(Constants.BodyType.allCases, id: \.rawValue) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.cardGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func classOptions() -> [Constants.MuscleClass] {
        let classes = Constants.MuscleClass.allCases.filter { $0.theme == .fantasy }
        guard !classes.isEmpty else { return [] }

        let scored = classes.map { cls -> (Constants.MuscleClass, Double) in
            let w = cls.weights
            let score = weight(for: primaryPriority, weights: w) * 0.6
                + weight(for: secondaryPriority, weights: w) * 0.4
            return (cls, score)
        }
        let sorted = scored.sorted { $0.1 > $1.1 }.map { $0.0 }
        let best = sorted.first ?? .warrior
        let second = sorted.dropFirst().first ?? best
        let opposite = oppositeClass(for: primaryPriority, in: classes) ?? best
        return Array(LinkedHashSet([best, second, opposite]))
    }

    func allAvailableClasses() -> [Constants.MuscleClass] {
        Constants.MuscleClass.allCases.filter { $0.theme == classTheme }
    }

    func weight(for stat: Constants.PriorityStat, weights: Constants.ClassWeights) -> Double {
        switch stat {
        case .strength: return weights.strength
        case .speed: return weights.speed
        case .endurance: return weights.endurance
        case .intelligence: return weights.intelligence
        }
    }

    func oppositeClass(for stat: Constants.PriorityStat, in classes: [Constants.MuscleClass]) -> Constants.MuscleClass? {
        let oppositeStat: Constants.PriorityStat
        switch stat {
        case .strength: oppositeStat = .speed
        case .speed: oppositeStat = .strength
        case .endurance: oppositeStat = .intelligence
        case .intelligence: oppositeStat = .endurance
        }
        return classes.max { weight(for: oppositeStat, weights: $0.weights) < weight(for: oppositeStat, weights: $1.weights) }
    }
}

private struct LinkedHashSet<Element: Hashable>: Sequence {
    private var ordered: [Element] = []
    private var set: Set<Element> = []

    init(_ elements: [Element]) {
        for element in elements {
            if !set.contains(element) {
                set.insert(element)
                ordered.append(element)
            }
        }
    }

    func makeIterator() -> IndexingIterator<[Element]> {
        ordered.makeIterator()
    }
}
