import SwiftUI

struct ModernCardContent: View {
    let card: CharacterCard
    let user: AppUser
    var compact: Bool = false
    var onPoke: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName.uppercased())
                        .font(.system(size: compact ? 16 : 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text(card.title)
                        .font(.system(size: compact ? 10 : 12, weight: .medium))
                        .foregroundColor(.cardGold)

                    Text(user.selectedClass.displayName)
                        .font(.system(size: compact ? 9 : 11, weight: .semibold))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("LV")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(card.levelDisplay)")
                        .font(.system(size: compact ? 24 : 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.cardGold, .orange], startPoint: .top, endPoint: .bottom)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, compact ? 12 : 16)

            if !compact {
                // Radar chart
                StatRadarView(
                    strength: user.stats.strength,
                    speed: user.stats.speed,
                    endurance: user.stats.endurance,
                    intelligence: user.stats.intelligence,
                    size: 160
                )
                .padding(.bottom, 12)
            }

            // Stat bars
            VStack(spacing: compact ? 6 : 8) {
                StatBar(label: "STR", value: card.strengthDisplay, color: .statRed)
                StatBar(label: "SPD", value: card.speedDisplay, color: .statBlue)
                StatBar(label: "END", value: card.enduranceDisplay, color: .statGreen)
                StatBar(label: "INT", value: card.intelligenceDisplay, color: .statPurple)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 6) {
                ProgressBar(
                    label: "XP",
                    progress: card.xpProgress,
                    valueText: "\(card.xpCurrentDisplay)/\(card.xpToNextDisplay)",
                    color: .cardGold
                )
                ProgressBar(
                    label: "REC",
                    progress: Double(card.intelligenceDisplay) / 99.0,
                    valueText: "\(card.intelligenceDisplay)",
                    color: .statPurple
                )
                ProgressBar(
                    label: "HP",
                    progress: card.hpProgress,
                    valueText: "\(card.hpCurrentDisplay)/\(card.hpMaxDisplay)",
                    color: .statGreen
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, compact ? 8 : 10)

            // Footer
            HStack {
                if user.currentStreak > 0 {
                    Label("\(user.currentStreak) day streak", systemImage: "flame.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }

                Spacer()

                if let onPoke {
                    Button(action: onPoke) {
                        Label("Poke", systemImage: "hand.point.right.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cardGold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cardGold.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, compact ? 10 : 14)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.cardDark, Color.cardDarkGray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(colors: [.cardGold.opacity(0.6), .cardGold.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .cardGold.opacity(0.2), radius: 12, y: 4)
    }
}
