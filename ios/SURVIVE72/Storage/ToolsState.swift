import Foundation
import Observation

/// In-memory state of SURVIVE TOOLS, shared by the app so the stopwatch keeps
/// counting while you look at other screens. Nothing is saved or sent.
@Observable
final class ToolsState {
    var stopwatch = Stopwatch()
    var sosSignal = SOSSignal()
    let torch = Torch()
}
