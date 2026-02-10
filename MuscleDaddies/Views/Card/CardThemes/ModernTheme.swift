import SwiftUI

struct ModernCardContent: View {
    let card: CharacterCard
    let user: AppUser
    var compact: Bool = false
    var onPoke: (() -> Void)? = nil
    @State private var showStatsOverlay = false

    var body: some View {
        ZStack {
            StatRadarView(
                strength: user.stats.strength,
                speed: user.stats.speed,
                endurance: user.stats.endurance,
                intelligence: user.stats.intelligence,
                size: 220
            )
            .opacity(0.08)
            .blur(radius: 0.5)

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName.uppercased())
                            .font(.system(size: compact ? 16 : 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        if !compact {
                            xpHpHeader
                        }

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
                    // Character art
                    if let asset = user.selectedClass.classArtAsset {
                        Image(asset)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 190)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cardGold.opacity(0.35), lineWidth: 1)
                            )
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    showStatsOverlay.toggle()
                                }
                            }
                    }
                }

                // Stat bars
                VStack(spacing: compact ? 6 : 8) {
                    StatBar(label: "STR", value: card.strengthDisplay, color: .statRed)
                    StatBar(label: "SPD", value: card.speedDisplay, color: .statBlue)
                    StatBar(label: "END", value: card.enduranceDisplay, color: .statGreen)
                    StatBar(label: "INT", value: card.intelligenceDisplay, color: .statPurple)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: compact ? 4 : 8)

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
            .blur(radius: showStatsOverlay ? 6 : 0)

            if showStatsOverlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.cardGold.opacity(0.25), lineWidth: 1)
                        )
                    StatRadarView(
                        strength: user.stats.strength,
                        speed: user.stats.speed,
                        endurance: user.stats.endurance,
                        intelligence: user.stats.intelligence,
                        size: 220
                    )
                }
                .padding(12)
                .onTapGesture {
                    withAnimation(.spring()) {
                        showStatsOverlay = false
                    }
                }
            }
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

    private var xpHpHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            headerBar(label: "XP", value: "\(card.xpCurrentDisplay)/\(card.xpToNextDisplay)", progress: card.xpProgress, color: .cardGold)
            headerBar(label: "HP", value: "\(card.hpCurrentDisplay)/\(card.hpMaxDisplay)", progress: card.hpProgress, color: .statRed)
        }
        .padding(.top, 6)
    }

    private func headerBar(label: String, value: String, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08)).frame(height: 6)
                Capsule().fill(color).frame(width: max(6, CGFloat(progress) * 120), height: 6)
            }
        }
    }
}
