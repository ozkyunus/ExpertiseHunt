import SwiftUI

struct BlurImageView: View {
    let imageName: String
    let playerName: String
    let isBlurred: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .blur(radius: isBlurred ? 8 : 0)
                .animation(.easeInOut(duration: 0.5), value: isBlurred)
            
            if !isBlurred {
                Text(playerName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .transition(.opacity)
            }
        }
    }
} 