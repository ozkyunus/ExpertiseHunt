import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    @Binding var isUserLoggedIn: Bool
    
    private let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Yeni Hesap Oluştur")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                TextField("E-posta", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                
                SecureField("Şifre", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Şifre Tekrar", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: handleSignUp) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Kayıt Ol")
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
            
            Button(action: { dismiss() }) {
                Text("Zaten hesabın var mı? Giriş Yap")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(.top, 50)
    }
    
    private func generateUserID() -> String {
        // 6 haneli rastgele ID oluştur
        String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    private func checkEmailAvailability(completion: @escaping (Bool) -> Void) {
        let emailLower = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        Auth.auth().fetchSignInMethods(forEmail: emailLower) { methods, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Email check error: \(error)")
                    self.errorMessage = "Email kontrolü sırasında bir hata oluştu"
                    completion(false)
                    return
                }

                let isEmailAvailable = (methods ?? []).isEmpty
                completion(isEmailAvailable)
            }
        }
    }
    
    private func handleSignUp() {
        let emailLower = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        

        if !isValidEmail(emailLower) {
            errorMessage = "Geçerli bir email adresi giriniz"
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Şifreler eşleşmiyor"
            return
        }
        
        if password.count < 6 {
            errorMessage = "Şifre en az 6 karakter olmalıdır"
            return
        }
        
        isLoading = true
        
        checkEmailAvailability { isAvailable in
            if !isAvailable {
                self.isLoading = false
                self.errorMessage = "Bu email adresi zaten kullanımda"
                return
            }

            Auth.auth().createUser(withEmail: emailLower, password: self.password) { result, error in
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let user = result?.user {
                    let db = Firestore.firestore()
                    

                    func createAndCheckUserID() -> String {
                        let userID = String(format: "%06d", Int.random(in: 100000...999999))
                        return userID
                    }
                    
                    let userID = createAndCheckUserID()
                    

                    let userData = [
                        "email": emailLower,
                        "userID": userID,
                        "friendCount": 0,
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    
                    db.collection("users").document(user.uid).setData(userData) { error in
                        if let error = error {
                            self.isLoading = false
                            self.errorMessage = "Kullanıcı bilgileri kaydedilemedi: \(error.localizedDescription)"
                            return
                        }
                        

                        let idData = [
                            "uid": user.uid,
                            "email": emailLower,
                            "createdAt": FieldValue.serverTimestamp()
                        ]
                        
                        db.collection("userIDs").document(userID).setData(idData) { error in
                            self.isLoading = false
                            
                            if let error = error {
                                print("UserID kaydedilemedi: \(error.localizedDescription)")

                            }
                            
                            self.isUserLoggedIn = true
                            self.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        return emailPredicate.evaluate(with: email)
    }
}  
