import XCTest
@testable import SURVIVE72

/// On-screen SOS pattern and start/stop state.
final class SOSSignalTests: XCTestCase {
    private let t0 = Date(timeIntervalSinceReferenceDate: 2_000_000)
    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    // MARK: Pattern

    func testPatternIsMorseSOS() {
        // 1 = light on for one unit, 0 = off for one unit.
        let expected =
            "10101" + "000" +            // S  ...
            "11101110111" + "000" +      // O  ---
            "10101" +                    // S  ...
            "0000000"                    // pause before repeating
        let actual = SOSPattern.slots.map { $0.isOn ? "1" : "0" }.joined()
        XCTAssertEqual(actual, expected)
        XCTAssertEqual(SOSPattern.slots.count, 34)
        XCTAssertEqual(SOSPattern.cycleDuration, 17, accuracy: 0.0001)
    }

    func testLettersFollowThePattern() {
        let letters = SOSPattern.slots.map { $0.letter.map { String($0) } ?? "-" }.joined()
        XCTAssertEqual(letters, String(repeating: "S", count: 8) + String(repeating: "O", count: 14)
                       + String(repeating: "S", count: 5) + String(repeating: "-", count: 7))
    }

    func testPatternIsSlowEnoughForPhotosensitivity() {
        // Each light change lasts at least one unit (0.5 s), so there is at most
        // one flash per second: far below the 3 flashes per second limit.
        XCTAssertGreaterThanOrEqual(SOSPattern.unit, 0.5)
        let flashesPerCycle = zip(SOSPattern.slots, SOSPattern.slots.dropFirst() + [SOSPattern.slots[0]])
            .filter { !$0.0.isOn && $0.1.isOn }.count
        XCTAssertEqual(flashesPerCycle, 9)
        XCTAssertLessThanOrEqual(1.0 / (2 * SOSPattern.unit), 3)
    }

    func testSlotAtTime() {
        XCTAssertTrue(SOSPattern.slot(atElapsed: 0).isOn)      // first dot
        XCTAssertFalse(SOSPattern.slot(atElapsed: 0.5).isOn)   // gap
        XCTAssertTrue(SOSPattern.slot(atElapsed: 1.0).isOn)    // second dot
        XCTAssertFalse(SOSPattern.slot(atElapsed: 3.0).isOn)   // gap between letters
        XCTAssertTrue(SOSPattern.slot(atElapsed: 4.0).isOn)    // start of first dash
        XCTAssertTrue(SOSPattern.slot(atElapsed: 5.4).isOn)    // still the first dash
        XCTAssertFalse(SOSPattern.slot(atElapsed: 14.0).isOn)  // final pause
    }

    func testPatternRepeats() {
        for second in stride(from: 0.0, to: 17.0, by: 0.5) {
            XCTAssertEqual(SOSPattern.slot(atElapsed: second),
                           SOSPattern.slot(atElapsed: second + 17),
                           "at \(second)s")
        }
    }

    // MARK: Signal state

    func testStoppedSignalIsDark() {
        let signal = SOSSignal()
        XCTAssertFalse(signal.isActive)
        XCTAssertFalse(signal.isLightOn(at: at(0)))
        XCTAssertNil(signal.currentLetter(at: at(0)))
    }

    func testStartedSignalFollowsPattern() {
        var signal = SOSSignal()
        signal.start(at: at(0))
        XCTAssertTrue(signal.isActive)
        XCTAssertTrue(signal.isLightOn(at: at(0)))
        XCTAssertFalse(signal.isLightOn(at: at(0.5)))
        XCTAssertEqual(signal.currentLetter(at: at(0)), "S")
        XCTAssertEqual(signal.currentLetter(at: at(5)), "O")
        XCTAssertNil(signal.currentLetter(at: at(15)))
    }

    func testStopTurnsTheLightOff() {
        var signal = SOSSignal()
        signal.start(at: at(0))
        signal.stop()
        XCTAssertFalse(signal.isActive)
        XCTAssertFalse(signal.isLightOn(at: at(0)))
    }

    func testStartWhileActiveDoesNotRestartThePattern() {
        var signal = SOSSignal()
        signal.start(at: at(0))
        signal.start(at: at(0.5))
        // Still timed from the first start: 0.5 s is a gap, not a new first dot.
        XCTAssertFalse(signal.isLightOn(at: at(0.5)))
    }

    func testRestartAfterStopBeginsFromTheFirstDot() {
        var signal = SOSSignal()
        signal.start(at: at(0))
        signal.stop()
        signal.start(at: at(100.5))
        XCTAssertTrue(signal.isLightOn(at: at(100.5)))
    }

    func testTimeBeforeStartIsTreatedAsTheBeginning() {
        var signal = SOSSignal()
        signal.start(at: at(10))
        XCTAssertTrue(signal.isLightOn(at: at(9)))
    }
}
