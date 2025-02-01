import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    var currentUser: FirebaseAuth.User? {
        return auth.currentUser
    }
    
    func checkSignInMethod(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        auth.fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let methods = methods, !methods.isEmpty {
                completion(.success(methods[0]))
            } else {
                completion(.success(""))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        auth.fetchSignInMethods(forEmail: email) { [weak self] methods, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let methods = methods {
                if methods.isEmpty {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bu email adresi ile kayıtlı hesap bulunamadı"])))
                } else if methods.contains("password") {
                    self.auth.signIn(withEmail: email, password: password) { result, error in
                        if let error = error {
                            completion(.failure(error))
                        } else if let user = result?.user {
                            completion(.success(user))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bu email adresi Google hesabı ile kayıtlı. Lütfen Google ile giriş yapın."])))
                }
            }
        }
    }
    
    func handleGoogleSignIn(credential: AuthCredential, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        auth.signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                self.createUserIfNeeded(user: user) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(user))
                    }
                }
            }
        }
    }
    
    private func createUserIfNeeded(user: FirebaseAuth.User, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            if snapshot?.exists != true {
                self?.generateUniqueUserID { result in
                    switch result {
                    case .success(let userID):
                        let userData: [String: Any] = [
                            "email": user.email ?? "",
                            "userID": userID,
                            "username": "",
                            "friendCount": 0,
                            "score": 0,
                            "createdAt": FieldValue.serverTimestamp()
                        ]
                        
                        let batch = db.batch()
                        
                        let userRef = db.collection("users").document(user.uid)
                        batch.setData(userData, forDocument: userRef)
                        
                        let idRef = db.collection("userIDs").document(userID)
                        batch.setData([
                            "uid": user.uid,
                            "email": user.email ?? "",
                            "createdAt": FieldValue.serverTimestamp()
                        ], forDocument: idRef)
                        
                        batch.commit(completion: completion)
                        
                        UserDefaults.standard.set(userID, forKey: "userID_\(user.uid)")
                        
                    case .failure(let error):
                        completion(error)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    private func generateUniqueUserID(completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        
        func tryGenerateID() {
            let userID = String(format: "%06d", Int.random(in: 100000...999999))
            
            db.collection("userIDs").document(userID).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if snapshot?.exists == true {
                    tryGenerateID()
                } else {
                    completion(.success(userID))
                }
            }
        }
        
        tryGenerateID()
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                completion(.success(user))
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"]))
            return
        }
        
        let userId = currentUser.uid
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            if let userData = snapshot?.data(),
               let userID = userData["userID"] as? String {
                
                self.deleteAllFriendships(userId: userId) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    self.deleteAllFriendRequests(userId: userId) { error in
                        if let error = error {
                            completion(error)
                            return
                        }
                        
                        StorageService.shared.deleteProfileImage(for: userId) { _ in
                            let batch = self.db.batch()
                            
                            batch.deleteDocument(self.db.collection("users").document(userId))
                            batch.deleteDocument(self.db.collection("userIDs").document(userID))
                            
                            batch.commit { error in
                                if let error = error {
                                    completion(error)
                                    return
                                }
                                
                                currentUser.delete { error in
                                    completion(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteAllFriendships(userId: String, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var friendshipDocs: [QueryDocumentSnapshot] = []
        
        group.enter()
        db.collection("friendships")
            .whereField("user1", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let docs = snapshot?.documents {
                    friendshipDocs.append(contentsOf: docs)
                }
            }
        
        group.enter()
        db.collection("friendships")
            .whereField("user2", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let docs = snapshot?.documents {
                    friendshipDocs.append(contentsOf: docs)
                }
            }
        
        group.notify(queue: .main) {
            let batch = self.db.batch()
            
            for doc in friendshipDocs {
                batch.deleteDocument(doc.reference)
            }
            
            batch.commit(completion: completion)
        }
    }
    
    private func deleteAllFriendRequests(userId: String, completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var requestDocs: [QueryDocumentSnapshot] = []
        
        group.enter()
        db.collection("friendRequests")
            .whereField("fromUID", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let docs = snapshot?.documents {
                    requestDocs.append(contentsOf: docs)
                }
            }
        
        group.enter()
        db.collection("friendRequests")
            .whereField("toUID", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { group.leave() }
                if let docs = snapshot?.documents {
                    requestDocs.append(contentsOf: docs)
                }
            }
        
        group.notify(queue: .main) {
            let batch = self.db.batch()
            
            for doc in requestDocs {
                batch.deleteDocument(doc.reference)
            }
            
            batch.commit(completion: completion)
        }
    }
} 