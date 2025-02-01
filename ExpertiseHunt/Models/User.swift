import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    let username: String
    let email: String
    var friend_count: Int
    var profileImageUrl: String?
    var bio: String?
    var createdAt: Date?
} 
