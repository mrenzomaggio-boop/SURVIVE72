import Foundation

/// Morse "SOS" (... --- ...) as a slow on/off light pattern for the screen.
///
/// Safety: one time unit is 0.5 s, so the screen changes at most once per
/// half second (no more than 1 flash per second, well under the 3 flashes per
/// second photosensitivity limit). It never starts by itself.
enum SOSPattern {
    /// Length of one Morse unit, in seconds.
    static let unit: TimeInterval = 0.5

    struct Slot: Equatable {
        let isOn: Bool
        /// The letter being signalled, nil during the pause between repetitions.
        let letter: Character?
    }

    /// One full cycle, one slot per unit:
    /// dot = 1 on, dash = 3 on, 1 off between marks, 3 off between letters,
    /// 7 off before the pattern repeats.
    static let slots: [Slot] = {
        var result: [Slot] = []
        func on(_ units: Int, _ letter: Character) {
            result += Array(repeating: Slot(isOn: true, letter: letter), count: units)
        }
        func off(_ units: Int, _ letter: Character?) {
            result += Array(repeating: Slot(isOn: false, letter: letter), count: units)
        }
        let letters: [(Character, [Int])] = [("S", [1, 1, 1]), ("O", [3, 3, 3]), ("S", [1, 1, 1])]
        for (letterIndex, (letter, marks)) in letters.enumerated() {
            for (markIndex, length) in marks.enumerated() {
                on(length, letter)
                if markIndex < marks.count - 1 { off(1, letter) }
            }
            if letterIndex < letters.count - 1 { off(3, letter) }
        }
        off(7, nil)
        return result
    }()

    static var cycleDuration: TimeInterval { Double(slots.count) * unit }

    static func slot(atElapsed elapsed: TimeInterval) -> Slot {
        guard elapsed.isFinite, elapsed >= 0 else { return slots[0] }
        let index = Int((elapsed / unit).rounded(.down)) % slots.count
        return slots[index]
    }
}

/// Start/stop state of the on-screen SOS signal. Time is passed in for testing.
struct SOSSignal: Equatable {
    private(set) var startedAt: Date?

    var isActive: Bool { startedAt != nil }

    /// Starts the pattern from the beginning. Ignored while already active.
    mutating func start(at now: Date) {
        guard startedAt == nil else { return }
        startedAt = now
    }

    mutating func stop() {
        startedAt = nil
    }

    /// Whether the screen should be lit at `now`. Always false when stopped.
    func isLightOn(at now: Date) -> Bool {
        guard let startedAt else { return false }
        return SOSPattern.slot(atElapsed: now.timeIntervalSince(startedAt)).isOn
    }

    /// Letter currently being signalled, nil when stopped or between repetitions.
    func currentLetter(at now: Date) -> Character? {
        guard let startedAt else { return nil }
        return SOSPattern.slot(atElapsed: now.timeIntervalSince(startedAt)).letter
    }
}
