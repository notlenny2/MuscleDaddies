import SwiftUI
import UIKit

struct AchievementsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var unlockedAchievements: Set<String> = []
    @State private var isLoading = true
    @State private var selectedAchievement: Constants.AchievementType?
    @State private var showCelebration = false

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cardGold)
            } else {
                ScrollView {
                    header
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(Constants.AchievementType.allCases, id: \.rawValue) { achievement in
                            let isUnlocked = unlockedAchievements.contains(achievement.rawValue)
                            achievementCard(achievement, isUnlocked: isUnlocked)
                                .onTapGesture {
                                    guard isUnlocked else { return }
                                    selectedAchievement = achievement
                                    triggerCelebration()
                                }
                        }
                    }
                    .padding()
                }
            }

            if showCelebration, let selectedAchievement {
                CelebrationOverlay(achievement: selectedAchievement, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.2)) { showCelebration = false }
                })
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

    private var header: some View {
        let unlockedCount = unlockedAchievements.count
        let total = Constants.AchievementType.allCases.count
        let progress = total > 0 ? Double(unlockedCount) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Unlocked \(unlockedCount) / \(total)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                ProgressRing(progress: progress)
                    .frame(width: 40, height: 40)
            }
            Text("Tap an unlocked badge to celebrate.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)

#if DEBUG
            HStack(spacing: 12) {
                Button("Unlock All (Demo)") {
                    unlockedAchievements = Set(Constants.AchievementType.allCases.map { $0.rawValue })
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.cardGold)

                Button("Test Celebration") {
                    selectedAchievement = Constants.AchievementType.allCases.first
                    triggerCelebration()
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            }
#endif
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private func triggerCelebration() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showCelebration = true
        }
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 4)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Color.cardGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

private struct CelebrationOverlay: View {
    let achievement: Constants.AchievementType
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.cardGold.opacity(0.2))
                        .frame(width: 120, height: 120)
                    Image(systemName: achievement.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.cardGold)
                }
                Text(achievement.displayName)
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(achievement.description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text("UNLOCKED")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.cardGold)
                    .cornerRadius(4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardDarkGray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cardGold.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal, 30)

            ConfettiView()
                .ignoresSafeArea()
        }
        .transition(.opacity)
    }
}

private struct ConfettiView: View {
    @State private var animate = false

    private let colors: [Color] = [
        .cardGold, .orange, .statGreen, .statBlue, .statPurple, .white
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<80, id: \.self) { i in
                let size = CGFloat(Int.random(in: 4...10))
                let x = CGFloat(Int.random(in: 0...Int(geo.size.width)))
                let y = CGFloat(Int.random(in: -50...0))
                RoundedRectangle(cornerRadius: 1)
                    .fill(colors[i % colors.count])
                    .frame(width: size, height: size * 1.6)
                    .position(x: x, y: animate ? geo.size.height + 40 : y)
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeIn(duration: Double.random(in: 1.4...2.0))
                        .delay(Double.random(in: 0...0.3)),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}
