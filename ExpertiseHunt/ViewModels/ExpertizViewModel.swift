//
//  ExpertiseViewModel.swift
//  ExpertiseHunt
//
//  Created by Yunus Emre Özkaya on 15.12.2024.
//

import Foundation
import FirebaseFirestore

@MainActor
class ExpertizViewModel: ObservableObject {
    @Published var currentPlayer: Player
    @Published var hasGuessed = false
    @Published var score = 0
    @Published var currentPlayerIndex = 0
    @Published var isLoading = false
    @Published var error: Error?
    
    private let players: [Player] = [
        Player(
            name: "İlkay Gündoğan",
            imageURL: "ilkay_gundogan",
            age: 33,
            nationality: "Almanya",
            currentTeam: "Barcelona",
            marketValue: 35.0,
            seasonStats: SeasonStats(
                injuries: [
                    Injury(
                        type: "Kas Sakatlığı",
                        reason: "Hafif Zorlanma",
                        startDate: "2023-12-15T00:00:00Z",
                        endDate: "2023-12-30T00:00:00Z"
                    )
                ],
                trophies: ["La Liga", "UEFA Süper Kupa"]
            )
        ),
        Player(
            name: "Vinicius Jr",
            imageURL: "vinicius",
            age: 23,
            nationality: "Brezilya",
            currentTeam: "Real Madrid",
            marketValue: 150.0,
            seasonStats: SeasonStats(
                injuries: [
                    Injury(
                        type: "Kas Sakatlığı",
                        reason: "Zorlanma",
                        startDate: "2023-11-12T00:00:00Z",
                        endDate: "2023-12-01T00:00:00Z"
                    )
                ],
                trophies: ["UEFA Süper Kupa", "FIFA Kulüpler Dünya Kupası"]
            )
        ),
        Player(
            name: "Florian Wirtz",
            imageURL: "wirtz",
            age: 20,
            nationality: "Almanya",
            currentTeam: "Bayer Leverkusen",
            marketValue: 85.0,
            seasonStats: SeasonStats(
                injuries: nil,
                trophies: ["Bundesliga"]
            )
        ),
        Player(
            name: "Davinson Sanchez",
            imageURL: "davinson", 
            age: 27,
            nationality: "Kolombiya",
            currentTeam: "Galatasaray",
            marketValue: 18.0,
            seasonStats: SeasonStats(
                injuries: nil,
                trophies: ["Türkiye Süper Kupası"]
            )
        )
    ]
    
    init() {
        self.currentPlayer = players[0]
    }
    
    var isLastPlayer: Bool {
        currentPlayerIndex == players.count - 1
    }
    
    func makeGuess(_ value: Double) {
        hasGuessed = true
    }
    
    func nextPlayer() {
        if currentPlayerIndex < players.count - 1 {
            currentPlayerIndex += 1
            currentPlayer = players[currentPlayerIndex]
            hasGuessed = false
        }
    }
    
    func calculateScore(guessedValue: Double) -> Int {
        let difference = abs(guessedValue - currentPlayer.marketValue)
        let percentage = (difference / currentPlayer.marketValue) * 100
        
        if percentage <= 5 { return 100 }
        if percentage <= 10 { return 80 }
        if percentage <= 20 { return 60 }
        if percentage <= 30 { return 40 }
        if percentage <= 40 { return 20 }
        return 0
    }
}
