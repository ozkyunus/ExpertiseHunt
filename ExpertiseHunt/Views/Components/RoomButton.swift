import SwiftUI

struct RoomButton: View {
    let title: String
    let image: String
    let category: String
    
    var body: some View {
        NavigationLink(destination: RoomView(category: category, title: title)) {
            HStack {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .padding(.leading, 15)
                
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.leading, 12)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing, 15)
            }
            .frame(height: 70)
            .background(Color(UIColor.systemGray6).opacity(0.1))
            .cornerRadius(35)
        }
    }
} 