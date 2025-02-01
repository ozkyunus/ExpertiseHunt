import SwiftUI

struct FriendCard: View {
    let friend: Friend
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(friend.username.isEmpty ? friend.email : friend.username)
                    .font(.headline)
                Text("ID: \(friend.userID)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "person.badge.minus.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
} 