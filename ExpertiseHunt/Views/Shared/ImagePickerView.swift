import SwiftUI
import UIKit

struct ImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImage: UIImage?
    @State private var showSourcePicker = true
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button(action: {
                    sourceType = .camera
                    showSourcePicker = false
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Fotoğraf Çek")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    sourceType = .photoLibrary
                    showSourcePicker = false
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Galeriden Seç")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button("İptal", role: .cancel) {
                    dismiss()
                }
                .padding()
            }
            .padding()
            .navigationTitle("Fotoğraf Seç")
            .sheet(isPresented: .constant(!showSourcePicker)) {
                CustomImagePicker(image: $selectedImage, sourceType: sourceType, isPresented: $showSourcePicker)
            }
        }
    }
}

private struct CustomImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CustomImagePicker
        
        init(_ parent: CustomImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = true
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = true
            picker.dismiss(animated: true)
        }
    }
} 