import SwiftUI

struct FeedItemView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var firestoreService: FirestoreService
    let item: FeedItem
    @State private var showComments = false
    @State private var commentText = ""

    private var currentUserId: String {
        authService.currentUser?.id ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(iconColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.userName)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(item.createdAt.timeAgoDisplay)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                feedTypeBadge
            }

            // Content
            Text(item.content)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))

            // Reactions
            HStack(spacing: 12) {
                ForEach(Constants.Reaction.allCases, id: \.rawValue) { reaction in
                    let users = item.reactions[reaction.rawValue] ?? []
                    let isActive = users.contains(currentUserId)

                    Button {
                        Task {
                            guard let itemId = item.id else { return }
                            if isActive {
                                try? await firestoreService.removeReaction(feedItemId: itemId, reaction: reaction.rawValue, userId: currentUserId)
                            } else {
                                try? await firestoreService.addReaction(feedItemId: itemId, reaction: reaction.rawValue, userId: currentUserId)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(reaction.rawValue)
                                .font(.system(size: 16))
                            if !users.isEmpty {
                                Text("\(users.count)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(isActive ? .cardGold : .gray)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isActive ? Color.cardGold.opacity(0.15) : Color.white.opacity(0.05))
                        )
                    }
                }

                Spacer()

                Button {
                    showComments.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 12))
                        if !item.comments.isEmpty {
                            Text("\(item.comments.count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                    }
                    .foregroundColor(.gray)
                }
            }

            // Comments section
            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.comments) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(comment.userName)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cardGold)
                            Text(comment.text)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Comment...", text: $commentText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))

                        Button("Send") {
                            guard let itemId = item.id, !commentText.isEmpty else { return }
                            let comment = FeedComment(
                                userId: currentUserId,
                                userName: authService.currentUser?.displayName ?? "",
                                text: commentText
                            )
                            Task {
                                try? await firestoreService.addComment(feedItemId: itemId, comment: comment)
                                commentText = ""
                            }
                        }
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.cardGold)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cardDarkGray)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch item.type {
        case .workout: return "figure.run"
        case .achievement: return "star.fill"
        case .levelup: return "arrow.up.circle.fill"
        case .challenge: return "trophy.fill"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .workout: return .statBlue
        case .achievement: return .cardGold
        case .levelup: return .statGreen
        case .challenge: return .statPurple
        }
    }

    private var feedTypeBadge: some View {
        Text(item.type.rawValue.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(iconColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(iconColor.opacity(0.15))
            )
    }
}
