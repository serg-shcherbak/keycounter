import Foundation

enum CountingMode: String, Codable, CaseIterable {
    case smart = "Smart"
    case allExceptModifiers = "AllExceptModifiers"
    case allKeyDown = "AllKeyDown"
    
    var localizedName: String {
        switch self {
        case .smart: return "Smart Counting"
        case .allExceptModifiers: return "All except Modifiers"
        case .allKeyDown: return "All Keystrokes"
        }
    }
}
