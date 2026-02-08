import SwiftUI

struct TradingCardContent: View {
    let card: CharacterCard
    let user: AppUser
    var compact: Bool = false
    var onPoke: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Gold frame header
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.cardGold, Color(red: 0.7, green: 0.55, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: compact ? 36 : 44)

                HStack {
                    Text(user.displayName.uppercased())
                        .font(.system(size: compact ? 14 : 17, weight: .black, design: .serif))
                        .foregroundColor(.black)

                    Spacer()

                    Text("LV \(card.levelDisplay)")
                        .font(.system(size: compact ? 14 : 17, weight: .black, design: .serif))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
            }

            // Title ribbon
            Text("\(card.title) • \(user.selectedClass.displayName)")
                .font(.system(size: compact ? 9 : 11, weight: .semibold, design: .serif))
                .foregroundColor(.cardGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color(red: 0.12, green: 0.1, blue: 0.08))

            // Class art
            if !compact, let asset = user.selectedClass.classArtAsset {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            // Stats area
            VStack(spacing: compact ? 8 : 12) {
                if !compact {
                    // Overall circle
                    ZStack {
                        Circle()
                            .stroke(Color.cardGold.opacity(0.3), lineWidth: 3)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: Double(card.overallDisplay) / 99.0)
                            .stroke(Color.cardGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(card.overallDisplay)")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(.cardGold)
                            Text("OVR")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 8)
                }

                // Stat grid
                HStack(spacing: compact ? 12 : 20) {
                    tradingStatBox("STR", card.strengthDisplay, .statRed)
                    tradingStatBox("SPD", card.speedDisplay, .statBlue)
                    tradingStatBox("END", card.enduranceDisplay, .statGreen)
                    tradingStatBox("INT", card.intelligenceDisplay, .statPurple)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, compact ? 10 : 14)

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
            .padding(.horizontal, 16)
            .padding(.bottom, compact ? 8 : 12)

            // Footer
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.cardGold, Color(red: 0.7, green: 0.55, blue: 0.2)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 32)

                HStack {
                    if user.currentStreak > 0 {
                        Text("🔥 \(user.currentStreak)")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    if let onPoke {
                        Button(action: onPoke) {
                            Text("POKE")
                                .font(.system(size: 11, weight: .black, design: .serif))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(red: 0.08, green: 0.07, blue: 0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardGold, lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cardGold.opacity(0.3), lineWidth: 1)
                .padding(4)
        )
        .shadow(color: .cardGold.opacity(0.3), radius: 10, y: 4)
    }

    private func tradingStatBox(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: compact ? 18 : 24, weight: .black, design: .serif))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9, weight: .bold, design: .serif))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
