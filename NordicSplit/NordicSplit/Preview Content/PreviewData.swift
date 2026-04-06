import Foundation

/// Sample data for Xcode previews and SwiftUI canvas.
enum PreviewData {

    static var splitModel: SplitModel {
        let m = SplitModel()
        m.totalString = "349.00"
        m.tipPercent = 15
        m.people = [
            Person(name: "Anna", phoneNumber: "98765432"),
            Person(name: "Bjørn", phoneNumber: ""),
            Person(name: "Camilla", phoneNumber: "91234567")
        ]
        return m
    }

    static var people: [Person] {
        [
            Person(name: "Anna Larsen", phoneNumber: "98765432"),
            Person(name: "Ole Berg"),
            Person(name: "Mia K.", phoneNumber: "41234567", paid: true)
        ]
    }

    static var splitRecord: SplitRecord {
        let record = SplitRecord(total: 349.00, currencyCode: "NOK", tipPercent: 15, date: .now)
        record.people = [
            PersonRecord(name: "Anna", share: 133.68),
            PersonRecord(name: "Bjørn", share: 133.68),
            PersonRecord(name: "Camilla", share: 133.64)
        ]
        return record
    }
}
