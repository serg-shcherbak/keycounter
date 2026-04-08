import Foundation

struct NumberFormatterUtils {
    static func formatXK(_ count: Int) -> String {
        let cappedCount = min(count, 99000)
        
        if cappedCount < 1000 {
            let kValue = Double(cappedCount) / 1000.0
            return String(format: "%.1fK", kValue)
        } else if cappedCount < 10000 {
            let kValue = Double(cappedCount) / 1000.0
            return String(format: "%.1fK", kValue)
        } else {
            let kValue = cappedCount / 1000
            return "\(kValue)K"
        }
    }
    
    static func formatFull(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}
