import Foundation
import XCTest
import StockPriceTracker

@MainActor
final class StockWebSocketAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerEchoResult_matchesSentStockUpdates() async {
        let expectedUpdates = [
            ExpectedUpdate(symbol: "AAPL", price: 181.25),
            ExpectedUpdate(symbol: "MSFT", price: 412.10)
        ]

        switch await echoedUpdatesResult(for: [expectedUpdates]) {
        case let .success(receivedBatches)?:
            XCTAssertEqual(receivedBatches, [expectedUpdates])

        case let .failure(error)?:
            XCTFail("Expected successful echoed updates, got \(error) instead")

        default:
            XCTFail("Expected echoed updates, got no result instead")
        }
    }

    func test_endToEndTestServerEchoResults_preserveMessageOrderOnSameConnection() async {
        let firstExpectedUpdates = [
            ExpectedUpdate(symbol: "GOOG", price: 145.90)
        ]
        let secondExpectedUpdates = [
            ExpectedUpdate(symbol: "TSLA", price: 212.75),
            ExpectedUpdate(symbol: "NVDA", price: 903.40)
        ]

        switch await echoedUpdatesResult(for: [firstExpectedUpdates, secondExpectedUpdates]) {
        case let .success(receivedBatches)?:
            XCTAssertEqual(receivedBatches, [firstExpectedUpdates, secondExpectedUpdates])

        case let .failure(error)?:
            XCTFail("Expected successful echoed updates, got \(error) instead")

        default:
            XCTFail("Expected echoed updates, got no result instead")
        }
    }

    private func echoedUpdatesResult(
        for expectedBatches: [[ExpectedUpdate]],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Result<[[ExpectedUpdate]], Error>? {
        let client = ephemeralClient(file: file, line: line)

        do {
            try await client.connect()
            defer { client.disconnect() }

            let expectation = expectation(description: "Wait for echoed websocket messages")
            expectation.expectedFulfillmentCount = expectedBatches.count

            var receivedMessages = [Result<String, Error>]()
            let receiveTask = Task { @MainActor in
                for await result in client.receive() {
                    receivedMessages.append(result)
                    expectation.fulfill()

                    if receivedMessages.count == expectedBatches.count {
                        break
                    }
                }
            }

            for batch in expectedBatches {
                try await client.send(payload(for: batch))
            }

            await fulfillment(of: [expectation], timeout: 10.0)
            receiveTask.cancel()
            await receiveTask.value

            guard receivedMessages.count == expectedBatches.count else {
                return nil
            }

            return .success(try receivedMessages.map(map))
        } catch {
            return .failure(error)
        }
    }

    private func payload(for updates: [ExpectedUpdate]) throws -> String {
        let items = updates.map { update in
            ["symbol": update.symbol, "price": update.price] as [String : Any]
        }
        let data = try JSONSerialization.data(withJSONObject: items)
        return String(decoding: data, as: UTF8.self)
    }

    private func map(_ result: Result<String, Error>) throws -> [ExpectedUpdate] {
        switch result {
        case let .success(message):
            return try StockMessageMapper.map(message).map(ExpectedUpdate.init)

        case let .failure(error):
            throw error
        }
    }

    private func ephemeralClient(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionWebSocketClient {
        let client = URLSessionWebSocketClient(
            url: echoServerURL,
            session: URLSession(configuration: .ephemeral)
        )
        trackForMemoryLeaks(client, file: file, line: line)
        return client
    }

    private var echoServerURL: URL {
        URL(string: "wss://ws.postman-echo.com/raw")!
    }

    private struct ExpectedUpdate: Equatable {
        let symbol: String
        let price: Double

        init(symbol: String, price: Double) {
            self.symbol = symbol
            self.price = price
        }

        init(_ update: StockMessageMapper.StockPriceUpdate) {
            self.init(symbol: update.symbol, price: update.price)
        }
    }
}
