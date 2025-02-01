import SwiftUI

struct RoomView: View {
    @StateObject private var viewModel = RoomViewModel()
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showExplanation = false
    let category: String
    let title: String
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Sorular yükleniyor...")
            } else if let currentQuestion = viewModel.questions[safe: currentQuestionIndex] {
                ScrollView {
                    VStack(spacing: 20) {
                        if let mediaURL = currentQuestion.mediaURL,
                           currentQuestion.mediaType == "image" {
                            AsyncImage(url: URL(string: mediaURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(10)
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 200)
                            }
                        }
                        if let questionText = currentQuestion.question {
                            Text(questionText)
                                .font(.title3)
                                .padding()
                        }
                        ForEach(currentQuestion.options.indices, id: \.self) { index in
                            Button(action: {
                                selectedAnswer = index
                            }) {
                                HStack {
                                    Text(currentQuestion.options[index])
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if let selected = selectedAnswer, selected == index {
                                        Image(systemName: selected == currentQuestion.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(selected == currentQuestion.correctAnswer ? .green : .red)
                                    }
                                }
                                .padding()
                                .background(buttonBackground(for: index, correctAnswer: currentQuestion.correctAnswer))
                                .cornerRadius(10)
                            }
                            .disabled(selectedAnswer != nil)
                        }
                        
                        if selectedAnswer != nil {
                            if let explanation = currentQuestion.explanation {
                                VStack(spacing: 10) {
                                    Text("Açıklama:")
                                        .font(.headline)
                                    Text(explanation)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            Button(action: nextQuestion) {
                                Text(isLastQuestion ? "Başa Dön" : "Sonraki Soru")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            } else {
                Text("Bu kategoride henüz soru bulunmuyor")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(title)
        .task {
            await viewModel.loadQuestions(for: category)
        }
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == viewModel.questions.count - 1
    }
    
    private func buttonBackground(for index: Int, correctAnswer: Int) -> Color {
        guard let selected = selectedAnswer else {
            return Color(.systemGray6)
        }
        
        if index == correctAnswer {
            return .green.opacity(0.2)
        }
        if index == selected && selected != correctAnswer {
            return .red.opacity(0.2)
        }
        return Color(.systemGray6)
    }
    
    private func nextQuestion() {
        selectedAnswer = nil
        if currentQuestionIndex < viewModel.questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            currentQuestionIndex = 0
        }
    }
} 
