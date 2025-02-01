import Foundation


public struct Models {
    public struct FriendRequest: Identifiable {
        public let id: String
        public let fromUID: String
        public let fromUsername: String
        public let fromEmail: String
        public let fromUserID: String
        
        public init(id: String, fromUID: String, fromUsername: String, fromEmail: String, fromUserID: String) {
            self.id = id
            self.fromUID = fromUID
            self.fromUsername = fromUsername
            self.fromEmail = fromEmail
            self.fromUserID = fromUserID
        }
        
        public init?(id: String, fromUserData: [String: Any]) {
            self.id = id
            self.fromUID = fromUserData["fromUID"] as? String ?? ""
            self.fromUsername = fromUserData["username"] as? String ?? ""
            self.fromEmail = fromUserData["email"] as? String ?? ""
            self.fromUserID = fromUserData["userID"] as? String ?? ""
            
            if self.fromUID.isEmpty || self.fromEmail.isEmpty {
                return nil
            }
        }
    }
}
public typealias FriendRequest = Models.FriendRequest 
