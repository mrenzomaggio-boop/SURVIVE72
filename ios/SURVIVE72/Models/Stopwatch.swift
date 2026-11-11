import Foundation

/// Stopwatch based on timestamps, not on a ticking counter: the elapsed time
/// stays correct even if the screen is closed or the app is in the background.
/// Every method takes `now` so tests can use a fixed clock.
struct Stopwatch: Equatable {
    /// Time collected by earlier start/pause cycles.
    private(set) var accumulated: TimeInterval = 0
    /// Set while running.
    private(set) var startedAt: Date?

    var isRunning: Bool { startedAt != nil }

    func elapsed(at now: Date) -> TimeInterval {
        guard let startedAt else { return accumulated }
        // Never count backwards if the clock moved back.
        return accumulated + max(0, now.timeIntervalSince(startedAt))
    }

    /// Starts or resumes. Ignored while already running.
    mutating func start(at now: Date) {
        guard startedAt == nil else { return }
        startedAt = now
    }

    /// Pauses and keeps the elapsed time. Ignored while paused.
    mutating func pause(at now: Date) {
        guard let startedAt else { return }
        accumulated += max(0, now.timeIntervalSince(startedAt))
        self.startedAt = nil
    }

    /// Back to zero and stopped.
    mutating func reset() {
        accumulated = 0
        startedAt = nil
    }
}

/// Readable text for elapsed times.
enum ElapsedTimeFormat {
    /// "MM:SS.t" below one hour (e.g. "01:05.9"), "H:MM:SS" from one hour
    /// (e.g. "1:02:05"). Tenths are truncated, never rounded up.
    static func display(_ interval: TimeInterval) -> String {
        let tenthsTotal = Int((sanitized(interval) * 10).rounded(.down))
        let totalSeconds = tenthsTotal / 10
        let tenths = tenthsTotal % 10
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours):" + twoDigits(minutes) + ":" + twoDigits(seconds)
        }
        return twoDigits(minutes) + ":" + twoDigits(seconds) + ".\(tenths)"
    }

    /// Words for VoiceOver, e.g. "1 hour 2 minutes 5 seconds".
    static func spoken(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(sanitized(interval).rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []
        if hours > 0 { parts.append(unit(hours, "hour")) }
        if minutes > 0 { parts.append(unit(minutes, "minute")) }
        if seconds > 0 || parts.isEmpty { parts.append(unit(seconds, "second")) }
        return parts.joined(separator: " ")
    }

    private static func sanitized(_ interval: TimeInterval) -> TimeInterval {
        interval.isFinite && interval > 0 ? interval : 0
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }

    private static func unit(_ value: Int, _ name: String) -> String {
        "\(value) \(name)\(value == 1 ? "" : "s")"
    }
}
