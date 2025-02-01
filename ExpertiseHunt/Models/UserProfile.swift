import Foundation

struct UserProfile: Identifiable {
    let id: String
    var email: String
    var username: String
    var userID: String
    var profileImageUrl: String?
    var friendCount: Int
    var score: Int
    var isDefaultAvatar: Bool
    
    init?(id: String, data: [String: Any]) {
        self.id = id
        guard let email = data["email"] as? String,
              let userID = data["userID"] as? String else {
            return nil
        }
        
        self.email = email
        self.userID = userID
        self.username = data["username"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String
        self.friendCount = data["friendCount"] as? Int ?? 0
        self.score = data["score"] as? Int ?? 0
        self.isDefaultAvatar = data["isDefaultAvatar"] as? Bool ?? false
    }
} 