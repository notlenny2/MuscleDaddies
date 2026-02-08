import Foundation
import FirebaseFirestore

struct FeedItem: Codable, Identifiable {
    @DocumentID var id: String?
    var groupId: String
    var userId: String
    var userName: String
    var type: FeedItemType
    var content: String
    var createdAt: Date
    var reactions: [String: [String]] // emoji key: [userId, ...]
    var comments: [FeedComment]

    enum FeedItemType: String, Codable {
        case workout, achievement, levelup, challenge
    }

    init(
        groupId: String,
        userId: String,
        userName: String,
        type: FeedItemType,
        content: String,
        createdAt: Date = Date(),
        reactions: [String: [String]] = [:],
        comments: [FeedComment] = []
    ) {
        self.groupId = groupId
        self.userId = userId
        self.userName = userName
        self.type = type
        self.content = content
        self.createdAt = createdAt
        self.reactions = reactions
        self.comments = comments
    }
}

struct FeedComment: Codable, Identifiable {
    var id: String = UUID().uuidString
    var userId: String
    var userName: String
    var text: String
    var createdAt: Date

    init(userId: String, userName: String, text: String, createdAt: Date = Date()) {
        self.userId = userId
        self.userName = userName
        self.text = text
        self.createdAt = createdAt
    }
}

struct WorkoutGroup: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var inviteCode: String
    var createdBy: String
    var memberIds: [String]

    init(id: String? = nil, name: String, inviteCode: String, createdBy: String, memberIds: [String] = []) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.createdBy = createdBy
        self.memberIds = memberIds
    }
}
