import SwiftUI

struct GuidedOnboardingFlowView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var healthKitService: HealthKitService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("unitsSystem") private var unitsSystemRaw: String = Constants.UnitsSystem.imperial.rawValue

    @State private var stepIndex: Int = 0
    @State private var displayName: String = ""
    @State private var primaryPriority: Constants.PriorityStat = .strength
    @State private var secondaryPriority: Constants.PriorityStat = .endurance
    @State private var selectedClass: Constants.MuscleClass = .warrior
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var heightCategory: Constants.HeightCategory = .medium
    @State private var bodyType: Constants.BodyType = .medium
    @State private var targetSpeedMph: String = ""
    @State private var targetWeeklyDistanceMiles: String = ""
    @State private var strengthChecksPerLevel: Int = 1
    @State private var isSaving = false
    @State private var isTalking = false
    @State private var talkPhase = 0

    private let totalSteps = 4

    private var usesImperial: Bool {
        unitsSystemRaw == Constants.UnitsSystem.imperial.rawValue
    }

    private var heightPlaceholder: String {
        usesImperial ? "Height (in)" : "Height (cm)"
    }

    private var weightPlaceholder: String {
        usesImperial ? "Weight (lb)" : "Weight (kg)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cardDark, Color(red: 0.12, green: 0.05, blue: 0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    header

                    Group {
                        switch stepIndex {
                        case 0: welcomeStep
                        case 1: profileStep
                        case 2: bodyBasicsStep
                        default: classAndGoalsStep
                        }
                    }
                    .padding(.horizontal, 24)

                    warriorFooter

                    Spacer()

                    footer
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .interactiveDismissDisabled(true)
        }
        .onAppear {
            displayName = authService.currentUser?.displayName ?? ""
            isTalking = true
        }
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            talkPhase = (talkPhase + 1) % 3
        }
        .onChange(of: unitsSystemRaw) { oldValue, newValue in
            convertDisplayedMeasurements(from: oldValue, to: newValue)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("MUSCLE DADDIES")
                .font(.pixel(12))
                .foregroundColor(.white)
            Text("Forge Your Legend")
                .font(.pixel(9))
                .foregroundColor(.cardGold)

            Text("Step \(stepIndex + 1) of \(totalSteps)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Back") {
                stepIndex = max(0, stepIndex - 1)
            }
            .disabled(stepIndex == 0 || isSaving)
            .foregroundColor(.gray)

            Spacer()

            Button {
                Task { await nextOrFinish() }
            } label: {
                if isSaving {
                    ProgressView().tint(.black)
                } else {
                    Text(stepIndex == 0 ? "Begin the Trial" : (stepIndex == totalSteps - 1 ? "Forge My Card" : "Next"))
                        .font(.pixel(10))
                }
            }
            .foregroundColor(.black)
            .frame(width: 140, height: 48)
            .background(Color.cardGold)
            .cornerRadius(6)
            .disabled(!canProceed || isSaving)
        }
        .padding(.horizontal, 24)
    }

    private var warriorFooter: some View {
        HStack(alignment: .bottom, spacing: 12) {
            warriorBubble(text: warriorLine)
            Image("Warrior")
                .resizable()
                .scaledToFit()
                .frame(width: 184, height: 184)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private var warriorLine: String {
        switch stepIndex {
        case 0:
            return "Warrior: Hear me! This is the forging of legends."
        case 1:
            return "Warrior: Name yourself and claim your power!"
        case 2:
            return "Warrior: Temper your body—steel your form."
        default:
            return "Warrior: Choose your path and I shall guide you."
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Warrior’s Oath")
                .font(.pixel(10))
                .foregroundColor(.white)

            Text("By the power of the Forge, we will shape your legend in moments.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 10) {
                infoRow(title: "Warrior’s Decree", text: "Your choices fuel your class, stats, and XP.")
                infoRow(title: "No Fear", text: "You can refine your fate later in Settings.")
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.cardDarkGray))
        }
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Name Your Champion")
                .font(.pixel(9))
                .foregroundColor(.white)

            Text("Warrior: Speak your name, hero. Let it thunder across the realm.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)

            TextField("Display Name", text: $displayName)
                .textFieldStyle(.roundedBorder)

            Text("Pick Your Power")
                .font(.pixel(9))
                .foregroundColor(.white)

            Text("Warrior: Choose your might and speed, and the forge will follow your will.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)

            priorityPicker(title: "Primary", selection: $primaryPriority, excludes: nil)
            priorityPicker(title: "Secondary", selection: $secondaryPriority, excludes: primaryPriority)
        }
    }

    private var bodyBasicsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Forge Your Body")
                .font(.pixel(9))
                .foregroundColor(.white)

            Text("Warrior: Temper your frame. Strength and stature shape your legend.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)

            if healthKitService.isAuthorized {
                Button {
                    Task {
                        let hw = await healthKitService.fetchMostRecentHeightWeight()
                        if let h = hw.heightCm { heightText = displayHeightText(fromCm: h) }
                        if let w = hw.weightKg { weightText = displayWeightText(fromKg: w) }
                    }
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Pull from Apple Health")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cardGold)
                }
            } else {
                Button("Bind to Apple Health") {
                    Task {
                        _ = await healthKitService.requestAuthorization()
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.cardGold)
            }

            HStack(spacing: 10) {
                TextField(heightPlaceholder, text: $heightText)
                    .textFieldStyle(.roundedBorder)
                TextField(weightPlaceholder, text: $weightText)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 10) {
                heightPicker(title: "Height", selection: $heightCategory)
                bodyTypePicker(title: "Body", selection: $bodyType)
            }

            Text("Units default to Imperial. Change them anytime in Settings.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var classAndGoalsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose Your Class")
                .font(.pixel(9))
                .foregroundColor(.white)

            Text("Warrior: Choose the path that sings to your soul, and I will empower it.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)

            let options = classOptions()
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedClass == cls ? Color.cardGold.opacity(0.18) : Color.cardDarkGray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedClass == cls ? Color.cardGold.opacity(0.6) : Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }

            Text("Quests (optional)")
                .font(.pixel(9))
                .foregroundColor(.white)
                .padding(.top, 8)

            TextField("Target Speed (mph)", text: $targetSpeedMph)
                .textFieldStyle(.roundedBorder)

            TextField("Weekly Distance Goal (miles)", text: $targetWeeklyDistanceMiles)
                .textFieldStyle(.roundedBorder)

            Stepper("Strength Checks per Level: \(strengthChecksPerLevel)", value: $strengthChecksPerLevel, in: 0...3)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private var canProceed: Bool {
        switch stepIndex {
        case 0:
            return true
        case 1:
            return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return true
        default:
            return true
        }
    }

    private func nextOrFinish() async {
        if stepIndex < totalSteps - 1 {
            stepIndex += 1
            return
        }
        isSaving = true
        let heightCm = parseHeightCm()
        let weightKg = parseWeightKg()
        let goals = UserGoals(
            targetSpeedMph: Double(targetSpeedMph),
            targetWeeklyDistanceMiles: Double(targetWeeklyDistanceMiles),
            targetStrengthChecksPerLevel: strengthChecksPerLevel
        )
        await authService.applyOnboardingUpdates(
            displayName: displayName,
            classTheme: .fantasy,
            selectedClass: selectedClass,
            priorityPrimary: primaryPriority,
            prioritySecondary: secondaryPriority,
            heightCm: heightCm,
            weightKg: weightKg,
            heightCategory: heightCm != nil ? nil : heightCategory,
            bodyType: weightKg != nil ? nil : bodyType,
            goals: goals
        )
        isSaving = false
        dismiss()
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

private extension GuidedOnboardingFlowView {
    func warriorBubble(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(text)
                    .font(.system(size: 21, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.cardGold)
                            .frame(width: 10, height: 10)
                            .opacity(isTalking && index == talkPhase ? 1 : 0.35)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardDarkGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cardGold.opacity(0.4), lineWidth: 1)
                    )
            )

            Image(systemName: "bubble.right.fill")
                .font(.system(size: 12))
                .foregroundColor(Color.cardDarkGray)
                .offset(x: -6, y: 6)
        }
    }

    func displayHeightText(fromCm cm: Double) -> String {
        if usesImperial {
            let inches = cm / 2.54
            return String(format: "%.0f", inches)
        }
        return String(format: "%.0f", cm)
    }

    func displayWeightText(fromKg kg: Double) -> String {
        if usesImperial {
            let pounds = kg / 0.45359237
            return String(format: "%.1f", pounds)
        }
        return String(format: "%.1f", kg)
    }

    func parseHeightCm() -> Double? {
        guard let value = Double(heightText) else { return nil }
        return usesImperial ? value * 2.54 : value
    }

    func parseWeightKg() -> Double? {
        guard let value = Double(weightText) else { return nil }
        return usesImperial ? value * 0.45359237 : value
    }

    func convertDisplayedMeasurements(from oldRaw: String, to newRaw: String) {
        let oldImperial = oldRaw == Constants.UnitsSystem.imperial.rawValue
        let newImperial = newRaw == Constants.UnitsSystem.imperial.rawValue
        guard oldImperial != newImperial else { return }

        if let value = Double(heightText) {
            let cm = oldImperial ? value * 2.54 : value
            heightText = newImperial ? String(format: "%.0f", cm / 2.54) : String(format: "%.0f", cm)
        }

        if let value = Double(weightText) {
            let kg = oldImperial ? value * 0.45359237 : value
            weightText = newImperial ? String(format: "%.1f", kg / 0.45359237) : String(format: "%.1f", kg)
        }
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
    private var seen: Set<Element> = []
    private var ordered: [Element] = []

    init(_ elements: [Element]) {
        elements.forEach { append($0) }
    }

    mutating func append(_ element: Element) {
        if seen.insert(element).inserted {
            ordered.append(element)
        }
    }

    func makeIterator() -> IndexingIterator<[Element]> {
        ordered.makeIterator()
    }
}
