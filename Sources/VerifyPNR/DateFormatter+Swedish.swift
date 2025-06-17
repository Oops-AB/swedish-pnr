import Foundation

extension DateFormatter {
    public static let swedishDate = {
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Stockholm")

        return formatter
    }()
}
