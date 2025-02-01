import SwiftUI

struct FriendRequestCard: View {
    let request: Models.FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(request.fromUsername.isEmpty ? request.fromEmail : request.fromUsername)
                        .font(.headline)
                    Text("ID: \(request.fromUserID)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 15) {
                Button(action: onAccept) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Kabul Et")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reddet")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
} 