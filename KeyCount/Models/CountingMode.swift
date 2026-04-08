import Foundation

enum CountingMode: String, Codable, CaseIterable {
    case smart = "Smart"
    case allExceptModifiers = "AllExceptModifiers"
    case allKeyDown = "AllKeyDown"
    
    var localizedName: String {
        switch self {
        case .smart: return "Умный подсчет"
        case .allExceptModifiers: return "Все кроме модификаторов"
        case .allKeyDown: return "Полный подсчет"
        }
    }
}
