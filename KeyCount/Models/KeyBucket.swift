import Foundation
import SwiftData

@Model
final class KeyBucket {
    @Attribute(.unique) var timestamp: Date // Начало минуты
    var count: Int
    
    init(timestamp: Date, count: Int = 0) {
        self.timestamp = timestamp
        self.count = count
    }
    
    /// Получить дату начала текущей минуты для временной метки
    static func normalizedTimestamp(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }
}
