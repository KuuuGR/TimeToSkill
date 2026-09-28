import XCTest
@testable import TimeToSkill

final class AppLaunchTests: XCTestCase {

    private let suiteName = "AppLaunchTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    // MARK: - Counter

    func testFirstIncrementCountsAsOne() {
        XCTAssertEqual(AppLaunch.incrementCount(defaults: defaults), 1)
        XCTAssertEqual(AppLaunch.currentCount(defaults: defaults), 1)
    }

    func testCounterKeepsIncrementing() {
        AppLaunch.incrementCount(defaults: defaults)
        AppLaunch.incrementCount(defaults: defaults)
        XCTAssertEqual(AppLaunch.incrementCount(defaults: defaults), 3)
    }

    func testRecordLaunchDoesNotDoubleCountWithinProcess() {
        // The process-level guard makes the second call a plain read.
        let first = AppLaunch.recordLaunch(defaults: defaults)
        let second = AppLaunch.recordLaunch(defaults: defaults)
        XCTAssertEqual(first, second)
    }

    // MARK: - Splash policy

    func testSplashShowsOnDesignatedLaunches() {
        XCTAssertTrue(AppLaunch.shouldShowSplash(onLaunch: 1))
        XCTAssertTrue(AppLaunch.shouldShowSplash(onLaunch: 32))
        XCTAssertTrue(AppLaunch.shouldShowSplash(onLaunch: 64))
        XCTAssertTrue(AppLaunch.shouldShowSplash(onLaunch: 128))
    }

    func testSplashHiddenOnOtherLaunches() {
        for launch in [0, 2, 15, 16, 31, 33, 100, 127, 129, 256] {
            XCTAssertFalse(
                AppLaunch.shouldShowSplash(onLaunch: launch),
                "splash must not show on launch \(launch)"
            )
        }
    }

    // MARK: - Review policy

    func testReviewRequestedOnDesignatedLaunches() {
        XCTAssertTrue(AppLaunch.shouldRequestReview(onLaunch: 16))
        XCTAssertTrue(AppLaunch.shouldRequestReview(onLaunch: 256))
    }

    func testReviewSkippedOnOtherLaunches() {
        for launch in [1, 15, 17, 32, 128, 255, 257] {
            XCTAssertFalse(
                AppLaunch.shouldRequestReview(onLaunch: launch),
                "review must not be requested on launch \(launch)"
            )
        }
    }

    func testSplashAndReviewLaunchesDoNotOverlap() {
        XCTAssertTrue(AppLaunch.splashLaunches.isDisjoint(with: AppLaunch.reviewLaunches))
    }
}
