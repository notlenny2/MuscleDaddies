import SwiftUI

struct GroupView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var group: WorkoutGroup?
    @State private var members: [AppUser] = []
    @State private var isLoading = true
    @State private var showJoinSheet = false
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.cardGold)
                } else if authService.currentUser?.groupId == nil {
                    // No group - show join/create
                    noGroupView
                } else {
                    groupContentView
                }
            }
            .navigationTitle(group?.name ?? "Group")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if group != nil {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink(destination: LeaderboardView(members: members)) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.cardGold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinGroupSheet()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateGroupSheet()
            }
            .task {
                await loadGroup()
            }
        }
    }

    private var noGroupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.cardGold)

            Text("Join a Group")
                .font(.pixel(14))
                .foregroundColor(.white)

            Text("Get an invite code from your friends\nor create a new group")
                .font(.secondary(15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                showJoinSheet = true
            } label: {
                Text("JOIN WITH CODE")
                    .font(.pixel(10))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cardGold)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 40)

            Button {
                showCreateSheet = true
            } label: {
                Text("CREATE NEW GROUP")
                    .font(.pixel(10))
                    .foregroundColor(.cardGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cardGold.opacity(0.15))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 40)
        }
    }

    private var groupContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Invite code banner
                if let code = group?.inviteCode {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INVITE CODE")
                                .font(.pixel(7))
                                .foregroundColor(.gray)
                            Text(code)
                                .font(.pixel(14))
                                .foregroundColor(.cardGold)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.cardGold)
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
                }

                // Member cards
                ForEach(members.sorted(by: { $0.stats.level > $1.stats.level })) { member in
                    CharacterCardView(
                        user: member,
                        compact: true,
                        onPoke: member.id != authService.currentUser?.id ? {
                            pokeMember(member)
                        } : nil
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await loadGroup()
        }
    }

    private func loadGroup() async {
        guard let groupId = authService.currentUser?.groupId else {
            isLoading = false
            return
        }
        do {
            group = try await firestoreService.getGroup(groupId: groupId)
            members = try await firestoreService.getGroupMembers(groupId: groupId)
        } catch {
            print("Failed to load group: \(error)")
        }
        isLoading = false
    }

    private func pokeMember(_ member: AppUser) {
        // In MVP, just post to feed. Phase 2 adds push notifications.
        guard let user = authService.currentUser, let uid = user.id, let groupId = user.groupId else { return }
        let feedItem = FeedItem(
            groupId: groupId,
            userId: uid,
            userName: user.displayName,
            type: .challenge,
            content: "\(user.displayName) poked \(member.displayName)! Get to the gym! 👉"
        )
        Task {
            try? await firestoreService.postFeedItem(feedItem)
        }
    }
}

// MARK: - Join Group Sheet
struct JoinGroupSheet: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var error: String?
    @State private var isJoining = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Enter Invite Code")
                        .font(.pixel(12))
                        .foregroundColor(.white)

                    TextField("CODE", text: $inviteCode)
                        .font(.secondary(24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 60)

                    if let error {
                        Text(error)
                            .font(.secondary(12))
                            .foregroundColor(.red)
                    }

                    Button {
                        Task { await joinGroup() }
                    } label: {
                        if isJoining {
                            ProgressView().tint(.black)
                        } else {
                            Text("JOIN")
                                .font(.pixel(10))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.cardGold)
                    .cornerRadius(4)
                    .disabled(inviteCode.count < 4 || isJoining)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cardGold)
                }
            }
        }
    }

    private func joinGroup() async {
        guard let uid = authService.currentUser?.id else { return }
        isJoining = true
        do {
            if let group = try await firestoreService.joinGroup(inviteCode: inviteCode.uppercased(), userId: uid) {
                authService.currentUser?.groupId = group.id
                dismiss()
            } else {
                error = "Invalid invite code"
            }
        } catch {
            self.error = error.localizedDescription
        }
        isJoining = false
    }
}

// MARK: - Create Group Sheet
struct CreateGroupSheet: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Create a Group")
                        .font(.pixel(12))
                        .foregroundColor(.white)

                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)

                    Button {
                        Task { await createGroup() }
                    } label: {
                        if isCreating {
                            ProgressView().tint(.black)
                        } else {
                            Text("CREATE")
                                .font(.pixel(10))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(width: 200, height: 50)
                    .background(Color.cardGold)
                    .cornerRadius(4)
                    .disabled(groupName.isEmpty || isCreating)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cardGold)
                }
            }
        }
    }

    private func createGroup() async {
        guard let uid = authService.currentUser?.id else { return }
        isCreating = true
        do {
            let group = try await firestoreService.createGroup(name: groupName, createdBy: uid)
            authService.currentUser?.groupId = group.id
            dismiss()
        } catch {
            print("Failed to create group: \(error)")
        }
        isCreating = false
    }
}
