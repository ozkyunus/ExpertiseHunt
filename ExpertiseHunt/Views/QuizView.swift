import SwiftUI

struct QuizView: View {
    @StateObject private var viewModel = QuizViewModel()
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showExplanation = false
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Sorular yükleniyor...")
            } else if let currentQuestion = viewModel.questions[safe: currentQuestionIndex] {
                ScrollView {
                    VStack(spacing: 20) {
                        if let mediaType = currentQuestion.mediaType,
                           let mediaURL = currentQuestion.mediaURL,
                           mediaType == "image",
                           let image = viewModel.getImage(for: currentQuestion) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                        }

                        Text(currentQuestion.question)
                            .font(.title3)
                            .padding()

                        ForEach(currentQuestion.options.indices, id: \.self) { index in
                            Button(action: {
                                selectedAnswer = index
                            }) {
                                HStack {
                                    Text(currentQuestion.options[index])
                                    Spacer()
                                    if let selected = selectedAnswer, selected == index {
                                        Image(systemName: selected == currentQuestion.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(selected == currentQuestion.correctAnswer ? .green : .red)
                                    }
                                }
                                .padding()
                                .background(selectedAnswer == index ? (index == currentQuestion.correctAnswer ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .disabled(selectedAnswer != nil)
                        }
                        
                        if selectedAnswer != nil {
                            Button("Açıklamayı Göster") {
                                showExplanation = true
                            }
                            .padding()
                            
                            Button("Sonraki Soru") {
                                nextQuestion()
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            } else {
                Text("Soru bulunamadı")
            }
        }
        .navigationTitle("Quiz")
        .alert("Açıklama", isPresented: $showExplanation) {
            Button("Tamam", role: .cancel) { }
        } message: {
            if let question = viewModel.questions[safe: currentQuestionIndex] {
                Text(question.explanation)
            }
        }
        .onAppear {
            viewModel.fetchQuestions()
        }
    }
    
    private func nextQuestion() {
        selectedAnswer = nil
        showExplanation = false
        if currentQuestionIndex < viewModel.questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            currentQuestionIndex = 0
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
