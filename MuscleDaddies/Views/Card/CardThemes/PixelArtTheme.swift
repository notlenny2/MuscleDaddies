import SwiftUI

struct PixelArtCardContent: View {
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
                size: 200
            )
            .opacity(0.12)
            .blur(radius: 0.5)

            VStack(spacing: 0) {
            // Pixel-style header with hard edges
            VStack(spacing: 4) {
                HStack {
                    Text("★ \(user.displayName.uppercased()) ★")
                        .font(.secondary(compact ? 14 : 18, weight: .black))
                        .foregroundColor(.green)

                    Spacer()

                    Text("LV\(card.levelDisplay)")
                        .font(.secondary(compact ? 16 : 22, weight: .black))
                        .foregroundColor(.yellow)
                }

                if !compact {
                    xpHpHeader
                }

                Text("[\(user.selectedClass.displayName.uppercased())]")
                    .font(.secondary(compact ? 9 : 10, weight: .bold))
                    .foregroundColor(.green.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            pixelDivider()

            if !compact {
                if let asset = user.selectedClass.classArtAsset {
                    Image(asset)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 170)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.25))
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showStatsOverlay.toggle()
                            }
                        }
                }
                // Pixel-style stat display
                VStack(spacing: 4) {
                    pixelStatRow(icon: "⚔️", label: "STR", value: card.strengthDisplay)
                    pixelStatRow(icon: "⚡", label: "SPD", value: card.speedDisplay)
                    pixelStatRow(icon: "🛡️", label: "END", value: card.enduranceDisplay)
                    pixelStatRow(icon: "📖", label: "INT", value: card.intelligenceDisplay)
                    
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            } else {
                HStack(spacing: 16) {
                    pixelStatCompact("STR", card.strengthDisplay)
                    pixelStatCompact("SPD", card.speedDisplay)
                    pixelStatCompact("END", card.enduranceDisplay)
                    pixelStatCompact("INT", card.intelligenceDisplay)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            pixelDivider()

            // Footer
            HStack {
                if user.currentStreak > 0 {
                    Text("🔥 x\(user.currentStreak)")
                        .font(.secondary(12, weight: .bold))
                        .foregroundColor(.orange)
                }

                Spacer()

                if let onPoke {
                    Button(action: onPoke) {
                        Text("👉 POKE")
                            .font(.secondary(11, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            }
            .blur(radius: showStatsOverlay ? 6 : 0)

            if showStatsOverlay {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.55))
                    StatRadarView(
                        strength: user.stats.strength,
                        speed: user.stats.speed,
                        endurance: user.stats.endurance,
                        intelligence: user.stats.intelligence,
                        size: 220
                    )
                }
                .padding(10)
                .onTapGesture {
                    withAnimation(.spring()) {
                        showStatsOverlay = false
                    }
                }
            }
        }
        .background(
            Rectangle()
                .fill(Color(red: 0.05, green: 0.05, blue: 0.1))
        )
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.8), lineWidth: 3)
        )
        .overlay(
            Rectangle()
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
                .padding(3)
        )
    }

    private func pixelStatRow(icon: String, label: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            Text(label)
                .font(.secondary(12, weight: .bold))
                .foregroundColor(.green)
                .frame(width: 30, alignment: .leading)

            // Pixel bar using block rectangles
            let blocks = Int(min(max(Double(value) / 99.0, 0), 1) * 20)
            pixelBlocks(filled: blocks, total: 20, color: .green, height: 8)

            Text("\(value)")
                .font(.secondary(12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func pixelStatCompact(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.secondary(9, weight: .bold))
                .foregroundColor(.green.opacity(0.7))
            Text("\(value)")
                .font(.secondary(14, weight: .black))
                .foregroundColor(.green)
        }
    }

    private func pixelProgressRow(label: String, valueText: String, progress: Double, barColor: Color = .green) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.secondary(12, weight: .bold))
                .foregroundColor(.green)
                .frame(width: 30, alignment: .leading)

            let blocks = Int(min(max(progress, 0), 1) * 20)
            pixelBlocks(filled: blocks, total: 20, color: barColor, height: 8)

            Text(valueText)
                .font(.secondary(10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func pixelDivider() -> some View {
        Rectangle()
            .fill(Color.green.opacity(0.5))
            .frame(height: 2)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    private var xpHpHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            pixelHeaderBar(label: "XP", valueText: "\(card.xpCurrentDisplay)/\(card.xpToNextDisplay)", progress: card.xpProgress, color: .yellow)
            pixelHeaderBar(label: "HP", valueText: "\(card.hpCurrentDisplay)/\(card.hpMaxDisplay)", progress: card.hpProgress, color: .statRed)
        }
    }

    private func pixelHeaderBar(label: String, valueText: String, progress: Double, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.secondary(9, weight: .bold))
                .foregroundColor(color)
                .frame(width: 26, alignment: .leading)

            let blocks = Int(min(max(progress, 0), 1) * 16)
            pixelBlocks(filled: blocks, total: 16, color: color, height: 6)

            Text(valueText)
                .font(.secondary(9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func pixelBlocks(filled: Int, total: Int, color: Color, height: CGFloat) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { index in
                Rectangle()
                    .fill(index < filled ? color : color.opacity(0.2))
                    .frame(width: 6, height: height)
            }
        }
    }
}
