# NordicSplit

Expense splitting for Vipps and MobilePay users — built with Swift 6, SwiftUI and Observation.

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## What it does

You're at dinner. Someone pays. NordicSplit splits the bill and opens Vipps or MobilePay
for each person with the exact amount pre-filled. No account needed, no backend, no tracking.

- Photograph the receipt and Vision reads the total automatically
- Split evenly or set custom shares per person
- Tap a name to launch their Vipps/MobilePay payment directly
- Full history stored locally with SwiftData

## Why I built this

Vipps MobilePay already handles the payment. The problem is the 30 seconds before it —
figuring out who owes what. This app solves that one specific thing really well.

It also gave me a reason to dig into the official Vipps deeplink API, which turned out
to be a great fit for a zero-backend mobile app.

## Tech

- **Swift 6** with strict concurrency
- **SwiftUI** + `@Observable` (no third-party state management)
- **SwiftData** for local persistence
- **VisionKit** for receipt scanning
- **Vipps MobilePay deeplink API** for payment handoff
- Zero external dependencies

## Project structure

NordicSplit/
├── App/
│   └── AppContainer.swift          # @Observable root state
├── Features/
│   ├── Split/                      # main split screen
│   ├── Receipt/                    # camera + Vision parsing
│   └── History/                    # SwiftData records
├── Services/
│   └── VippsDeepLinkService.swift  # builds vipps:// and mobilepay:// URLs
└── Components/                     # reusable UI

## Running it

Xcode 16+ and an iOS 17 device or simulator. No API keys or config needed.

git clone https://github.com/yourusername/NordicSplit
open NordicSplit.xcodeproj

## What's next

- QR code others can scan to claim their share
- Running group tabs across multiple outings
- Vipps Login (OAuth) for contact lookup
- Home screen widget for quick splitting

## License

MIT. Not affiliated with Vipps MobilePay AS.
