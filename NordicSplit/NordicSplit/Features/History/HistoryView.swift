import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SplitRecord.date, order: .reverse)
    private var records: [SplitRecord]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("History")
        }
    }

    // MARK: - List

    private var list: some View {
        List {
            ForEach(records) { record in
                NavigationLink(destination: HistoryDetailView(record: record)) {
                    HistoryRow(record: record)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    modelContext.delete(records[index])
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No splits yet")
                .font(.title3.weight(.medium))
            Text("Saved splits will appear here.")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
    }
}

// MARK: - Row

struct HistoryRow: View {
    let record: SplitRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.formattedTotal)
                    .font(.headline)
                Text("\(record.personCount) people · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if record.tipPercent > 0 {
                Text("+\(Int(record.tipPercent))% tip")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail

struct HistoryDetailView: View {
    let record: SplitRecord

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Total", value: record.formattedTotal)
                if record.tipPercent > 0 {
                    LabeledContent("Tip", value: "\(Int(record.tipPercent))%")
                }
                LabeledContent("Date", value: record.date.formatted())
            }

            Section("People") {
                ForEach(record.people) { person in
                    HStack {
                        Text(person.name)
                        Spacer()
                        let formatter = NumberFormatter()
                        let _ = { formatter.numberStyle = .currency; formatter.currencyCode = record.currencyCode }()
                        Text(formatter.string(from: person.share as NSDecimalNumber) ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Split details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
