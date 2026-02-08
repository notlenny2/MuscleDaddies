import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var challenges: [Challenge] = []
    @State private var isLoading = true
    @State private var showCreate = false

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cardGold)
            } else if challenges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No challenges yet")
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(challenges) { challenge in
                            ChallengeCard(challenge: challenge)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Challenges")
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
            CreateChallengeSheet()
        }
        .task {
            await loadChallenges()
        }
    }

    private func loadChallenges() async {
        guard let groupId = authService.currentUser?.groupId else {
            isLoading = false
            return
        }
        do {
            challenges = try await firestoreService.getChallenges(groupId: groupId)
        } catch {
            print("Failed to load challenges: \(error)")
        }
        isLoading = false
    }
}

struct ChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: challenge.isActive ? "trophy.fill" : "trophy")
                    .foregroundColor(.cardGold)
                Text(challenge.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(challenge.isActive ? "ACTIVE" : (challenge.isCompleted ? "ENDED" : "UPCOMING"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(challenge.isActive ? .green : .gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill((challenge.isActive ? Color.green : Color.gray).opacity(0.15))
                    )
            }

            Text(challenge.description)
                .font(.system(size: 13))
                .foregroundColor(.gray)

            // Date range
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text("\(challenge.startDate.formatted(.dateTime.month().day())) - \(challenge.endDate.formatted(.dateTime.month().day()))")
                    .font(.system(size: 11))
            }
            .foregroundColor(.gray.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cardDarkGray)
        )
    }
}

struct CreateChallengeSheet: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var endDate = Date().addingTimeInterval(7 * 86400)
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("Challenge Title", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .foregroundColor(.white)
                        .tint(.cardGold)

                    Button {
                        Task { await createChallenge() }
                    } label: {
                        if isCreating {
                            ProgressView().tint(.black)
                        } else {
                            Text("CREATE CHALLENGE")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cardGold)
                    .cornerRadius(12)
                    .disabled(title.isEmpty || isCreating)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Challenge")
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
        guard let groupId = authService.currentUser?.groupId else { return }
        isCreating = true
        let challenge = Challenge(
            groupId: groupId,
            title: title,
            description: description,
            metric: "workouts",
            startDate: Date(),
            endDate: endDate,
            participants: [:]
        )
        do {
            try await firestoreService.createChallenge(challenge)
            dismiss()
        } catch {
            print("Failed to create challenge: \(error)")
        }
        isCreating = false
    }
}
