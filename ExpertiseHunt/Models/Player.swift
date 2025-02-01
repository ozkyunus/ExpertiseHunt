import Foundation

struct Player: Identifiable {
    let id = UUID()
    let name: String
    let imageURL: String
    let age: Int
    let nationality: String
    let currentTeam: String
    let marketValue: Double
    let seasonStats: SeasonStats
}

struct SeasonStats {
    let injuries: [Injury]?
    let trophies: [String]?
}

struct Injury {
    let type: String
    let reason: String
    let startDate: String
    let endDate: String
}
