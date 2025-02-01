import SwiftUI

struct PlayerImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 150, height: 150)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 15))
    }
} 