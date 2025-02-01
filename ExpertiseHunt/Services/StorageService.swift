import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    private let imageCache = ImageCacheService.shared
    
    func uploadProfileImage(_ image: UIImage, for userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image compression failed"])))
            return
        }
        deleteProfileImage(for: userId) { _ in
            let imageName = "\(UUID().uuidString).jpg"
            let imageRef = self.storage.reference().child("profile_images/\(userId)/\(imageName)")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            imageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        self?.imageCache.cacheImage(image, forKey: url.absoluteString)
                        completion(.success(url.absoluteString))
                    }
                }
            }
        }
    }
    
    func deleteProfileImage(for userId: String, completion: @escaping (Error?) -> Void) {
        let profileImagesRef = storage.reference().child("profile_images/\(userId)")
        profileImagesRef.listAll { result in
            switch result {
            case .success(let listResult):
                let group = DispatchGroup()
                var lastError: Error?
                for item in listResult.items {
                    group.enter()
                    item.delete { error in
                        if let error = error {
                            lastError = error
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    completion(lastError)
                }
                
            case .failure(let error):
                completion(error)
            }
        }
    }
    func clearCache() {
        imageCache.clearCache()
    }
} 
