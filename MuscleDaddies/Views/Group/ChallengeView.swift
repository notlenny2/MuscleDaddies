import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var challenges: [BeltChallenge] = []
    @State private var isLoading = true
    @State private var showCreate = false
    @State private var groupMembers: [AppUser] = []
    @State private var beltHolders: BeltHolders?

    private var groupLabel: String {
        switch authService.currentUser?.classTheme {
        case .sports: return "Squad"
        case .scifi: return "Crew"
        default: return "Fellowship"
        }
    }

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cardGold)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        beltHeader
                        ForEach(challenges) { challenge in
                            BeltChallengeCard(
                                challenge: challenge,
                                members: groupMembers,
                                onAccept: { Task { await accept(challenge) } },
                                onDecline: { Task { await decline(challenge) } },
                                onResolve: { Task { await resolve(challenge) } }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("\(groupLabel) Belts")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.cardGold)
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateBeltChallengeSheet(members: groupMembers)
        }
        .task {
            await loadData()
        }
    }

    private var beltHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Belts")
                .font(.secondary(14, weight: .bold))
                .foregroundColor(.white)
            Text("One challenge at a time. Win the belt by gaining the most XP in the chosen stat.")
                .font(.secondary(11))
                .foregroundColor(.gray)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cardDarkGray)
        )
    }

    private func loadData() async {
        guard let groupId = authService.currentUser?.groupId else {
            isLoading = false
            return
        }
        do {
            challenges = try await firestoreService.getBeltChallenges(groupId: groupId)
            groupMembers = try await firestoreService.getGroupMembers(groupId: groupId)
            beltHolders = try await firestoreService.getBeltHolders(groupId: groupId)
        } catch {
            print("Failed to load belt data: \(error)")
        }
        isLoading = false
    }

    private func accept(_ challenge: BeltChallenge) async {
        guard var challenge = challenges.first(where: { $0.id == challenge.id }),
              let uid = authService.currentUser?.id else { return }
        guard challenge.status == .pending, challenge.opponentId == uid else { return }

        let now = Date()
        challenge.status = .active
        challenge.acceptedAt = now
        challenge.startDate = now
        challenge.endDate = Calendar.current.date(byAdding: .day, value: challenge.durationDays, to: now)

        try? await firestoreService.updateBeltChallenge(challenge)
        await applyChallengeBonus(to: uid, bonus: 100)
        await loadData()
    }

    private func decline(_ challenge: BeltChallenge) async {
        guard var challenge = challenges.first(where: { $0.id == challenge.id }),
              let uid = authService.currentUser?.id else { return }
        guard challenge.status == .pending, challenge.opponentId == uid else { return }

        challenge.status = .declined
        try? await firestoreService.updateBeltChallenge(challenge)
        await applyChallengeBonus(to: uid, bonus: -100)
        await loadData()
    }

    private func resolve(_ challenge: BeltChallenge) async {
        guard var challenge = challenges.first(where: { $0.id == challenge.id }),
              let start = challenge.startDate,
              let end = challenge.endDate,
              challenge.status == .active else { return }

        let challengerWorkouts = (try? await firestoreService.getWorkouts(userId: challenge.challengerId, from: start, to: end)) ?? []
        let opponentWorkouts = (try? await firestoreService.getWorkouts(userId: challenge.opponentId, from: start, to: end)) ?? []

        let challenger = groupMembers.first { $0.id == challenge.challengerId }
        let opponent = groupMembers.first { $0.id == challenge.opponentId }

        let challengerWeights = challenger?.selectedClass.weights ?? Constants.ClassWeights(strength: 0.25, speed: 0.25, endurance: 0.25, intelligence: 0.25)
        let opponentWeights = opponent?.selectedClass.weights ?? Constants.ClassWeights(strength: 0.25, speed: 0.25, endurance: 0.25, intelligence: 0.25)

        if challenge.stat == .overall {
            let challengerScore = StatCalculator.overallXP(for: challengerWorkouts, classWeights: challengerWeights)
            let opponentScore = StatCalculator.overallXP(for: opponentWorkouts, classWeights: opponentWeights)
            challenge.challengerScore = challengerScore
            challenge.opponentScore = opponentScore
        } else {
            let stat = mapStat(challenge.stat)
            let challengerWeight = weight(for: stat, weights: challengerWeights)
            let opponentWeight = weight(for: stat, weights: opponentWeights)
            let maxWeight = max(challengerWeight, opponentWeight)
            let challengerMultiplier = challengerWeight > 0 ? (maxWeight / challengerWeight) : 1.0
            let opponentMultiplier = opponentWeight > 0 ? (maxWeight / opponentWeight) : 1.0
            challenge.challengerScore = StatCalculator.statXP(for: challengerWorkouts, stat: stat, classWeights: challengerWeights, classMultiplier: challengerMultiplier)
            challenge.opponentScore = StatCalculator.statXP(for: opponentWorkouts, stat: stat, classWeights: opponentWeights, classMultiplier: opponentMultiplier)
        }

        if let c = challenge.challengerScore, let o = challenge.opponentScore {
            challenge.winnerId = c >= o ? challenge.challengerId : challenge.opponentId
        }
        challenge.status = .completed

        try? await firestoreService.updateBeltChallenge(challenge)
        if let groupId = authService.currentUser?.groupId {
            try? await firestoreService.setBeltHolder(groupId: groupId, stat: challenge.stat, userId: challenge.winnerId)
        }
        await loadData()
    }

    private func applyChallengeBonus(to userId: String, bonus: Double) async {
        guard var user = authService.currentUser, user.id == userId else { return }
        let newTotal = max(0, user.stats.totalXP + bonus)
        let levelInfo = StatCalculator.levelInfoFromXP(newTotal)
        user.stats.totalXP = newTotal
        user.stats.level = levelInfo.level
        user.stats.xpCurrent = levelInfo.xpCurrent
        user.stats.xpToNext = levelInfo.xpToNext
        authService.currentUser = user
        try? await firestoreService.updateUser(user)
    }

    private func mapStat(_ stat: BeltChallenge.BeltStat) -> Constants.PriorityStat {
        switch stat {
        case .strength: return .strength
        case .speed: return .speed
        case .endurance: return .endurance
        case .intelligence: return .intelligence
        case .overall: return .endurance
        }
    }

    private func weight(for stat: Constants.PriorityStat, weights: Constants.ClassWeights) -> Double {
        switch stat {
        case .strength: return weights.strength
        case .speed: return weights.speed
        case .endurance: return weights.endurance
        case .intelligence: return weights.intelligence
        }
    }
}

