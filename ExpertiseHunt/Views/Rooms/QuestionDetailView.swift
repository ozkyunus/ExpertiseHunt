import SwiftUI

struct QuestionDetailView: View {
    let question: Question
    @Environment(\.dismiss) var dismiss
    @State private var selectedAnswer: Int?
    @State private var showResult = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let mediaURL = question.mediaURL {
                    AsyncImage(url: URL(string: mediaURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } placeholder: {
                        ProgressView()
                    }
                }
                if let questionText = question.question {
                    Text(questionText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                VStack(spacing: 12) {
                    ForEach(question.options.indices, id: \.self) { index in
                        Button {
                            selectedAnswer = index
                            showResult = true
                        } label: {
                            HStack {
                                Text(question.options[index])
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding()
                            .background(optionBackground(for: index))
                            .cornerRadius(10)
                        }
                        .disabled(showResult)
                    }
                }
                .padding()
                                if showResult {
                    VStack(spacing: 10) {
                        Text(selectedAnswer == question.correctAnswer ? "Doğru!" : "Yanlış!")
                            .font(.title2)
                            .foregroundColor(selectedAnswer == question.correctAnswer ? .green : .red)
                        
                        if let explanation = question.explanation {
                            Text("Açıklama:")
                                .font(.headline)
                            Text(explanation)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Kapat") {
                    dismiss()
                }
            }
        }
    }
    
    private func optionBackground(for index: Int) -> Color {
        guard showResult else {
            return selectedAnswer == index ? .blue.opacity(0.3) : Color(.systemGray6)
        }
        
        if index == question.correctAnswer {
            return .green.opacity(0.3)
        }
        if index == selectedAnswer && selectedAnswer != question.correctAnswer {
            return .red.opacity(0.3)
        }
        return Color(.systemGray6)
    }
} 
