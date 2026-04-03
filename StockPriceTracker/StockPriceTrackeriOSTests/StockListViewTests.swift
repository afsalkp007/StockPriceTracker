import UIKit
import SwiftUI
import XCTest
import StockPriceTrackeriOS

@MainActor
final class StockListViewTests: XCTestCase {

    func test_onFirstAppearance_startsFeed() {
        let (sut, callbacks) = makeSUT()

        sut.simulateAppearance()

        XCTAssertEqual(callbacks.startCallCount, 1)
        XCTAssertEqual(callbacks.stopCallCount, 0)
    }

    func test_onRepeatedAppearance_startsFeedOnlyOnce() {
        let (sut, callbacks) = makeSUT()

        sut.simulateAppearance()
        sut.simulateDisappearance()
        sut.simulateAppearance()

        XCTAssertEqual(callbacks.startCallCount, 1)
    }

    private func makeSUT() -> (sut: ViewHost, callbacks: CallbackSpy) {
        let callbacks = CallbackSpy()
        let controller = UIHostingController(
            rootView: StockListView(
                stateStore: StockListStateStore(),
                onStart: callbacks.start,
                onStop: callbacks.stop,
                onSort: { _ in },
                onRowSelected: { _ in }
            )
        )

        let sut = ViewHost(controller: controller)

        return (sut, callbacks)
    }

    private final class CallbackSpy {
        private(set) var startCallCount = 0
        private(set) var stopCallCount = 0

        func start() {
            startCallCount += 1
        }

        func stop() {
            stopCallCount += 1
        }
    }
}

private final class ViewHost {
    private let window = UIWindow(frame: UIScreen.main.bounds)
    private let controller: UIHostingController<StockListView>

    init(controller: UIHostingController<StockListView>) {
        self.controller = controller
        controller.loadViewIfNeeded()
        window.rootViewController = controller
    }

    func simulateAppearance() {
        window.makeKeyAndVisible()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date())
    }

    func simulateDisappearance() {
        controller.beginAppearanceTransition(false, animated: false)
        controller.endAppearanceTransition()
        window.isHidden = true
        RunLoop.current.run(until: Date())
    }
}
