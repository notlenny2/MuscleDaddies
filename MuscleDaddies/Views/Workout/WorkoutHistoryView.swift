import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var workouts: [Workout] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.cardDark.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.cardGold)
            } else if workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No workouts yet")
                        .font(.pixel(10))
                        .foregroundColor(.gray)
                }
            } else {
                List(workouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workout.type.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.cardGold)
                            .frame(width: 36, height: 36)
                            .background(Color.cardGold.opacity(0.15))
                            .cornerRadius(4)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(workout.type.displayName)
                                .font(.pixel(9))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                Text("\(workout.duration) min")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)

                                Text("•")
                                    .foregroundColor(.gray)

                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(i <= workout.intensity ? Color.cardGold : Color.gray.opacity(0.3))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }

                            if let notes = workout.notes {
                                Text(notes)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(workout.createdAt.timeAgoDisplay)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)

                            if workout.source == .healthkit {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listRowBackground(Color.cardDarkGray)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadWorkouts()
        }
    }

    private func loadWorkouts() async {
        guard let uid = authService.currentUser?.id else {
            isLoading = false
            return
        }
        do {
            workouts = try await firestoreService.getWorkouts(userId: uid)
        } catch {
            print("Failed to load workouts: \(error)")
        }
        isLoading = false
    }
}
