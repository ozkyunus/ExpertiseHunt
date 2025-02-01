import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var profileImage: Image?
    @Published var selectedImage: UIImage? {
        didSet {
            if let image = selectedImage {
                uploadProfileImage(image)
            }
        }
    }
    @Published var newUsername: String = ""
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var showSettings = false
    
    private let userService = UserService.shared
    private let storageService = StorageService.shared
    private let imageCache = ImageCacheService.shared
    private let defaults = UserDefaults.standard
    
    init() {
        // Kayıtlı profil fotoğrafını yükle
        if let savedUrl = defaults.string(forKey: "lastProfileImageUrl") {
            loadProfileImage(from: savedUrl)
        }
    }
    
    func loadProfile() {
        userService.loadCurrentUser { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.profile = profile
                    if let urlString = profile.profileImageUrl {
                        self?.loadProfileImage(from: urlString)
                    }
                case .failure(let error):
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                }
            }
        }
    }
    
    func updateUsername() {
        guard !newUsername.isEmpty else { return }
        
        userService.updateUsername(newUsername) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                } else {
                    self?.profile?.username = self?.newUsername ?? ""
                    self?.newUsername = ""
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaledImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        DispatchQueue.main.async {
            self.profileImage = Image(uiImage: scaledImage)
        }
        
        storageService.uploadProfileImage(scaledImage, for: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    // URL'i kaydet
                    self?.defaults.set(url, forKey: "lastProfileImageUrl")
                    
                    DatabaseService.shared.updateUserProfile(userId: userId, data: [
                        "profileImageUrl": url
                    ]) { error in
                        if let error = error {
                            self?.showAlert(title: "Hata", message: error.localizedDescription)
                        } else {
                            self?.profile?.profileImageUrl = url
                        }
                    }
                case .failure(let error):
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        if let cachedImage = imageCache.getImage(forKey: urlString) {
            self.profileImage = Image(uiImage: cachedImage)
            return
        }
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Error loading profile image: \(error)")
                return
            }
            
            if let data = data, let uiImage = UIImage(data: data) {
                let size = CGSize(width: 300, height: 300)
                let renderer = UIGraphicsImageRenderer(size: size)
                let scaledImage = renderer.image { context in
                    uiImage.draw(in: CGRect(origin: .zero, size: size))
                }
                
                self?.imageCache.cacheImage(scaledImage, forKey: urlString)
                
                DispatchQueue.main.async {
                    self?.profileImage = Image(uiImage: scaledImage)
                }
            }
        }.resume()
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    func clearCache() {
        imageCache.clearCache()
        showAlert(title: "Başarılı", message: "Önbellek temizlendi")
    }
    
    func resetProfile() {
        guard let userId = AuthService.shared.currentUser?.uid else { return }
        
        DatabaseService.shared.updateUserProfile(userId: userId, data: [
            "username": "",
            "profileImageUrl": nil
        ]) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                } else {
                    self?.profile?.username = ""
                    self?.profile?.profileImageUrl = nil
                    self?.profileImage = nil
                    self?.clearCache()
                    self?.showAlert(title: "Başarılı", message: "Profil sıfırlandı")
                }
            }
        }
    }
} 