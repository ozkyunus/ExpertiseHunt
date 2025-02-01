import FirebaseFirestore
import Foundation

class DatabaseService {
    static let shared = DatabaseService()
    private let db = Firestore.firestore()
    
    // MARK: - User Profile Operations
    func updateUserProfile(userId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).updateData(data, completion: completion)
    }
    
    func getUserProfile(userId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = snapshot?.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            }
        }
    }
    
    // MARK: - Friend Operations
    func sendFriendRequest(from: String, to: String, completion: @escaping (Error?) -> Void) {
        db.collection("userIDs").document(to).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            if let data = snapshot?.data(), let toUID = data["uid"] as? String {
                let requestData: [String: Any] = [
                    "fromUID": from,
                    "toUID": toUID,
                    "status": "pending",
                    "timestamp": FieldValue.serverTimestamp()
                ]
                db.collection("friendRequests").addDocument(data: requestData) { error in
                    if let error = error {
                        print("Friend request error: \(error.localizedDescription)")
                    }
                    completion(error)
                }
            } else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"]))
            }
        }
    }
    
    func updateFriendRequest(requestId: String, status: String, completion: @escaping (Error?) -> Void) {
        db.collection("friendRequests").document(requestId).updateData([
            "status": status
        ], completion: completion)
    }
    
    // MARK: - Friend List Operations
    func getFriendsList(for userId: String, completion: @escaping (Result<[Friend], Error>) -> Void) {
        var friends: [Friend] = []
        let group = DispatchGroup()
        group.enter()
        db.collection("friendships")
            .whereField("user1", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                for document in snapshot?.documents ?? [] {
                    if let friendId = document.data()["user2"] as? String {
                        group.enter()
                        self.getUserProfile(userId: friendId) { result in
                            defer { group.leave() }
                            switch result {
                            case .success(let data):
                                if let friend = Friend(id: friendId, data: data) {
                                    friends.append(friend)
                                }
                            case .failure(let error):
                                print("Error fetching friend data: \(error)")
                            }
                        }
                    }
                }
            }
        group.enter()
        db.collection("friendships")
            .whereField("user2", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                for document in snapshot?.documents ?? [] {
                    if let friendId = document.data()["user1"] as? String {
                        group.enter()
                        self.getUserProfile(userId: friendId) { result in
                            defer { group.leave() }
                            switch result {
                            case .success(let data):
                                if let friend = Friend(id: friendId, data: data) {
                                    friends.append(friend)
                                }
                            case .failure(let error):
                                print("Error fetching friend data: \(error)")
                            }
                        }
                    }
                }
            }
        
        group.notify(queue: .main) {
            completion(.success(friends))
        }
    }
    
    // MARK: - Friend Request Operations
    func getPendingFriendRequests(for userId: String, completion: @escaping (Result<[Models.FriendRequest], Error>) -> Void) {
        db.collection("friendRequests")
            .whereField("toUID", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var requests: [Models.FriendRequest] = []
                let group = DispatchGroup()
                
                for document in snapshot?.documents ?? [] {
                    if let fromUID = document.data()["fromUID"] as? String {
                        group.enter()
                        self?.getUserProfile(userId: fromUID) { result in
                            defer { group.leave() }
                            switch result {
                            case .success(let data):
                                var requestData = data
                                requestData["id"] = document.documentID
                                if let request = Models.FriendRequest(id: document.documentID, fromUserData: requestData) {
                                    requests.append(request)
                                }
                            case .failure(let error):
                                print("Error fetching request data: \(error)")
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(requests))
                }
            }
    }
} 
