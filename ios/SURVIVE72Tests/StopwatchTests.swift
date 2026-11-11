import XCTest
@testable import SURVIVE72

/// Stopwatch behaviour and time formatting, with a fixed clock.
final class StopwatchTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    // MARK: Stopwatch

    func testNewStopwatchIsStoppedAtZero() {
        let stopwatch = Stopwatch()
        XCTAssertFalse(stopwatch.isRunning)
        XCTAssertEqual(stopwatch.elapsed(at: at(100)), 0)
    }

    func testStartCountsElapsedTime() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        XCTAssertTrue(stopwatch.isRunning)
        XCTAssertEqual(stopwatch.elapsed(at: at(5)), 5, accuracy: 0.0001)
    }

    func testPauseFreezesTheTime() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        stopwatch.pause(at: at(10))
        XCTAssertFalse(stopwatch.isRunning)
        XCTAssertEqual(stopwatch.elapsed(at: at(500)), 10, accuracy: 0.0001)
    }

    func testResumeAddsToPreviousTime() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        stopwatch.pause(at: at(10))
        stopwatch.start(at: at(100))
        XCTAssertEqual(stopwatch.elapsed(at: at(103)), 13, accuracy: 0.0001)
        stopwatch.pause(at: at(105))
        XCTAssertEqual(stopwatch.elapsed(at: at(999)), 15, accuracy: 0.0001)
    }

    func testResetGoesBackToZeroAndStops() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        stopwatch.reset()
        XCTAssertFalse(stopwatch.isRunning)
        XCTAssertEqual(stopwatch.elapsed(at: at(50)), 0)
        XCTAssertEqual(stopwatch, Stopwatch())
    }

    func testStartWhileRunningDoesNotRestart() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        stopwatch.start(at: at(30))
        XCTAssertEqual(stopwatch.elapsed(at: at(40)), 40, accuracy: 0.0001)
    }

    func testPauseWhilePausedChangesNothing() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(0))
        stopwatch.pause(at: at(4))
        stopwatch.pause(at: at(20))
        XCTAssertEqual(stopwatch.elapsed(at: at(60)), 4, accuracy: 0.0001)
    }

    func testClockGoingBackwardsNeverGivesNegativeTime() {
        var stopwatch = Stopwatch()
        stopwatch.start(at: at(10))
        XCTAssertEqual(stopwatch.elapsed(at: at(5)), 0)
        stopwatch.pause(at: at(5))
        XCTAssertEqual(stopwatch.elapsed(at: at(5)), 0)
    }

    // MARK: Display format

    func testDisplayBelowOneHour() {
        XCTAssertEqual(ElapsedTimeFormat.display(0), "00:00.0")
        XCTAssertEqual(ElapsedTimeFormat.display(5.25), "00:05.2")
        XCTAssertEqual(ElapsedTimeFormat.display(65.5), "01:05.5")
        XCTAssertEqual(ElapsedTimeFormat.display(600), "10:00.0")
    }

    func testDisplayNeverRoundsUp() {
        XCTAssertEqual(ElapsedTimeFormat.display(59.99), "00:59.9")
        XCTAssertEqual(ElapsedTimeFormat.display(3599.99), "59:59.9")
    }

    func testDisplayFromOneHour() {
        XCTAssertEqual(ElapsedTimeFormat.display(3600), "1:00:00")
        XCTAssertEqual(ElapsedTimeFormat.display(3725), "1:02:05")
        XCTAssertEqual(ElapsedTimeFormat.display(36_000 + 59), "10:00:59")
    }

    func testDisplayOfInvalidValuesIsZero() {
        XCTAssertEqual(ElapsedTimeFormat.display(-3), "00:00.0")
        XCTAssertEqual(ElapsedTimeFormat.display(.nan), "00:00.0")
        XCTAssertEqual(ElapsedTimeFormat.display(.infinity), "00:00.0")
    }

    // MARK: Spoken format (VoiceOver)

    func testSpokenFormat() {
        XCTAssertEqual(ElapsedTimeFormat.spoken(0), "0 seconds")
        XCTAssertEqual(ElapsedTimeFormat.spoken(1), "1 second")
        XCTAssertEqual(ElapsedTimeFormat.spoken(65.5), "1 minute 5 seconds")
        XCTAssertEqual(ElapsedTimeFormat.spoken(120), "2 minutes")
        XCTAssertEqual(ElapsedTimeFormat.spoken(3725), "1 hour 2 minutes 5 seconds")
        XCTAssertEqual(ElapsedTimeFormat.spoken(7200), "2 hours")
    }
}
