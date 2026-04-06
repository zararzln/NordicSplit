import SwiftData
import Foundation

/// Persisted record of a completed split session.
@Model
final class SplitRecord {
    var total: Decimal
    var currencyCode: String
    var tipPercent: Double
    var date: Date

    @Relationship(deleteRule: .cascade, inverse: \PersonRecord.split)
    var people: [PersonRecord] = []

    init(total: Decimal, currencyCode: String, tipPercent: Double, date: Date) {
        self.total = total
        self.currencyCode = currencyCode
        self.tipPercent = tipPercent
        self.date = date
    }

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: total as NSDecimalNumber) ?? "\(total)"
    }

    var personCount: Int { people.count }
}

/// A single person's record within a SplitRecord.
@Model
final class PersonRecord {
    var name: String
    var share: Decimal
    var split: SplitRecord?

    init(name: String, share: Decimal) {
        self.name = name
        self.share = share
    }
}
