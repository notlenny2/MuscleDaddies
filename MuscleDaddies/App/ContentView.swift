import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var notificationService: NotificationService
    @State private var showLogWorkout = false
    @State private var hasSynced = false

    var body: some View {
        Group {
            if authService.isLoading {
                ZStack {
                    Color.cardDark.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.statRed, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        ProgressView()
                            .tint(.cardGold)
                    }
                }
            } else if !authService.isAuthenticated || authService.currentUser == nil {
                LoginView()
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        ZStack(alignment: .bottom) {
            TabView {
                // My Card
                NavigationStack {
                    ZStack {
                        Color.cardDark.ignoresSafeArea()

                        ScrollView {
                            VStack(spacing: 20) {
                                if let user = authService.currentUser {
                                    CharacterCardView(user: user)
                                        .padding(.horizontal)

                                    // Quick stats
                                    HStack(spacing: 16) {
                                        quickStatCard(
                                            icon: "flame.fill",
                                            label: "Streak",
                                            value: "\(user.currentStreak)",
                                            color: .orange
                                        )
                                        quickStatCard(
                                            icon: "trophy.fill",
                                            label: "Best",
                                            value: "\(user.longestStreak)",
                                            color: .cardGold
                                        )
                                        quickStatCard(
                                            icon: "star.fill",
                                            label: "Level",
                                            value: "\(user.stats.level)",
                                            color: .statPurple
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Your Daddy")
                                .font(.primary(24))
                                .foregroundColor(.white)
                        }
                    }
                    .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label("Card", systemImage: "person.crop.rectangle")
                }

                // Progress
                XPRecoveryView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.xaxis")
                    }

                // Feed
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "bubble.left.and.bubble.right")
                    }

                // Challenges
                NavigationStack {
                    ChallengeView()
                }
                .tabItem {
                    Label("Challenges", systemImage: "trophy.fill")
                }

                // Log Workout (placeholder for center button)
                Color.clear
                    .tabItem {
                        Label("Log", systemImage: "plus.circle.fill")
                    }

                // Group
                GroupView()
                    .tabItem {
                        Label("Group", systemImage: "person.3")
                    }

                // Settings
                SettingsView()
                    .tabItem {
                        Label("More", systemImage: "gearshape")
                    }
            }
            .tint(.cardGold)
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(Color.cardDark)
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }

            // Floating log workout button (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showLogWorkout = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cardGold)
                                .frame(width: 48, height: 48)
                                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)

                            Image(systemName: "plus")
                                .font(.secondary(20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 10)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showLogWorkout) {
            LogWorkoutView()
        }
        .task {
            guard !hasSynced, let user = authService.currentUser, let uid = user.id else { return }
            hasSynced = true

            // Request notification permission + save FCM token
            _ = await notificationService.requestAuthorization()
            if let token = notificationService.getFCMToken(), token != user.fcmToken {
                var updated = user
                updated.fcmToken = token
                try? await firestoreService.updateUser(updated)
                authService.currentUser = updated
            }

            // HealthKit sync
            guard healthKitService.isAuthorized else { return }
            let synced = await healthKitService.syncWorkouts(
                userId: uid, groupId: user.groupId, firestoreService: firestoreService
            )
            let backfilled = await firestoreService.backfillWorkoutMetrics(userId: uid)
            if synced > 0 || backfilled > 0 {
                if let workouts = try? await firestoreService.getWorkouts(userId: uid) {
                    var updated = authService.currentUser ?? user
                    let recovery = await healthKitService.fetchRecoveryMetrics()
                    try? await firestoreService.saveRecoveryMetrics(userId: uid, metrics: recovery)
                    updated.stats = StatCalculator.calculateStats(workouts: workouts, recovery: recovery, selectedClass: updated.selectedClass)
                    let streak = StatCalculator.calculateStreak(workouts: workouts)
                    updated.currentStreak = streak.current
                    updated.longestStreak = streak.longest
                    updated.lastWorkoutDate = workouts.first?.createdAt
                    try? await firestoreService.updateUser(updated)
                    authService.currentUser = updated
                }
            }
        }
    }

    private func quickStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.secondary(14, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.pixel(7))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cardDarkGray)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
