import SwiftUI
import FirebaseFirestore

extension Color {
    static let statRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let statBlue = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let statGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let statPurple = Color(red: 0.6, green: 0.2, blue: 0.9)
    static let cardGold = Color(red: 0.85, green: 0.7, blue: 0.3)
    static let cardDark = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let cardDarkGray = Color(red: 0.15, green: 0.15, blue: 0.2)
}

extension Font {
    /// SNES-style pixel font for headings, labels, and stat values.
    /// Falls back to system monospaced if font not loaded.
    static func pixel(_ size: CGFloat) -> Font {
        .custom("PressStart2P-Regular", size: size)
    }
}

extension Date {
    var timeAgoDisplay: String {
        let seconds = Int(-self.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        if seconds < 604800 { return "\(seconds / 86400)d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
}

extension Timestamp {
    var dateValue: Date {
        return self.dateValue()
    }
}
