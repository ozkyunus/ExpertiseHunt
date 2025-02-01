import SwiftUI

struct GurmeView: View {
    var body: some View {
        VStack {
            Text("Gurme Bölümü")
                .font(.title)
                .padding()
            
            Text("Bu bölüm yapım aşamasında...")
                .foregroundColor(.gray)
        }
        .navigationTitle("Gurme")
    }
} 