struct Avatar: Identifiable {
    let id: String
    let imageName: String
    let url: String
    
    static let defaultAvatars = [
        Avatar(id: "avatar1", imageName: "soccer_player1", url: "avatars/soccer_player1.png"),
        Avatar(id: "avatar2", imageName: "soccer_player2", url: "avatars/soccer_player2.png"),
        Avatar(id: "avatar3", imageName: "soccer_player3", url: "avatars/soccer_player3.png"),
        Avatar(id: "avatar4", imageName: "referee", url: "avatars/referee.png"),
        Avatar(id: "avatar5", imageName: "coach", url: "avatars/coach.png"),
    ]
} 
