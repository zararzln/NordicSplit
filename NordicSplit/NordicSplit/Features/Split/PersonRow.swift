import SwiftUI

struct PersonRow: View {
    @Binding var person: Person
    let share: Decimal
    let currency: Currency
    let splitMode: SplitModel.SplitMode
    let deepLinkService: VippsDeepLinkService

    @State private var showPhoneEntry = false
    @State private var customShareString: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(initials)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(avatarColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.body)

                    if splitMode == .custom {
                        HStack(spacing: 4) {
                            Text(currency.symbol)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Amount", text: $customShareString)
                                .keyboardType(.decimalPad)
                                .font(.caption)
                                .frame(width: 70)
                                .onChange(of: customShareString) { _, new in
                                    person.customShare = Decimal(string: new.replacingOccurrences(of: ",", with: "."))
                                }
                        }
                    } else {
                        Text(currency.formatted(share))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if splitMode == .even {
                        Text(currency.formatted(share))
                            .font(.headline)
                            .monospacedDigit()
                    }

                    payButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
        .background(person.paid ? Color.green.opacity(0.05) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: person.paid)
    }

    // MARK: - Pay button

    private var payButton: some View {
        Group {
            if person.paid {
                Label("Paid", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .labelStyle(.iconOnly)
                    .font(.title2)
            } else if person.phoneNumber.isEmpty {
                Button {
                    showPhoneEntry = true
                } label: {
                    payLabel
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showPhoneEntry) {
                    phoneEntryPopover
                }
            } else {
                Button {
                    openPayment()
                } label: {
                    payLabel
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var payLabel: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.circle.fill")
            Text(deepLinkService.appName)
        }
        .font(.caption.bold())
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(deepLinkService.brandColor.opacity(0.12))
        .foregroundStyle(deepLinkService.brandColor)
        .clipShape(Capsule())
    }

    private var phoneEntryPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter \(person.name)'s number")
                .font(.headline)
            TextField("Phone number", text: $person.phoneNumber)
                .keyboardType(.phonePad)
                .textFieldStyle(.roundedBorder)
            Button("Request payment") {
                showPhoneEntry = false
                openPayment()
            }
            .buttonStyle(.borderedProminent)
            .disabled(person.phoneNumber.isEmpty)
        }
        .padding()
        .frame(minWidth: 260)
    }

    // MARK: - Actions

    private func openPayment() {
        guard let url = deepLinkService.paymentURL(
            amount: share,
            recipient: person.phoneNumber,
            message: "NordicSplit"
        ) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { person.paid = true }
            }
        }
    }

    // MARK: - Helpers

    private var initials: String {
        person.name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo]
        let index = abs(person.name.hashValue) % colors.count
        return colors[index]
    }
}
