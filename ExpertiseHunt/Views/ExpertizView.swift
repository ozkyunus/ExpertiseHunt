import SwiftUI

struct ExpertizView: View {
    @StateObject private var viewModel = ExpertizViewModel()
    @State private var guessText: String = ""
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView
            } else {
                VStack(spacing: 20) {
                    playerCard
                    playerDetails
                    guessSection
                }
                .padding()
            }
        }
        .background(Color(hex: "1C1C1E").ignoresSafeArea())
        .navigationTitle("Expertiz")
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView("Oyuncular yükleniyor...")
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Hata")
                .font(.title)
                .padding(.vertical)
            Text(viewModel.error?.localizedDescription ?? "Bilinmeyen bir hata oluştu")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
    
    // MARK: - Player Card
    private var playerCard: some View {
        VStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "1A5F7A"), Color(hex: "0E3746")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 15) {
                    playerImage
                    playerInfo
                }
                .padding(.vertical, 25)
            }
            .cornerRadius(20)
        }
    }
    
    private var playerImage: some View {
        Image(viewModel.currentPlayer.imageURL)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(radius: 5)
            .overlay(
                Group {
                    if !viewModel.hasGuessed {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 140)
                    }
                }
            )
    }
    
    private var playerInfo: some View {
        VStack(spacing: 8) {
            if viewModel.hasGuessed {
                Text(viewModel.currentPlayer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 15) {
                PlayerInfoBadge(icon: "calendar", text: "\(viewModel.currentPlayer.age)")
                PlayerInfoBadge(icon: "flag.fill", text: viewModel.currentPlayer.nationality)
                PlayerInfoBadge(icon: "sportscourt.fill", text: viewModel.currentPlayer.currentTeam)
            }
        }
    }
    
    // MARK: - Player Details
    private var playerDetails: some View {
        VStack(spacing: 15) {
            DetailCard(
                title: "Temel Bilgiler",
                icon: "person.fill",
                items: [
                    "Yaş: \(viewModel.currentPlayer.age)",
                    "Uyruk: \(viewModel.currentPlayer.nationality)",
                    "Takım: \(viewModel.currentPlayer.currentTeam)"
                ]
            )
            
            if let injuries = viewModel.currentPlayer.seasonStats.injuries, !injuries.isEmpty {
                DetailCard(
                    title: "Sakatlık Geçmişi",
                    icon: "bandage.fill",
                    items: injuries.map { injury in
                        "\(injury.type) - \(injury.reason)\nBaşlangıç: \(formatDate(injury.startDate))\nBitiş: \(injury.endDate)"
                    }
                )
            }
            
            if let kupalar = viewModel.currentPlayer.seasonStats.trophies, !kupalar.isEmpty {
                DetailCard(
                    title: "Kazanılan Kupalar",
                    icon: "trophy.fill",
                    items: kupalar
                )
            }
        }
    }

    // MARK: - Guess Section
    private var guessSection: some View {
        VStack(spacing: 20) {
            if !viewModel.hasGuessed {
                VStack(spacing: 15) {
                    Text("Market Değeri Tahmini")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Değer giriniz", text: $guessText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        withAnimation {
                            viewModel.makeGuess(guessValue)
                        }
                    }) {
                        Text("Tahmin Et")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
            } else {
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tahmininiz")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(guessValue, specifier: "%.1f") M€")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Gerçek Değer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.currentPlayer.marketValue, specifier: "%.1f") M€")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        ScoreView(title: "Kazanılan", score: viewModel.calculateScore(guessedValue: guessValue))
                        Spacer()
                        ScoreView(title: "Toplam", score: viewModel.score)
                    }
                    
                    if !viewModel.isLastPlayer {
                        Button(action: {
                            withAnimation {
                                viewModel.nextPlayer()
                                guessText = ""
                            }
                        }) {
                            Text("Sonraki Oyuncu")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(20)
    }

    // Tarih formatı için yardımcı fonksiyon
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }

    private var guessValue: Double {
        Double(guessText) ?? 0.0
    }
}

// MARK: - Yardımcı Görünümler
struct PlayerInfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.9))
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.2))
        .cornerRadius(20)
    }
}

struct DetailCard: View {
    let title: String
    let icon: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(15)
    }
}

struct ScoreView: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("\(score)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Renk Yardımcısı
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
