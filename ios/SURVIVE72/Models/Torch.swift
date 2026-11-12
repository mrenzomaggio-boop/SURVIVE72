import AVFoundation
import Observation

/// The flash hardware, hidden behind a protocol so the logic can be tested
/// without an iPhone.
protocol TorchDevice {
    var hasTorch: Bool { get }
    var isTorchOn: Bool { get }
    func setTorch(on: Bool) throws
}

/// The iPhone flash used as a torch. It only switches the LED: no capture
/// session is created, so no camera permission is needed and no image is read.
struct SystemTorchDevice: TorchDevice {
    private var device: AVCaptureDevice? { AVCaptureDevice.default(for: .video) }

    var hasTorch: Bool { device?.hasTorch == true }

    var isTorchOn: Bool { device?.isTorchActive == true }

    func setTorch(on: Bool) throws {
        guard let device, device.hasTorch else { throw TorchError.unavailable }
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        guard device.isTorchModeSupported(on ? .on : .off) else { throw TorchError.unavailable }
        device.torchMode = on ? .on : .off
    }
}

enum TorchError: Error {
    case unavailable
}

/// Torch state shown by SURVIVE TOOLS. It never switches on by itself.
@Observable
final class Torch {
    private(set) var isOn = false
    /// True after a failed attempt, until the next successful one.
    private(set) var didFail = false

    private let device: TorchDevice

    init(device: TorchDevice = SystemTorchDevice()) {
        self.device = device
    }

    var isAvailable: Bool { device.hasTorch }

    func toggle() {
        set(on: !isOn)
    }

    func set(on: Bool) {
        guard device.hasTorch else {
            isOn = false
            didFail = on
            return
        }
        do {
            try device.setTorch(on: on)
            isOn = on
            didFail = false
        } catch {
            isOn = device.isTorchOn
            didFail = true
        }
    }

    /// iOS switches the flash off when the app leaves the foreground:
    /// call this when the app becomes active again to show the real state.
    func refresh() {
        isOn = device.hasTorch && device.isTorchOn
    }
}
