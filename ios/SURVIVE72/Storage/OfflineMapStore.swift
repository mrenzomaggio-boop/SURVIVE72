import Foundation
import Observation

/// Where one downloadable area stands on this device.
enum MapDownloadState: Equatable {
    case notDownloaded
    /// 0...1
    case downloading(Double)
    case downloaded(bytes: Int64)
    case failed

    var isDownloaded: Bool {
        if case .downloaded = self { return true }
        return false
    }

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}

/// Offline maps: downloads area files once, keeps them in the app's Library
/// folder (not in iCloud backups) and lists what is on the device.
@MainActor
@Observable
final class OfflineMapStore {
    let regions: [MapRegion]
    let directory: URL
    private let baseURL: URL?

    private(set) var states: [String: MapDownloadState] = [:]
    private var tasks: [String: URLSessionDownloadTask] = [:]
    private var observations: [String: NSKeyValueObservation] = [:]

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OfflineMaps", isDirectory: true)
    }

    init(regions: [MapRegion] = MapRegionCatalog.load(),
         directory: URL = OfflineMapStore.defaultDirectory,
         baseURL: URL? = MapRegionCatalog.downloadBaseURL) {
        self.regions = regions
        self.directory = directory
        self.baseURL = baseURL
        refresh()
    }

    /// True when the map files are published and can be downloaded.
    var canDownload: Bool { baseURL != nil }

    func state(of region: MapRegion) -> MapDownloadState {
        states[region.id] ?? .notDownloaded
    }

    func fileURL(for region: MapRegion) -> URL {
        directory.appendingPathComponent(region.fileName)
    }

    var downloadedRegions: [MapRegion] {
        regions.filter { state(of: $0).isDownloaded }
    }

    var usedBytes: Int64 {
        states.values.reduce(0) { total, state in
            if case .downloaded(let bytes) = state { return total + bytes }
            return total
        }
    }

    /// Reads the folder again: files on disk are the truth.
    func refresh() {
        for region in regions where !state(of: region).isDownloading {
            let size = (try? fileURL(for: region).resourceValues(forKeys: [.fileSizeKey]))?.fileSize
            states[region.id] = size.map { .downloaded(bytes: Int64($0)) } ?? .notDownloaded
        }
    }

    func download(_ region: MapRegion) {
        guard tasks[region.id] == nil,
              let url = MapRegionCatalog.downloadURL(for: region, base: baseURL) else { return }
        prepareDirectory()

        let id = region.id
        let destination = fileURL(for: region)
        let task = URLSession.shared.downloadTask(with: url) { [weak self] location, response, error in
            // The temporary file is deleted when this closure returns: move it now.
            var bytes: Int64?
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error == nil, (200..<300).contains(status), let location {
                bytes = OfflineMapStore.moveDownloadedFile(from: location, to: destination)
            }
            Task { @MainActor [weak self] in
                self?.finish(id: id, bytes: bytes)
            }
        }
        observations[id] = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            let fraction = progress.fractionCompleted
            Task { @MainActor [weak self] in
                self?.updateProgress(id: id, fraction: fraction)
            }
        }
        tasks[id] = task
        states[id] = .downloading(0)
        task.resume()
    }

    func cancel(_ region: MapRegion) {
        guard let task = tasks[region.id] else { return }
        states[region.id] = .notDownloaded
        task.cancel()
    }

    func delete(_ region: MapRegion) {
        cancel(region)
        try? FileManager.default.removeItem(at: fileURL(for: region))
        states[region.id] = .notDownloaded
    }

    // MARK: Private

    private func updateProgress(id: String, fraction: Double) {
        guard case .downloading(let current) = states[id] else { return }
        // Fewer screen refreshes: only whole percent steps.
        if (fraction * 100).rounded(.down) > (current * 100).rounded(.down) {
            states[id] = .downloading(min(fraction, 1))
        }
    }

    private func finish(id: String, bytes: Int64?) {
        let wasCancelled = states[id] == .notDownloaded
        tasks[id] = nil
        observations[id] = nil
        if let bytes {
            states[id] = .downloaded(bytes: bytes)
            return
        }
        // A failed or cancelled download keeps any older file of the same area.
        states[id] = .notDownloaded
        refresh()
        if !wasCancelled, states[id] == .notDownloaded {
            states[id] = .failed
        }
    }

    private func prepareDirectory() {
        var dir = directory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Maps can be downloaded again: keep them out of iCloud backups.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
    }

    /// Replaces the destination with the downloaded file. Returns its size,
    /// or nil if the move failed (the old file, if any, is kept).
    nonisolated static func moveDownloadedFile(from location: URL, to destination: URL) -> Int64? {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: destination.path) {
                _ = try fm.replaceItemAt(destination, withItemAt: location)
            } else {
                try fm.moveItem(at: location, to: destination)
            }
        } catch {
            return nil
        }
        let size = (try? destination.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
        return size.map(Int64.init)
    }
}
