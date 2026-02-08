import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    @State private var feedItems: [FeedItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cardDark.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.cardGold)
                } else if feedItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No activity yet")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("Log a workout to get started!")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(feedItems) { item in
                                FeedItemView(item: item)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadFeed()
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadFeed()
            }
        }
    }

    private func loadFeed() async {
        guard let groupId = authService.currentUser?.groupId else {
            isLoading = false
            return
        }
        do {
            feedItems = try await firestoreService.getFeed(groupId: groupId)
        } catch {
            print("Failed to load feed: \(error)")
        }
        isLoading = false
    }
}
