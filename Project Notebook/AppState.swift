import SwiftUI
import Combine

enum Language: String, CaseIterable {
    case english = "en"
    case turkish = "tr"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }
}

final class AppState: ObservableObject {
    @Published var currentLanguage: Language = .english
    
    init() {}
}
