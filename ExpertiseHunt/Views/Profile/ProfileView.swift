import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showImagePicker = false
    @State private var showUsernameEdit = false
    @State private var newUsername = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if let profileImage = viewModel.profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
                
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 45, y: 45)
            }
            VStack(spacing: 10) {
                if showUsernameEdit {
                    HStack {
                        TextField("Kullanıcı adı", text: $newUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Kaydet") {
                            viewModel.updateUsername()
                            showUsernameEdit = false
                        }
                        .disabled(newUsername.isEmpty)
                    }
                    .padding(.horizontal)
                } else {
                    HStack {
                        Text(viewModel.profile?.username ?? "Kullanıcı Adı Ekle")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Button(action: {
                            newUsername = viewModel.profile?.username ?? ""
                            showUsernameEdit = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Text(viewModel.profile?.email ?? "")
                    .foregroundColor(.gray)
                
                HStack {
                    Text("ID: \(viewModel.profile?.userID ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        UIPasteboard.general.string = viewModel.profile?.userID
                        viewModel.showAlert(title: "Kopyalandı", message: "ID panoya kopyalandı")
                    }) {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            HStack(spacing: 40) {
                VStack {
                    Text("\(viewModel.profile?.friendCount ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Arkadaş")
                        .foregroundColor(.gray)
                }
            }
            .padding(.top)
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ProfileImagePickerView(selectedImage: $viewModel.selectedImage)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .onAppear {
            viewModel.loadProfile()
        }
    }
} 