struct BeltChallengeCard: View {
    let challenge: BeltChallenge
    let members: [AppUser]
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onResolve: () -> Void

    private var challengerName: String { members.first { $0.id == challenge.challengerId }?.displayName ?? "Challenger" }
    private var opponentName: String { members.first { $0.id == challenge.opponentId }?.displayName ?? "Opponent" }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.cardGold)
                Text("\(challenge.stat.displayName) Belt")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(challenge.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(challenge.isActive ? .green : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((challenge.isActive ? Color.green : Color.gray).opacity(0.15))
                    )
            }

            Text("\(challengerName) vs \(opponentName)")
                .font(.system(size: 13))
                .foregroundColor(.gray)

            if let start = challenge.startDate, let end = challenge.endDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                    Text("\(start.formatted(.dateTime.month().day())) - \(end.formatted(.dateTime.month().day()))")
                        .font(.system(size: 11))
                }
                .foregroundColor(.gray.opacity(0.7))
            }

            if challenge.status == .pending {
                HStack(spacing: 10) {
                    Button("ACCEPT") { onAccept() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cardGold)
                        .cornerRadius(6)

                    Button("DECLINE") { onDecline() }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(6)
                }
            }

            if challenge.status == .active, let end = challenge.endDate, Date() > end {
                Button("RESOLVE") { onResolve() }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cardGold)
                    .cornerRadius(6)
            }

            if challenge.status == .completed, let c = challenge.challengerScore, let o = challenge.opponentScore {
                Text("Score: \(Int(c)) - \(Int(o))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardDarkGray)
        )
    }
}

struct CreateBeltChallengeSheet: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss
    @State private var opponentId: String = ""
    @State private var stat: BeltChallenge.BeltStat = .strength
    @State private var durationDays: Int = 7
    @State private var isCreating = false
    let members: [AppUser]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    Picker("Opponent", selection: $opponentId) {
                        ForEach(members.filter { $0.id != authService.currentUser?.id }, id: \.id) { member in
                            Text(member.displayName).tag(member.id ?? "")
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Stat", selection: $stat) {
                        ForEach(BeltChallenge.BeltStat.allCases, id: \.rawValue) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Duration", selection: $durationDays) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                    }
                    .pickerStyle(.segmented)

                    Button {
                        Task { await createChallenge() }
                    } label: {
                        if isCreating {
                            ProgressView().tint(.black)
                        } else {
                            Text("SEND CHALLENGE")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cardGold)
                    .cornerRadius(12)
                    .disabled(opponentId.isEmpty || isCreating)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Belt Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cardGold)
                }
            }
        }
    }

    private func createChallenge() async {
        guard let groupId = authService.currentUser?.groupId,
              let uid = authService.currentUser?.id else { return }
        isCreating = true
        let challenge = BeltChallenge(
            groupId: groupId,
            challengerId: uid,
            opponentId: opponentId,
            stat: stat,
            status: .pending,
            durationDays: durationDays,
            startDate: nil,
            endDate: nil,
            createdAt: Date()
        )
        do {
            // one challenge at a time
            if (try? await firestoreService.getActiveBeltChallenge(for: uid)) != nil {
                isCreating = false
                return
            }
            try await firestoreService.createBeltChallenge(challenge)
            dismiss()
        } catch {
            print("Failed to create belt challenge: \(error)")
        }
        isCreating = false
    }
}
