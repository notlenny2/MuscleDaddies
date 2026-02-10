import SwiftUI

struct CharacterCardView: View {
    let user: AppUser
    var compact: Bool = false
    var onPoke: (() -> Void)? = nil

    private var card: CharacterCard {
        CharacterCard(user: user)
    }

    var body: some View {
        switch user.selectedTheme {
        case .modern:
            ModernCardContent(card: card, user: user, compact: compact, onPoke: onPoke)
        case .pixel:
            PixelArtCardContent(card: card, user: user, compact: compact, onPoke: onPoke)
        case .trading:
            TradingCardContent(card: card, user: user, compact: compact, onPoke: onPoke)
        }
    }
}

// MARK: - Shared SNES-style segmented stat bar
struct StatBar: View {
    let label: String
    let value: Int
    let color: Color
    let maxValue: Int = 99
    private let segments = 10

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.pixel(7))
                .foregroundColor(color)
                .frame(width: 32, alignment: .leading)

            HStack(spacing: 2) {
                let filled = Int(Double(value) / Double(maxValue) * Double(segments))
                ForEach(0..<segments, id: \.self) { i in
                    Rectangle()
                        .fill(i < filled ? color : Color.white.opacity(0.1))
                        .frame(height: 8)
                }
            }

            Text("\(value)")
                .font(.pixel(7))
                .foregroundColor(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

struct ProgressBar: View {
    let label: String
    let progress: Double
    let valueText: String
    let color: Color
    private let segments = 10

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.pixel(7))
                .foregroundColor(color)
                .frame(width: 32, alignment: .leading)

            HStack(spacing: 2) {
                let filled = Int(min(max(progress, 0), 1) * Double(segments))
                ForEach(0..<segments, id: \.self) { i in
                    Rectangle()
                        .fill(i < filled ? color : Color.white.opacity(0.08))
                        .frame(height: 8)
                }
            }

            Text(valueText)
                .font(.pixel(6))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

#if DEBUG
struct CharacterCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            previewCard(theme: .modern, name: "Demo Daddy", className: .warrior)
                .previewDisplayName("Modern")

            previewCard(theme: .pixel, name: "Iron Mike", className: .powerForward)
                .previewDisplayName("Pixel")

            previewCard(theme: .trading, name: "Cardio Queen", className: .striker)
                .previewDisplayName("Trading")
        }
        .preferredColorScheme(.dark)
    }

    private static func previewCard(theme: Constants.CardTheme, name: String, className: Constants.MuscleClass) -> some View {
        let stats = UserStats(
            strength: 62,
            speed: 48,
            endurance: 71,
            intelligence: 39,
            level: 12,
            xpCurrent: 420,
            xpToNext: 1200,
            totalXP: 15420,
            hpCurrent: 76,
            hpMax: 100,
            xpMultiplier: 1.12
        )
        let user = AppUser(
            id: "preview",
            displayName: name,
            stats: stats,
            currentStreak: 6,
            longestStreak: 14,
            selectedTheme: theme,
            classTheme: className.theme,
            selectedClass: className
        )
        return ZStack {
            Color.cardDark.ignoresSafeArea()
            CharacterCardView(user: user)
                .padding()
        }
    }
}
#endif
