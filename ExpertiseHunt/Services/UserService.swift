import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private var currentUserProfile: UserProfile?
    
    var currentUser: UserProfile? {
        return currentUserProfile
    }
    
    func loadCurrentUser(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = snapshot?.data(),
               let profile = UserProfile(id: userId, data: data) {
                self?.currentUserProfile = profile
                completion(.success(profile))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user profile"])))
            }
        }
    }
    
    func updateUsername(_ username: String, completion: @escaping (Error?) -> Void) {
        guard let userId = auth.currentUser?.uid else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        db.collection("users").document(userId).updateData([
            "username": username
        ]) { [weak self] error in
            if error == nil {
                self?.currentUserProfile?.username = username
            }
            completion(error)
        }
    }
} 