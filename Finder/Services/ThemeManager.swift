import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("accentColorName") var accentColorName: String = "blue"

    @Published var currentTheme: FinderTheme = .light

    struct FinderTheme {
        let name: String
        let backgroundColor: Color
        let secondaryBackground: Color
        let cardBackground: Color
        let textPrimary: Color
        let textSecondary: Color
        let accent: Color
        let glassOpacity: Double
        let glassTint: Color

        static let light = FinderTheme(
            name: "light",
            backgroundColor: Color(.systemBackground),
            secondaryBackground: Color(.secondarySystemBackground),
            cardBackground: Color.white.opacity(0.7),
            textPrimary: Color.primary,
            textSecondary: Color.secondary,
            accent: Color.blue,
            glassOpacity: 0.15,
            glassTint: Color.white
        )

        static let dark = FinderTheme(
            name: "dark",
            backgroundColor: Color(.systemBackground),
            secondaryBackground: Color(.secondarySystemBackground),
            cardBackground: Color.white.opacity(0.08),
            textPrimary: Color.primary,
            textSecondary: Color.secondary,
            accent: Color.blue,
            glassOpacity: 0.1,
            glassTint: Color.gray
        )
    }

    private init() {
        currentTheme = isDarkMode ? .dark : .light
    }

    func toggleTheme() {
        isDarkMode.toggle()
        currentTheme = isDarkMode ? .dark : .light
    }

    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
}
