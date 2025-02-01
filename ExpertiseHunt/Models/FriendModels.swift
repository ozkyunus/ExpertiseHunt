import Foundation

struct Friend: Identifiable {
    let id: String
    let username: String
    let email: String
    let userID: String
    
    init?(id: String, data: [String: Any]) {
        self.id = id
        self.username = data["username"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.userID = data["userID"] as? String ?? ""
        
        if self.email.isEmpty {
            return nil
        }
    }
} 
