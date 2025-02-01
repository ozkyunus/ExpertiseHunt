import Foundation
import FirebaseFirestore
import FirebaseStorage

class QuizViewModel: ObservableObject {
    @Published var questions: [QuizQuestion] = []
    @Published var questionImages: [String: UIImage] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentQuestionIndex = 0
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var imageLoadTasks: [String: StorageDownloadTask] = [:]
    
    func fetchQuestions() {
        isLoading = true
        
        db.collection("questions")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    self.isLoading = false
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.questions = documents.compactMap { document in
                        let data = document.data()
                        return QuizQuestion(
                            id: document.documentID,
                            question: data["question"] as? String ?? "",
                            options: data["options"] as? [String] ?? [],
                            correctAnswer: data["correctAnswer"] as? Int ?? 0,
                            explanation: data["explanation"] as? String ?? "",
                            mediaType: data["mediaType"] as? String,
                            mediaURL: data["mediaURL"] as? String
                        )
                    }
                    if let firstQuestion = self.questions.first {
                        self.preloadImagesForNextQuestions(startIndex: 0)
                    }
                }
                
                self.isLoading = false
            }
    }
    
    private func preloadImagesForNextQuestions(startIndex: Int) {
        let endIndex = min(startIndex + 3, questions.count)
        for index in startIndex..<endIndex {
            let question = questions[index]
            if let mediaType = question.mediaType,
               let mediaURL = question.mediaURL,
               mediaType == "image" && !mediaURL.isEmpty {
                loadQuestionImage(for: question)
            }
        }
    }
    
    private func loadQuestionImage(for question: QuizQuestion) {
        guard let mediaURL = question.mediaURL else { return }
        if questionImages[mediaURL] != nil || imageLoadTasks[mediaURL] != nil {
            return
        }
        
        let imageRef = storage.reference().child(mediaURL)
        let task = imageRef.getData(maxSize: 5 * 1024 * 1024) { [weak self] data, error in
            DispatchQueue.main.async {
                self?.imageLoadTasks[mediaURL] = nil
                
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    self?.questionImages[mediaURL] = image
                }
            }
        }
        
        imageLoadTasks[mediaURL] = task
    }
    
    func moveToNextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            preloadImagesForNextQuestions(startIndex: currentQuestionIndex)
        } else {
            currentQuestionIndex = 0
            preloadImagesForNextQuestions(startIndex: 0)
        }
    }
    
    func getImage(for question: QuizQuestion) -> UIImage? {
        guard let mediaURL = question.mediaURL else { return nil }
        return questionImages[mediaURL]
    }
} 
