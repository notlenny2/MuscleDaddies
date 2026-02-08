import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var unlockedAchievements: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cardGold)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Constants.AchievementType.allCases, id: \.rawValue) { achievement in
                            let isUnlocked = unlockedAchievements.contains(achievement.rawValue)
                            achievementCard(achievement, isUnlocked: isUnlocked)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Achievements")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadAchievements()
        }
    }

    private func achievementCard(_ type: Constants.AchievementType, isUnlocked: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isUnlocked ? Color.cardGold.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 56, height: 56)

                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .cardGold : .gray.opacity(0.4))
            }

            Text(type.displayName)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(isUnlocked ? .white : .gray)
                .multilineTextAlignment(.center)

            Text(type.description)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cardDarkGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isUnlocked ? Color.cardGold.opacity(0.4) : Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(isUnlocked ? 1 : 0.6)
    }

    private func loadAchievements() async {
        guard let uid = authService.currentUser?.id else {
            isLoading = false
            return
        }
        do {
            let achievements = try await firestoreService.getAchievements(userId: uid)
            unlockedAchievements = Set(achievements.map { $0.achievementType.rawValue })
        } catch {
            print("Failed to load achievements: \(error)")
        }
        isLoading = false
    }
}
