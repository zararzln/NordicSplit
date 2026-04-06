import SwiftUI
import PhotosUI

struct ReceiptScanView: View {
    let onDetected: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let parser = ReceiptParser()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Preview area
                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(.blue, lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                } else {
                    placeholderBox
                }

                Spacer()

                // State feedback
                if isProcessing {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Reading receipt…")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Actions
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    Button("Enter amount manually") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Scan receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await load(item: item) }
            }
        }
    }

    // MARK: - Placeholder

    private var placeholderBox: some View {
        VStack(spacing: 16) {
            Image(systemName: "receipt")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Point your camera at the receipt total")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Processing

    @MainActor
    private func load(item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load image."
                isProcessing = false
                return
            }

            scannedImage = image

            if let amount = try await parser.extractTotal(from: image) {
                onDetected(amount)
                dismiss()
            } else {
                errorMessage = "No total found. Try a clearer photo or enter the amount manually."
            }
        } catch {
            errorMessage = "Something went wrong: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
