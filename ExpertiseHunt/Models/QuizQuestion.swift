import Foundation
import FirebaseFirestore

struct QuizQuestion: Identifiable, Codable {
    var id: String
    var question: String
    var options: [String]
    var correctAnswer: Int
    var explanation: String
    var mediaType: String?
    var mediaURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case options
        case correctAnswer
        case explanation
        case mediaType
        case mediaURL
    }
} 
