import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn = false
    @AppStorage("rememberMe") private var rememberMe = false
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            if isUserLoggedIn {
                MainMenuView(isUserLoggedIn: $isUserLoggedIn)
            } else {
                LoginView(isUserLoggedIn: $isUserLoggedIn)
            }
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            if let _ = Auth.auth().currentUser {
                isUserLoggedIn = true
            }
            
            Auth.auth().addStateDidChangeListener { auth, user in
                withAnimation {
                    isUserLoggedIn = user != nil
                }
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 
