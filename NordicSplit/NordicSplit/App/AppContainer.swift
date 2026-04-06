import SwiftUI
import Observation

/// Root application state. Injected into the environment at the top level
/// so any view can reach shared services without passing them manually.
@Observable
final class AppContainer {

    // MARK: - Shared services
    let deepLinkService: VippsDeepLinkService
    let haptics: HapticsService

    // MARK: - Navigation state
    var selectedTab: Tab = .split
    var presentingHistory: Bool = false

    init() {
        // Detect locale to pick Vipps (Norway) vs MobilePay (Denmark)
        let locale: VippsLocale = Locale.current.region?.identifier == "DK" ? .denmark : .norway
        self.deepLinkService = VippsDeepLinkService(locale: locale)
        self.haptics = HapticsService()
    }

    enum Tab: Hashable {
        case split, history
    }
}
