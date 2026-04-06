import Foundation
import Observation

/// Drives the split screen. All mutation happens here; views are pure projections.
@Observable
final class SplitModel {

    // MARK: - Input state
    var totalString: String = ""
    var people: [Person] = []
    var tipPercent: Double = 0
    var splitMode: SplitMode = .even
    var currency: Currency = .init()

    // MARK: - Computed totals

    var total: Decimal {
        Decimal(string: totalString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var tipAmount: Decimal {
        total * Decimal(tipPercent / 100)
    }

    var grandTotal: Decimal {
        total + tipAmount
    }

    /// Per-person share when splitting evenly.
    var evenShare: Decimal {
        guard !people.isEmpty else { return 0 }
        return (grandTotal / Decimal(people.count)).rounded(scale: 2)
    }

    /// Remaining after distributing custom shares; assigned to the last person.
    var remainder: Decimal {
        let customSum = people.reduce(Decimal(0)) { $0 + ($1.customShare ?? 0) }
        return max(0, grandTotal - customSum)
    }

    var isValid: Bool {
        total > 0 && !people.isEmpty
    }

    // MARK: - Mutations

    func addPerson(name: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let display = trimmed.isEmpty ? "Person \(people.count + 1)" : trimmed
        people.append(Person(name: display))
    }

    func removePerson(at offsets: IndexSet) {
        people.remove(atOffsets: offsets)
    }

    func share(for person: Person) -> Decimal {
        switch splitMode {
        case .even:
            return evenShare
        case .custom:
            if let idx = people.firstIndex(where: { $0.id == person.id }),
               idx == people.index(before: people.endIndex) {
                // Last person absorbs the remainder
                return person.customShare ?? remainder
            }
            return person.customShare ?? 0
        }
    }

    func updateCustomShare(_ value: String, for person: Person) {
        guard let idx = people.firstIndex(where: { $0.id == person.id }) else { return }
        people[idx].customShare = Decimal(string: value.replacingOccurrences(of: ",", with: "."))
    }

    func reset() {
        totalString = ""
        people = []
        tipPercent = 0
        splitMode = .even
    }

    // MARK: - Types

    enum SplitMode: String, CaseIterable {
        case even = "Even"
        case custom = "Custom"
    }
}

// MARK: - Person model

struct Person: Identifiable {
    let id: UUID = UUID()
    var name: String
    var phoneNumber: String = ""
    var customShare: Decimal? = nil
    var paid: Bool = false
}

// MARK: - Currency helper

struct Currency {
    var code: String = Locale.current.currency?.identifier ?? "NOK"

    var symbol: String {
        Locale.current.currencySymbol ?? code
    }

    func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(symbol)\(amount)"
    }
}

// MARK: - Decimal rounding helper

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var result = Decimal()
        var mutable = self
        NSDecimalRound(&result, &mutable, scale, .plain)
        return result
    }
}
