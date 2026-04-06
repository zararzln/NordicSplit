import SwiftUI

/// Which payment app to deep-link into.
enum VippsLocale {
    case norway   // vipps://
    case denmark  // mobilepay://
}

/// Constructs deep links that hand off directly to Vipps (Norway) or MobilePay (Denmark).
///
/// Spec reference: https://developer.vippsmobilepay.com/docs/APIs/vipps-deeplink-api/
///
/// Usage:
/// ```swift
/// let service = VippsDeepLinkService(locale: .norway)
/// if let url = service.paymentURL(amount: 149.50, recipient: "98765432", message: "Dinner") {
///     UIApplication.shared.open(url)
/// }
/// ```
struct VippsDeepLinkService {

    let locale: VippsLocale

    // MARK: - Public interface

    /// Human-readable name shown in the UI.
    var appName: String {
        locale == .norway ? "Vipps" : "MobilePay"
    }

    /// Brand color for buttons and accents.
    var brandColor: Color {
        locale == .norway ? Color(red: 1.0, green: 0.55, blue: 0.0) : Color(red: 0.25, green: 0.47, blue: 0.85)
    }

    /// Builds the deep-link URL for a payment request.
    ///
    /// - Parameters:
    ///   - amount: Amount in the local currency (NOK or DKK).
    ///   - recipient: Phone number of the receiver, digits only.
    ///   - message: Short payment description shown in the app.
    /// - Returns: A URL that opens the payment app, or nil if the URL could not be constructed.
    func paymentURL(amount: Decimal, recipient: String, message: String) -> URL? {
        switch locale {
        case .norway:
            return vippsURL(amount: amount, recipient: recipient, message: message)
        case .denmark:
            return mobilepayURL(amount: amount, recipient: recipient, message: message)
        }
    }

    /// Returns true when the relevant payment app is installed on the device.
    var isAppInstalled: Bool {
        guard let probe = URL(string: locale == .norway ? "vipps://" : "mobilepay://") else {
            return false
        }
        return UIApplication.shared.canOpenURL(probe)
    }

    // MARK: - Private URL builders

    /// vipps://payment?amount=&recipient=&message=
    private func vippsURL(amount: Decimal, recipient: String, message: String) -> URL? {
        var components = URLComponents()
        components.scheme = "vipps"
        components.host = "payment"
        components.queryItems = [
            URLQueryItem(name: "amount",    value: øreString(amount)),
            URLQueryItem(name: "recipient", value: sanitizedPhone(recipient)),
            URLQueryItem(name: "message",   value: message)
        ]
        return components.url
    }

    /// mobilepay://send?amount=&to=&comment=
    private func mobilepayURL(amount: Decimal, recipient: String, message: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mobilepay"
        components.host = "send"
        components.queryItems = [
            URLQueryItem(name: "amount",  value: øreString(amount)),
            URLQueryItem(name: "to",      value: sanitizedPhone(recipient)),
            URLQueryItem(name: "comment", value: message)
        ]
        return components.url
    }

    // MARK: - Formatting helpers

    /// Vipps and MobilePay both expect amounts in the smallest unit (øre/ører).
    /// 149.50 NOK → "14950"
    private func øreString(_ amount: Decimal) -> String {
        let øre = (amount * 100) as NSDecimalNumber
        return "\(øre.intValue)"
    }

    /// Strip spaces, dashes and country codes so the app receives clean digits.
    private func sanitizedPhone(_ raw: String) -> String {
        var digits = raw.filter(\.isNumber)
        // Remove leading country code (47 for NO, 45 for DK) if present
        if digits.count > 8 {
            digits = String(digits.suffix(8))
        }
        return digits
    }
}
