import SwiftUI
import SwiftData

struct SplitView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext

    @State private var model = SplitModel()
    @State private var showReceiptScanner = false
    @State private var showAddPerson = false
    @State private var newPersonName = ""
    @State private var savedConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    totalSection
                    tipSection
                    splitModeSection
                    peopleSection
                    if model.isValid {
                        saveButton
                    }
                }
                .padding()
            }
            .navigationTitle("NordicSplit")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReceiptScanner = true
                    } label: {
                        Image(systemName: "camera.viewfinder")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !model.totalString.isEmpty || !model.people.isEmpty {
                        Button("Reset", role: .destructive) {
                            withAnimation { model.reset() }
                        }
                    }
                }
            }
            .sheet(isPresented: $showReceiptScanner) {
                ReceiptScanView { detected in
                    model.totalString = detected
                }
            }
            .alert("Add person", isPresented: $showAddPerson) {
                TextField("Name", text: $newPersonName)
                Button("Add") {
                    model.addPerson(name: newPersonName)
                    newPersonName = ""
                }
                Button("Cancel", role: .cancel) { newPersonName = "" }
            }
            .overlay(alignment: .bottom) {
                if savedConfirmation {
                    savedBanner
                }
            }
        }
    }

    // MARK: - Sections

    private var totalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Total bill", systemImage: "banknote")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(model.currency.symbol)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                TextField("0.00", text: $model.totalString)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.5)
            }

            if model.tipPercent > 0 {
                HStack {
                    Text("Tip \(Int(model.tipPercent))%")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Spacer()
                    Text("+ \(model.currency.formatted(model.tipAmount))")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
                Divider()
                HStack {
                    Text("Grand total")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(model.currency.formatted(model.grandTotal))
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tip", systemImage: "hand.thumbsup")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach([0, 10, 15, 20], id: \.self) { percent in
                    TipChip(
                        label: percent == 0 ? "No tip" : "\(percent)%",
                        isSelected: Int(model.tipPercent) == percent
                    ) {
                        withAnimation(.spring(duration: 0.2)) {
                            model.tipPercent = Double(percent)
                        }
                        container.haptics.light()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var splitModeSection: some View {
        Picker("Split mode", selection: $model.splitMode) {
            ForEach(SplitModel.SplitMode.allCases, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("People", systemImage: "person.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showAddPerson = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if model.people.isEmpty {
                emptyPeopleState
            } else {
                ForEach($model.people) { $person in
                    PersonRow(
                        person: $person,
                        share: model.share(for: person),
                        currency: model.currency,
                        splitMode: model.splitMode,
                        deepLinkService: container.deepLinkService
                    )
                    .swipeActions {
                        Button(role: .destructive) {
                            withAnimation {
                                model.people.removeAll { $0.id == person.id }
                            }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }

                    if person.id != model.people.last?.id {
                        Divider().padding(.leading)
                    }
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyPeopleState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Add people to split with")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var saveButton: some View {
        Button {
            saveSplit()
        } label: {
            Label("Save split", systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .font(.headline)
        }
    }

    private var savedBanner: some View {
        Label("Split saved to history", systemImage: "checkmark.circle.fill")
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Actions

    private func saveSplit() {
        let record = SplitRecord(
            total: model.grandTotal,
            currencyCode: model.currency.code,
            tipPercent: model.tipPercent,
            date: .now
        )
        modelContext.insert(record)

        for person in model.people {
            let pr = PersonRecord(name: person.name, share: model.share(for: person))
            pr.split = record
            modelContext.insert(pr)
        }

        try? modelContext.save()
        container.haptics.success()

        withAnimation {
            savedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { savedConfirmation = false }
        }
    }
}

// MARK: - Tip chip

private struct TipChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}
