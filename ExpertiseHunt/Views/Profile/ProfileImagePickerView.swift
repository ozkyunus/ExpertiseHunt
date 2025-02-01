import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileImagePickerView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImageSource: ImageSource?
    @State private var selectedAvatar: Avatar?
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    enum ImageSource {
        case library, camera, avatar
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Avatar Seçenekleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Avatar.defaultAvatars) { avatar in
                            Image(avatar.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(selectedAvatar?.id == avatar.id ? Color.blue : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedAvatar = avatar
                                    selectedImage = nil
                                }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Fotoğraf Seçenekleri
                VStack(spacing: 15) {
                    Button(action: {
                        selectedImageSource = .library
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Galeriden Seç")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        selectedImageSource = .camera
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Fotoğraf Çek")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Profil Fotoğrafı")
            .navigationBarItems(
                leading: Button("İptal") { dismiss() },
                trailing: Button("Kaydet") {
                    if let avatar = selectedAvatar {
                        saveProfileImage(avatarUrl: avatar.url)
                    } else if let image = selectedImage {
                        uploadAndSaveProfileImage(image)
                    }
                }
                .disabled(selectedImage == nil && selectedAvatar == nil)
            )
        }
        .sheet(isPresented: $showImagePicker) {
            if selectedImageSource == .library {
                ImagePicker(image: $selectedImage)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    private func saveProfileImage(avatarUrl: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(currentUser.uid).updateData([
            "profileImageUrl": avatarUrl,
            "isDefaultAvatar": true
        ]) { error in
            if let error = error {
                showAlert(title: "Hata", message: error.localizedDescription)
            } else {
                dismiss()
            }
        }
    }
    
    private func uploadAndSaveProfileImage(_ image: UIImage) {
        guard let currentUser = Auth.auth().currentUser else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("profile_images/\(currentUser.uid)/\(UUID().uuidString).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                showAlert(title: "Hata", message: error.localizedDescription)
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    showAlert(title: "Hata", message: error.localizedDescription)
                    return
                }
                
                if let url = url {
                    let db = Firestore.firestore()
                    db.collection("users").document(currentUser.uid).updateData([
                        "profileImageUrl": url.absoluteString,
                        "isDefaultAvatar": false
                    ]) { error in
                        if let error = error {
                            showAlert(title: "Hata", message: error.localizedDescription)
                        } else {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
