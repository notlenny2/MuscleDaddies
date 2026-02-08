import SwiftUI

struct LeaderboardView: View {
    let members: [AppUser]
    @State private var selectedStat: StatFilter = .overall

    enum StatFilter: String, CaseIterable {
        case overall = "Overall"
        case strength = "STR"
        case speed = "SPD"
        case endurance = "END"
        case intelligence = "INT"
    }

    private var sortedMembers: [AppUser] {
        members.sorted { lhs, rhs in
            statValue(for: lhs) > statValue(for: rhs)
        }
    }

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            VStack(spacing: 0) {
                // Stat filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StatFilter.allCases, id: \.rawValue) { filter in
                            Button {
                                selectedStat = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(selectedStat == filter ? .black : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(selectedStat == filter ? Color.cardGold : Color.cardDarkGray)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)

                // Rankings
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(sortedMembers.enumerated()), id: \.element.id) { index, member in
                            HStack(spacing: 14) {
                                // Rank
                                ZStack {
                                    if index < 3 {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(medalColor(index))
                                            .frame(width: 32, height: 32)
                                    } else {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.cardDarkGray)
                                            .frame(width: 32, height: 32)
                                    }
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(index < 3 ? .black : .white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.displayName)
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)

                                    Text("Level \(member.stats.level)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                }

                                Spacer()

                                Text("\(Int(statValue(for: member)))")
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .foregroundColor(.cardGold)

                                if member.currentStreak > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                        Text("\(member.currentStreak)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                    .foregroundColor(.orange)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
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
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Leaderboard")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func statValue(for user: AppUser) -> Double {
        switch selectedStat {
        case .overall: return user.stats.overall
        case .strength: return user.stats.strength
        case .speed: return user.stats.speed
        case .endurance: return user.stats.endurance
        case .intelligence: return user.stats.intelligence
        }
    }

    private func medalColor(_ index: Int) -> Color {
        switch index {
        case 0: return .cardGold
        case 1: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .gray
        }
    }
}
