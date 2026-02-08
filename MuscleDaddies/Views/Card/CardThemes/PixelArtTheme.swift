import SwiftUI

struct PixelArtCardContent: View {
    let card: CharacterCard
    let user: AppUser
    var compact: Bool = false
    var onPoke: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Pixel-style header with border
            HStack {
                Text("★ \(user.displayName.uppercased()) ★")
                    .font(.system(size: compact ? 14 : 18, weight: .black, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                Text("LV\(card.levelDisplay)")
                    .font(.system(size: compact ? 16 : 22, weight: .black, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Text("< \(card.title) >")
                .font(.system(size: compact ? 9 : 11, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.7))
                .padding(.top, 2)

            Text("[\(user.selectedClass.displayName.uppercased())]")
                .font(.system(size: compact ? 9 : 10, weight: .bold, design: .monospaced))
                .foregroundColor(.green.opacity(0.7))

            Divider()
                .background(Color.green.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            if !compact {
                if let asset = user.selectedClass.classArtAsset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                // Pixel-style stat display
                VStack(spacing: 4) {
                    pixelStatRow(icon: "⚔️", label: "STR", value: card.strengthDisplay)
                    pixelStatRow(icon: "⚡", label: "SPD", value: card.speedDisplay)
                    pixelStatRow(icon: "🛡️", label: "END", value: card.enduranceDisplay)
                    pixelStatRow(icon: "📖", label: "INT", value: card.intelligenceDisplay)
                    pixelProgressRow(label: "XP", valueText: "\(card.xpCurrentDisplay)/\(card.xpToNextDisplay)", progress: card.xpProgress)
                    pixelProgressRow(label: "REC", valueText: "\(card.intelligenceDisplay)", progress: Double(card.intelligenceDisplay) / 99.0)
                    pixelProgressRow(label: "HP", valueText: "\(card.hpCurrentDisplay)/\(card.hpMaxDisplay)", progress: card.hpProgress)
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

            Divider()
                .background(Color.green.opacity(0.5))
                .padding(.horizontal, 16)

            // Footer
            HStack {
                if user.currentStreak > 0 {
                    Text("🔥 x\(user.currentStreak)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }

                Spacer()

                if let onPoke {
                    Button(action: onPoke) {
                        Text("👉 POKE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
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
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.green.opacity(0.6), lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                .padding(3)
        )
    }

    private func pixelStatRow(icon: String, label: String, value: Int) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .frame(width: 30, alignment: .leading)

            // Pixel bar using block characters
            let blocks = Int(Double(value) / 99.0 * 20)
            Text(String(repeating: "█", count: blocks) + String(repeating: "░", count: 20 - blocks))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.green)

            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func pixelStatCompact(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.green.opacity(0.7))
            Text("\(value)")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.green)
        }
    }

    private func pixelProgressRow(label: String, valueText: String, progress: Double) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .frame(width: 30, alignment: .leading)

            let blocks = Int(min(max(progress, 0), 1) * 20)
            Text(String(repeating: "█", count: blocks) + String(repeating: "░", count: 20 - blocks))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.green)

            Text(valueText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 52, alignment: .trailing)
        }
    }
}
