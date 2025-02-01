import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Binding var isUserLoggedIn: Bool
    @AppStorage("rememberMe") private var rememberMe = false
    
    var body: some View {
        VStack(spacing: 25) {
            // Logo ve Başlık
            VStack(spacing: 15) {
                Image(systemName: "soccerball")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("ExpertiseHunt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top, 50)
            
            // Giriş Formu
            VStack(spacing: 20) {
                TextField("E-posta", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Şifre", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Beni Hatırla seçeneği
                Toggle(isOn: $rememberMe) {
                    Text("Beni Hatırla")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleLogin) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Giriş Yap")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 50)
                .background(Color.green)
                .cornerRadius(10)
                .disabled(isLoading)
            }
            .padding(.horizontal)
            
            // Google ile Giriş
            Button(action: handleGoogleLogin) {
                HStack {
                    Image("google_logo") // Assets'e ekleyin
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Google ile Giriş Yap")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            // Kayıt Ol Butonu
            Button(action: { showingSignUp = true }) {
                Text("Hesabın yok mu? Kayıt Ol")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView(isUserLoggedIn: $isUserLoggedIn)
        }
    }
    
    private func handleLogin() {
        isLoading = true
        AuthService.shared.signIn(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(_):
                    UserDefaults.standard.set(self.rememberMe, forKey: "rememberMe")
                    self.isUserLoggedIn = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleGoogleLogin() {
        isLoading = true
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Client ID bulunamadı"
            isLoading = false
            return
        }
        
        let signInConfig = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = signInConfig
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "View Controller bulunamadı"
            isLoading = false
            return
        }
        
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if let signInResult = signInResult {
                            continuation.resume(returning: signInResult)
                        } else {
                            continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in result was nil"]))
                        }
                    }
                }
                
                guard let idToken = result.user.idToken?.tokenString else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID Token alınamadı"])
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
                
                AuthService.shared.handleGoogleSignIn(credential: credential) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            self.isUserLoggedIn = true
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
} 