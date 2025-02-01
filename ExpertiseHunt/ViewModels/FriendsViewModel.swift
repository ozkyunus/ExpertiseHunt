import FirebaseFirestore
import FirebaseAuth

class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [User] = []
    @Published var isLoading = false
    @Published var showDeleteConfirmation = false
    @Published var friendToDelete: User?
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var requestsListener: ListenerRegistration?
    
    var currentUserID: String? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return UserDefaults.standard.string(forKey: "userID_\(uid)")
    }
    
    // MARK: - Arkadaş İsteği Gönderme
    func sendFriendRequest(to userID: String) async throws {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Oturum açık değil"])
        }
        let snapshot = try await db.collection("userIDs")
            .document(userID)
            .getDocument()
        
        guard let targetUid = snapshot.data()?["uid"] as? String else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
        }
        guard targetUid != currentUid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kendinize arkadaşlık isteği gönderemezsiniz"])
        }
        let existingRef = try await db.collection("friends")
            .whereField("users", arrayContains: currentUid)
            .getDocuments()
        
        for doc in existingRef.documents {
            let data = doc.data()
            let users = data["users"] as? [String] ?? []
            let status = data["status"] as? String ?? ""
            
            if users.contains(targetUid) {
                if status == "accepted" {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zaten arkadaşsınız"])
                } else if status == "pending" {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bekleyen bir arkadaşlık isteği var"])
                }
            }
        }
        try await db.collection("friends").addDocument(data: [
            "users": [currentUid, targetUid],
            "status": "pending",
            "requestedBy": currentUid,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Arkadaş İsteklerini Dinleme
    func startListeningToRequests() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        requestsListener = db.collection("friends")
            .whereField("users", arrayContains: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .whereField("requestedBy", isNotEqualTo: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task {
                    var requests: [User] = []
                    for document in snapshot?.documents ?? [] {
                        let data = document.data()
                        if let requestedBy = data["requestedBy"] as? String,
                           let users = data["users"] as? [String],
                           let otherUserId = users.first(where: { $0 != currentUserId }) {
                            if let user = try? await self.fetchUserDetails(userId: otherUserId) {
                                await MainActor.run {
                                    requests.append(user)
                                }
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.friendRequests = requests
                    }
                }
            }
    }
    
    private func processRequestDocument(_ document: QueryDocumentSnapshot, currentUserId: String) async throws -> User? {
        let data = document.data()
        guard let requestedBy = data["requestedBy"] as? String,
              requestedBy != currentUserId,
              let users = data["users"] as? [String],
              let otherUserId = users.first(where: { $0 != currentUserId }) else {
            return nil
        }
        
        return try? await fetchUserDetails(userId: otherUserId)
    }
    
    // MARK: - Arkadaş İsteğini Kabul Etme
    func acceptFriendRequest(from user: User) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let requesterId = user.id else { return }
        
        let snapshot = try await db.collection("friends")
            .whereField("users", arrayContains: currentUserId)
            .whereField("requestedBy", isEqualTo: requesterId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return }
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                transaction.updateData(["status": "accepted"], forDocument: document.reference)
                try self.updateFriendCount(transaction: transaction, userId: currentUserId, increment: 1)
                try self.updateFriendCount(transaction: transaction, userId: requesterId, increment: 1)
                
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }
        await loadFriends()
    }
    
    // MARK: - Arkadaşlıktan Çıkarma
    func removeFriend(_ friend: User) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let friendId = friend.id else { return }
        
        let snapshot = try await db.collection("friends")
            .whereField("users", arrayContains: currentUserId)
            .whereField("users", arrayContains: friendId)
            .whereField("status", isEqualTo: "accepted")
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return }
        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                transaction.deleteDocument(document.reference)
                try self.updateFriendCount(transaction: transaction, userId: currentUserId, increment: -1)
                try self.updateFriendCount(transaction: transaction, userId: friendId, increment: -1)
                
                return nil
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
        }

        await loadFriends()
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    private func updateFriendCount(transaction: Transaction, userId: String, increment: Int) throws {
        let userRef = db.collection("users").document(userId)
        let userDoc = try transaction.getDocument(userRef)
        let currentCount = userDoc.data()?["friend_count"] as? Int ?? 0
        let newCount = max(0, currentCount + increment)
        transaction.updateData(["friend_count": newCount], forDocument: userRef)
    }
    
    private func fetchUserDetails(userId: String) async throws -> User? {
        print("Fetching user details for ID: \(userId)")
        let document = try await db.collection("users").document(userId).getDocument()
        if document.exists {
            print("Document exists for user: \(userId)")
            return try? document.data(as: User.self)
        } else {
            print("No document found for user: \(userId)")
            return nil
        }
    }
    
    func loadFriends() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            let snapshot = try await db.collection("friends")
                .whereField("users", arrayContains: currentUserId)
                .whereField("status", isEqualTo: "accepted")
                .getDocuments()
            
            var friendsList: [User] = []
            for document in snapshot.documents {
                let data = document.data()
                let users = data["users"] as? [String] ?? []
                
                if let otherUserId = users.first(where: { $0 != currentUserId }),
                   let user = try? await fetchUserDetails(userId: otherUserId) {
                    friendsList.append(user)
                }
            }
            
            await MainActor.run {
                self.friends = friendsList
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func stopListeningToRequests() {
        requestsListener?.remove()
        requestsListener = nil
    }
} 
