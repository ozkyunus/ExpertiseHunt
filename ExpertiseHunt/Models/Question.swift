import FirebaseFirestore

struct Question: Identifiable, Codable {
    @DocumentID var id: String?
    let question: String?
    let mediaType: String?
    let mediaURL: String?
    let options: [String]
    let correctAnswer: Int
    let difficulty: String?
    let explanation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case mediaType
        case mediaURL
        case options
        case correctAnswer
        case difficulty
        case explanation
    }
    
    init(id: String? = nil,
         question: String? = nil,
         mediaType: String? = nil,
         mediaURL: String? = nil,
         options: [String] = [],
         correctAnswer: Int = 0,
         difficulty: String? = nil,
         explanation: String? = nil) {
        self.id = id
        self.question = question
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.options = options
        self.correctAnswer = correctAnswer
        self.difficulty = difficulty
        self.explanation = explanation
    }
} 
