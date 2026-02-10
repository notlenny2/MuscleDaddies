import SwiftUI

struct TradingCardContent: View {
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
            .opacity(0.12)
            .blur(radius: 0.5)

            VStack(spacing: 0) {
                // Gold frame header
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.cardGold, Color(red: 0.65, green: 0.5, blue: 0.18)], startPoint: .leading, endPoint: .trailing)
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

                // XP / HP ribbon
                if !compact {
                    VStack(spacing: 4) {
                        headerBar(label: "XP", value: "\(card.xpCurrentDisplay)/\(card.xpToNextDisplay)", progress: card.xpProgress, color: .cardGold)
                        headerBar(label: "HP", value: "\(card.hpCurrentDisplay)/\(card.hpMaxDisplay)", progress: card.hpProgress, color: .statRed)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.12, green: 0.1, blue: 0.08))
                }

                // Player photo/art slot (sports trading card frame)
                if !compact {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.black.opacity(0.35), Color.black.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 190)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cardGold.opacity(0.6), lineWidth: 1)
                            )

                        // Diagonal stripe band
                        Rectangle()
                            .fill(Color.cardGold.opacity(0.25))
                            .frame(width: 220, height: 26)
                            .rotationEffect(.degrees(-12))
                            .offset(x: -40, y: 16)

                        // Position badge
                        Text(user.selectedClass.displayName.uppercased())
                            .font(.system(size: 10, weight: .black, design: .serif))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardGold)
                            .cornerRadius(6)
                            .padding(8)

                        // Art
                        if let asset = user.selectedClass.classArtAsset {
                            Image(asset)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.horizontal, 18)
                                .padding(.top, 24)
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        showStatsOverlay.toggle()
                                    }
                                }
                        } else {
                            Text("ART")
                                .font(.system(size: 14, weight: .black, design: .serif))
                                .foregroundColor(.cardGold.opacity(0.8))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
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

                Spacer(minLength: compact ? 4 : 8)

                // Footer
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.cardGold, Color(red: 0.65, green: 0.5, blue: 0.18)], startPoint: .leading, endPoint: .trailing)
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
            .blur(radius: showStatsOverlay ? 6 : 0)

            if showStatsOverlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.55))
                    StatRadarView(
                        strength: user.stats.strength,
                        speed: user.stats.speed,
                        endurance: user.stats.endurance,
                        intelligence: user.stats.intelligence,
                        size: 230
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

    private func headerBar(label: String, value: String, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .serif))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 9, weight: .medium, design: .serif))
                    .foregroundColor(.gray)
            }
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08)).frame(height: 6)
                Capsule().fill(color).frame(width: max(6, CGFloat(progress) * 180), height: 6)
            }
        }
    }
}
