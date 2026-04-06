# NordicSplit

Expense splitting for Vipps and MobilePay users, built with Swift 6, SwiftUI and Observation.

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![iOS](https://img.shields.io/badge/iOS-17%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)

---

## What it does

You're at dinner. Someone pays. NordicSplit splits the bill and opens Vipps or MobilePay
for each person with the exact amount pre-filled. No account needed, no backend and no tracking.

- Photograph the receipt and Vision reads the total automatically
- Split evenly or set custom shares per person
- Tap a name to launch their Vipps or MobilePay payment directly
- Full history stored locally with SwiftData

---

## Why I built this

Vipps MobilePay already handles the payment. The problem is the 30 seconds before it:
figuring out who owes what. This app solves that one specific thing really well.

It also gave me a reason to dig into the official Vipps deeplink API, which turned out
to be a natural fit for a zero-backend mobile app.

---

## Tech

| | |
|---|---|
| Language | Swift 6 with strict concurrency |
| UI | SwiftUI + `@Observable` |
| Persistence | SwiftData |
| Receipt scanning | VisionKit + Vision text recognition |
| Payments | Vipps MobilePay deeplink API |
| Dependencies | None |

---

## Architecture

```
NordicSplit/
├── App/
│   ├── NordicSplitApp.swift        # @main entry point
│   ├── AppContainer.swift          # @Observable root state and services
│   └── ContentView.swift           # Tab root
├── Features/
│   ├── Split/
│   │   ├── SplitView.swift         # Main split screen
│   │   ├── SplitModel.swift        # @Observable split logic and totals
│   │   └── PersonRow.swift         # Per-person row with Vipps pay button
│   ├── Receipt/
│   │   ├── ReceiptScanView.swift   # PhotosPicker + camera UI
│   │   └── ReceiptParser.swift     # Vision OCR pipeline (actor)
│   └── History/
│       ├── HistoryView.swift       # SwiftData query list and detail
│       └── SplitRecord.swift       # SwiftData model definitions
├── Services/
│   ├── VippsDeepLinkService.swift  # Builds vipps:// and mobilepay:// URLs
│   └── HapticsService.swift        # UIImpactFeedbackGenerator wrapper
└── Preview Content/
    └── PreviewData.swift           # Sample data for Xcode canvas
```

---

## Deep link integration

`VippsDeepLinkService` constructs payment URLs per the [official Vipps MobilePay deeplink spec](https://developer.vippsmobilepay.com/docs/APIs/vipps-deeplink-api/).
The service auto-detects the device locale to pick Vipps (Norway) or MobilePay (Denmark).

Amounts are converted to the smallest unit (øre) before being passed to the URL — so
349.50 NOK becomes `34950` in the query string, which is what the API expects.

```swift
// Norway
vipps://payment?amount=34950&recipient=98765432&message=NordicSplit

// Denmark
mobilepay://send?amount=34950&to=12345678&comment=NordicSplit
```

---

## Receipt parsing

`ReceiptParser` is a Swift `actor` that runs a VNRecognizeTextRequest over the image, then
scores each recognised line by:

1. Confidence score from Vision
2. Proximity to keywords like "total", "sum" and "å betale"
3. Vertical position on the receipt (totals appear near the bottom)
4. Value magnitude (totals tend to be the largest number)

The highest-scoring candidate is returned as a decimal string and populated directly into
`SplitModel.totalString`.

---

## Running it

Xcode 16+ and an iOS 17 device or simulator. No API keys or config needed.

```bash
git clone https://github.com/yourusername/NordicSplit
open NordicSplit.xcodeproj
```

To test the Vipps deep link, run on a physical device with Vipps installed.
The simulator will show a "can't open URL" alert, which is expected.

---

## What's next

- [ ] QR code others can scan to claim their share
- [ ] Running group tabs across multiple outings
- [ ] Vipps Login (OAuth) for contact lookup instead of manual phone entry
- [ ] Home screen widget for quick splitting

---

## License

MIT. Not affiliated with Vipps MobilePay AS.
