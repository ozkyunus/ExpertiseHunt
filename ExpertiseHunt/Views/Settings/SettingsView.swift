import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showDeleteConfirmation = false
    @Binding var isUserLoggedIn: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bildirimler")) {
                    Toggle("Bildirimler", isOn: $notificationsEnabled)
                }
                
                Section(header: Text("Hesap")) {
                    Button(action: {
                        viewModel.clearCache()
                    }) {
                        Text("Önbelleği Temizle")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        viewModel.resetProfile()
                    }) {
                        Text("Profili Sıfırla")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Tehlikeli Bölge")) {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Text("Hesabı Sil")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
            .alert("Hesabı Sil", isPresented: $showDeleteConfirmation) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    AuthService.shared.deleteAccount { error in
                        if let error = error {
                            viewModel.showAlert(title: "Hata", message: error.localizedDescription)
                        } else {
                            isUserLoggedIn = false
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
        }
        .preferredColorScheme(.dark)
    }
} 