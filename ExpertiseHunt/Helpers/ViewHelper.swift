import UIKit

extension UIApplication {
    func getRootViewController() -> UIViewController {
        guard let window = connectedScenes.first as? UIWindowScene else { return .init() }
        guard let viewController = window.windows.first?.rootViewController else { return .init() }
        
        return viewController
    }
} 