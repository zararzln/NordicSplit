import Vision
import UIKit

/// Uses the Vision text-recognition pipeline to extract a total amount from a receipt image.
///
/// Strategy:
/// 1. Run a full-page OCR pass with VNRecognizeTextRequest.
/// 2. Score each recognised string — lines that look like amounts and appear
///    near keywords ("total", "sum", "å betale") rank highest.
/// 3. Return the best candidate, or nil if nothing plausible is found.
///
actor ReceiptParser {

    // MARK: - Public

    /// Extracts the most likely total from `image`.
    /// Returns a string like "149.50" suitable for populating `SplitModel.totalString`.
    func extractTotal(from image: UIImage) async throws -> String? {
        guard let cgImage = image.cgImage else { return nil }

        let candidates = try await recognizeText(in: cgImage)
        return bestAmount(from: candidates)
    }

    // MARK: - OCR

    private func recognizeText(in image: CGImage) async throws -> [RecognizedLine] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { obs -> RecognizedLine? in
                    guard let candidate = obs.topCandidates(1).first else { return nil }
                    return RecognizedLine(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: obs.boundingBox
                    )
                }
                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["nb-NO", "da-DK", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Amount extraction

    private func bestAmount(from lines: [RecognizedLine]) -> String? {
        // Keywords that typically appear next to the total on Nordic receipts
        let totalKeywords = ["total", "sum", "å betale", "at betale", "grand total",
                             "totalt", "beløp", "betalas", "subtotal"]

        var scored: [(amount: String, score: Double)] = []

        for (idx, line) in lines.enumerated() {
            guard let amount = extractAmount(from: line.text) else { continue }

            var score = Double(line.confidence)

            // Boost if this line or an adjacent line contains a total keyword
            let context = contextLines(around: idx, in: lines)
            let joined = context.map(\.text.lowercased).joined(separator: " ")
            if totalKeywords.contains(where: { joined.contains($0) }) {
                score += 1.5
            }

            // Prefer amounts in the lower portion of the receipt (totals appear at bottom)
            let positionBoost = (1.0 - line.boundingBox.midY) * 0.5
            score += positionBoost

            // Prefer larger values (totals are usually the biggest number)
            if let value = Decimal(string: amount), value > 10 {
                score += 0.3
            }

            scored.append((amount: amount, score: score))
        }

        return scored.sorted { $0.score > $1.score }.first?.amount
    }

    /// Extracts a decimal amount string from raw OCR text.
    /// Handles "149,50", "149.50", "NOK 149.50", "kr 149,50" etc.
    private func extractAmount(from text: String) -> String? {
        // Strip currency symbols and codes
        let cleaned = text
            .replacingOccurrences(of: "NOK", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "DKK", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "kr", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ",-", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Match patterns like 1 234,50 or 1234.50 or 149
        let pattern = #"(\d{1,3}(?:[\s]\d{3})*(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
              let range = Range(match.range, in: cleaned) else {
            return nil
        }

        return String(cleaned[range])
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
    }

    private func contextLines(around index: Int, in lines: [RecognizedLine]) -> [RecognizedLine] {
        let start = max(0, index - 1)
        let end = min(lines.count - 1, index + 1)
        return Array(lines[start...end])
    }

    // MARK: - Types

    private struct RecognizedLine {
        let text: String
        let confidence: Float
        let boundingBox: CGRect
    }
}
