import FirebaseFirestore
import FirebaseStorage
import UIKit

class RoomViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private var imageCache: [String: UIImage] = [:]
    
    func loadQuestions(for category: String) async {
        await MainActor.run { 
            isLoading = true 
            questions = []
        }
        
        do {
            print("Loading questions for category: \(category)")
            
            let snapshot = try await db.collection(category)
                .getDocuments()
            
            print("Found \(snapshot.documents.count) questions in \(category)")
            
            var loadedQuestions: [Question] = []
            
            for document in snapshot.documents {
                print("Processing document: \(document.documentID)")
                do {
                    let data = document.data()
                    
                    let question = Question(
                        id: document.documentID,
                        question: data["question"] as? String,
                        mediaType: data["mediaType"] as? String,
                        mediaURL: data["mediaURL"] as? String,
                        options: data["options"] as? [String] ?? [],
                        correctAnswer: data["correctAnswer"] as? Int ?? 0,
                        difficulty: data["difficulty"] as? String,
                        explanation: data["explanation"] as? String
                    )
                    if let mediaURL = question.mediaURL,
                       question.mediaType == "image" {
                        do {
                            let imageRef = storage.child(mediaURL)
                            print("Trying to download image from path: \(mediaURL)")
                            
                            do {
                                let downloadURL = try await imageRef.downloadURL()
                                print("Got download URL: \(downloadURL)")
                                
                                let (imageData, _) = try await URLSession.shared.data(from: downloadURL)
                                if let image = UIImage(data: imageData) {
                                    await MainActor.run {
                                        self.imageCache[mediaURL] = image
                                        print("Successfully cached image for: \(mediaURL)")
                                    }
                                }
                            } catch let storageError {
                                print("Failed to get download URL: \(storageError.localizedDescription)")
                                print("Storage path attempted: \(mediaURL)")
                            }
                        } catch let processingError {
                            print("Error processing image URL: \(processingError.localizedDescription)")
                        }
                    }
                    
                    loadedQuestions.append(question)
                    print("Successfully loaded question: \(question.question ?? "")")
                } catch let decodingError {
                    print("Error decoding question: \(decodingError.localizedDescription)")
                }
            }
            
            await MainActor.run {
                self.questions = loadedQuestions
                self.isLoading = false
                if loadedQuestions.isEmpty {
                    self.error = NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Bu kategoride henüz soru bulunmuyor"]
                    )
                }
            }
        } catch let loadError {
            print("Error loading questions: \(loadError.localizedDescription)")
            await MainActor.run {
                self.error = loadError
                self.isLoading = false
            }
        }
    }
    
    func getImage(for question: Question) -> UIImage? {
        guard let mediaURL = question.mediaURL else { return nil }
        return imageCache[mediaURL]
    }
}

