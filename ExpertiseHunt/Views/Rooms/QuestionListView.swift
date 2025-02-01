import SwiftUI

struct QuestionListView: View {
    let questions: [Question]
    @State private var selectedQuestion: Question?
    @State private var showQuestion = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(questions) { question in
                    QuestionCard(question: question)
                        .onTapGesture {
                            selectedQuestion = question
                            showQuestion = true
                        }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showQuestion) {
            if let question = selectedQuestion {
                QuestionDetailView(question: question)
            }
        }
    }
}

struct QuestionCard: View {
    let question: Question
    
    var body: some View {
        HStack {
            if let mediaURL = question.mediaURL {
                AsyncImage(url: URL(string: mediaURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let questionText = question.question {
                    Text(questionText)
                        .lineLimit(2)
                        .font(.system(size: 16, weight: .medium))
                }
                
                HStack {
                    // Zorluk seviyesi
                    if let difficulty = question.difficulty {
                        Text(difficulty)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor(difficulty))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy": return .green.opacity(0.3)
        case "medium": return .yellow.opacity(0.3)
        case "hard": return .red.opacity(0.3)
        default: return .gray.opacity(0.3)
        }
    }
} 
