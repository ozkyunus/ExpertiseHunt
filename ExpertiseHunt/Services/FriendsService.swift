import FirebaseFirestore
import Foundation

class FriendsService {
    static let shared = FriendsService()
    private let db = Firestore.firestore()
    
    // MARK: - Friend List Management
    func getFriends(for userId: String, completion: @escaping (Result<[Friend], Error>) -> Void) {
        DatabaseService.shared.getFriendsList(for: userId, completion: completion)
    }
    
    // MARK: - Friend Request Management
    func sendFriendRequest(fromUserId: String, toUserID: String, completion: @escaping (Error?) -> Void) {
        db.collection("userIDs").document(toUserID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = snapshot?.data(),
                  let toUID = data["uid"] as? String else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"]))
                return
            }
            
            let requestData: [String: Any] = [
                "fromUID": fromUserId,
                "toUID": toUID,
                "status": "pending",
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            self.db.collection("friendRequests").addDocument(data: requestData, completion: completion)
        }
    }
    
    // Gelen istekleri getir
    func getPendingRequests(for userId: String, completion: @escaping (Result<[Models.FriendRequest], Error>) -> Void) {
        db.collection("friendRequests")
            .whereField("toUID", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let group = DispatchGroup()
                var requests: [Models.FriendRequest] = []
                
                for document in documents {
                    if let fromUID = document.data()["fromUID"] as? String {
                        group.enter()
                        self.db.collection("users").document(fromUID).getDocument { snapshot, error in
                            defer { group.leave() }
                            
                            if let error = error {
                                print("Error fetching user details: \(error)")
                                return
                            }
                            
                            if let data = snapshot?.data() {
                                let request = Models.FriendRequest(
                                    id: document.documentID,
                                    fromUID: fromUID,
                                    fromUsername: data["username"] as? String ?? "",
                                    fromEmail: data["email"] as? String ?? "",
                                    fromUserID: data["userID"] as? String ?? ""
                                )
                                requests.append(request)
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(requests))
                }
            }
    }
    
    // İsteği kabul et
    func acceptFriendRequest(requestId: String, fromUID: String, toUID: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        let requestRef = db.collection("friendRequests").document(requestId)
        batch.updateData([
            "status": "accepted",
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: requestRef)
        
        let friendshipRef = db.collection("friendships").document()
        batch.setData([
            "user1": fromUID,
            "user2": toUID,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: friendshipRef)
        
        let increment = FieldValue.increment(Int64(1))
        batch.updateData(["friendCount": increment], forDocument: db.collection("users").document(fromUID))
        batch.updateData(["friendCount": increment], forDocument: db.collection("users").document(toUID))
        
        batch.commit(completion: completion)
    }
    
    // İsteği reddet
    func rejectFriendRequest(requestId: String, completion: @escaping (Error?) -> Void) {
        db.collection("friendRequests").document(requestId).updateData([
            "status": "rejected",
            "updatedAt": FieldValue.serverTimestamp()
        ], completion: completion)
    }
    
    // Arkadaşlıktan çıkar
    func removeFriend(userId: String, friendId: String, completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        db.collection("friendships")
            .whereField("user1", isEqualTo: userId)
            .whereField("user2", isEqualTo: friendId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(error)
                    return
                }
                
                for doc in snapshot?.documents ?? [] {
                    batch.deleteDocument(doc.reference)
                }
                
                let decrement = FieldValue.increment(Int64(-1))
                batch.updateData(["friendCount": decrement], forDocument: self.db.collection("users").document(userId))
                batch.updateData(["friendCount": decrement], forDocument: self.db.collection("users").document(friendId))
                
                batch.commit(completion: completion)
            }
    }
}
