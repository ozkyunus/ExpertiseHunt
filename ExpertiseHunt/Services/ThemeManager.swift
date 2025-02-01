import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    var isDarkMode: Bool = true
    
    let darkTheme = Theme(
        primary: Color(red: 0.1, green: 0.2, blue: 0.4),  // Koyu lacivert
        secondary: Color(red: 0.2, green: 0.3, blue: 0.5), // Orta lacivert
        background: Color(red: 0.05, green: 0.1, blue: 0.2), // En koyu lacivert
        text: Color.white
    )
    
    var current: Theme {
        return darkTheme
    }
}

struct Theme {
    let primary: Color
    let secondary: Color
    let background: Color
    let text: Color
} 
