# Stock Price Tracker App Case Study

![CI-iOS](https://github.com/afsalkp007/StockPriceTracker/actions/workflows/CI-iOS.yml/badge.svg)
![CI-macOS](https://github.com/afsalkp007/StockPriceTracker/actions/workflows/CI-macOS.yml/badge.svg)

This project is a Clean Architecture case study for a real-time stock tracker built with three modules:

- `StockPriceTracker`: feature, presentation, shared presentation, and websocket API
- `StockPriceTrackeriOS`: SwiftUI rendering layer
- `StockPriceTrackerApp`: composition root, app services, and navigation

The app tracks 25 seeded stocks, streams live price updates through a websocket echo server, supports list sorting and detail navigation, and handles connection loss with retry flows on both screens.


> Editable source remains available in `docs/diagram.drawio` and exported PNGs in `docs/stock-flow.png` / `docs/stock-architecture.png`.

## Model Specs

### Stock

| Property | Type | Description |
| --- | --- | --- |
| `symbol` | `String` | Unique stock ticker used as the primary identity |
| `name` | `String` | Company display name |
| `description` | `String` | Company description shown on the detail screen |
| `price` | `Double` | Latest known stock price |
| `previousPrice` | `Double` | Previous stock price used to compute change |
| `history` | `[Double]` | Sliding window of recent prices for the sparkline |

### Payload contract

The app connects to:

```text
wss://ws.postman-echo.com/raw
```

The websocket feed uses JSON arrays of stock price updates:

```json
[
  {
    "symbol": "AAPL",
    "price": 182.50
  },
  {
    "symbol": "MSFT",
    "price": 405.12
  }
]
```

`Postman Echo` returns the same frame payload, which the app maps into `StockMessageMapper.StockPriceUpdate` values before merging into the current stock state.

## Module Breakdown

### `StockPriceTracker`

- Domain model for `Stock`
- Feed abstractions such as `StockFeedLoader` and `StockFeedController`
- Stock presentation layer with presenters, view models, sorting, and localization
- Shared presentation layer for loading and error presentation
- Websocket infrastructure boundary with `WebSocketStockFeedLoader`, `URLSessionWebSocketClient`, and `StockMessageMapper`

### `StockPriceTrackeriOS`

- SwiftUI screens for the stock list and detail flows
- UI-specific observable state stores
- Reusable rendering components such as connection, price change, and sparkline views

### `StockPriceTrackerApp`

- Composition root and navigation setup
- Shared `StockService`
- App-layer composers and adapters that bridge feature APIs into the SwiftUI state stores

## Build Instructions

### Requirements

- Xcode 16+ installed (default path: `/Applications/Xcode.app`)
- iOS Simulator runtimes installed
- macOS can reach `wss://ws.postman-echo.com/raw` for end-to-end websocket tests

### Quick Start (Xcode)

1. Open `StockPriceTrackerApp/StockPriceTrackerApp.xcworkspace`
2. Select scheme `StockPriceTrackerApp`
3. Select an iOS Simulator (for example, iPhone 17 Pro)
4. Run (`Cmd + R`)

### Run Tests (Xcode)

- iOS CI-equivalent suite: scheme `CI-iOS` (workspace: `StockPriceTrackerApp/StockPriceTrackerApp.xcworkspace`)
- macOS CI-equivalent suite: scheme `CI-macOS` (project: `StockPriceTracker/StockPriceTracker.xcodeproj`)
- WebSocket E2E suite: scheme `StockWebSocketAPIEndToEndTests` (project: `StockPriceTracker/StockPriceTracker.xcodeproj`)

### Build and Test from CLI

From repo root:

```bash
xcodebuild clean build test \
  -workspace StockPriceTrackerApp/StockPriceTrackerApp.xcworkspace \
  -scheme "CI-iOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest" \
  ONLY_ACTIVE_ARCH=YES
```

```bash
xcodebuild clean build test \
  -project StockPriceTracker/StockPriceTracker.xcodeproj \
  -scheme "CI-macOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  -sdk macosx \
  -destination "platform=macOS" \
  ONLY_ACTIVE_ARCH=YES
```

### Build App Only (without tests)

```bash
xcodebuild build \
  -workspace StockPriceTrackerApp/StockPriceTrackerApp.xcworkspace \
  -scheme "StockPriceTrackerApp" \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=latest"
```

### Run WebSocket End-to-End Tests Only

```bash
xcodebuild test \
  -project StockPriceTracker/StockPriceTracker.xcodeproj \
  -scheme "StockWebSocketAPIEndToEndTests" \
  -sdk macosx \
  -destination "platform=macOS"
```

## Testing Strategy

The test suite follows the same general direction as the Essential Feed case study:

- framework unit tests focus on public feature, presentation, shared presentation, localization, and websocket seams
- app integration tests exercise the composed list and detail flows through public composition interfaces
- websocket end-to-end coverage lives in a dedicated target and shared scheme so it does not get mixed into the regular unit suite

Current testing layers include:

- `StockPriceTrackerTests`
- `StockPriceTrackeriOSTests`
- `StockPriceTrackerAppTests`
- `StockWebSocketAPIEndToEndTests`
