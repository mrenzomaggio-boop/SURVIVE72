import XCTest
@testable import SURVIVE72

final class OfflineMapTests: XCTestCase {

    // MARK: Catalog

    func testBundledCatalogLoadsAllRegions() {
        let regions = MapRegionCatalog.load()
        XCTAssertEqual(regions.count, 31)
        XCTAssertEqual(regions.filter { !$0.isCountry }.count, 20, "All 20 Italian regions")
        XCTAssertTrue(regions.contains { $0.iso == "IT" })
        XCTAssertEqual(Set(regions.map(\.id)).count, regions.count, "Ids must be unique")
    }

    func testRegionsAreValidAndCountriesFitFileLimit() {
        for region in MapRegionCatalog.load() {
            XCTAssertTrue(region.isValid, region.id)
            XCTAssertFalse(region.title.isEmpty, region.id)
            XCTAssertEqual(region.fileName, "\(region.id).pmtiles")
            XCTAssertTrue((2...14).contains(region.fittingZoom), region.id)
            // GitHub release files are limited to 2 GB.
            XCTAssertLessThan(region.estimatedMB, 2000, region.id)
        }
    }

    func testInvalidRegionsAreDropped() {
        let json = """
        {"regions": [
          {"id": "ok", "name": "Ok", "bbox": [7, 44, 8, 45], "maxzoom": 15, "estimatedMB": 10},
          {"id": "swapped", "name": "Bad", "bbox": [8, 44, 7, 45], "maxzoom": 15, "estimatedMB": 10},
          {"id": "short", "name": "Bad", "bbox": [8, 44], "maxzoom": 15, "estimatedMB": 10}
        ]}
        """
        XCTAssertEqual(MapRegionCatalog.decode(Data(json.utf8)).map(\.id), ["ok"])
        XCTAssertTrue(MapRegionCatalog.decode(Data("not json".utf8)).isEmpty)
    }

    func testDownloadURLNeedsBase() throws {
        let region = try XCTUnwrap(MapRegionCatalog.load().first)
        XCTAssertNil(MapRegionCatalog.downloadURL(for: region, base: nil))
        let url = MapRegionCatalog.downloadURL(for: region, base: URL(string: "https://example.org/maps"))
        XCTAssertEqual(url?.absoluteString, "https://example.org/maps/\(region.id).pmtiles")
    }

    // MARK: Style

    func testStyleUsesBundledFontsAndOneSourcePerArea() throws {
        let resources = try XCTUnwrap(OfflineMapStyle.resourcesURL)
        for dark in [false, true] {
            let files = [(id: "a", file: URL(fileURLWithPath: "/tmp/a.pmtiles")),
                         (id: "b", file: URL(fileURLWithPath: "/tmp/b.pmtiles"))]
            let data = try OfflineMapStyle.build(regions: files, dark: dark, resources: resources)
            let style = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
            let sources = try XCTUnwrap(style["sources"] as? [String: [String: Any]])
            XCTAssertEqual(Set(sources.keys), ["area-a", "area-b"])
            XCTAssertEqual(sources["area-a"]?["url"] as? String, "pmtiles://file:///tmp/a.pmtiles")
            let glyphs = try XCTUnwrap(style["glyphs"] as? String)
            XCTAssertTrue(glyphs.hasPrefix("file://"))
            XCTAssertTrue(glyphs.hasSuffix("/fonts/{fontstack}/{range}.pbf"))
            let layers = try XCTUnwrap(style["layers"] as? [[String: Any]])
            XCTAssertEqual(layers.filter { $0["type"] as? String == "background" }.count, 1)
            let ids = layers.compactMap { $0["id"] as? String }
            XCTAssertEqual(Set(ids).count, ids.count, "Layer ids must be unique")
        }
    }

    func testBundledFontsExistForEveryFontInStyle() throws {
        let resources = try XCTUnwrap(OfflineMapStyle.resourcesURL)
        for name in ["NotoSansRegular", "NotoSansMedium", "NotoSansItalic", "NotoSansDevanagari"] {
            let first = resources.appendingPathComponent("fonts/\(name)/0-255.pbf")
            XCTAssertTrue(FileManager.default.fileExists(atPath: first.path), name)
        }
        for sprite in ["light.json", "light@2x.png", "dark.json", "dark@2x.png"] {
            XCTAssertTrue(FileManager.default.fileExists(atPath: resources.appendingPathComponent("sprites/\(sprite)").path))
        }
    }

    func testStyleWithoutAreasIsJustBackground() throws {
        let resources = try XCTUnwrap(OfflineMapStyle.resourcesURL)
        let data = try OfflineMapStyle.build(regions: [], dark: false, resources: resources)
        let style = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual((style["layers"] as? [Any])?.count, 1)
        XCTAssertEqual((style["sources"] as? [String: Any])?.count, 0)
    }

    // MARK: Store

    @MainActor
    func testStoreReadsFilesOnDisk() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let regions = Array(MapRegionCatalog.load().prefix(2))
        XCTAssertEqual(regions.count, 2)

        let store = OfflineMapStore(regions: regions, directory: dir, baseURL: nil)
        XCTAssertFalse(store.canDownload)
        XCTAssertTrue(store.downloadedRegions.isEmpty)
        XCTAssertEqual(store.usedBytes, 0)

        try Data(count: 1234).write(to: store.fileURL(for: regions[0]))
        store.refresh()
        XCTAssertEqual(store.downloadedRegions.map(\.id), [regions[0].id])
        XCTAssertEqual(store.state(of: regions[0]), .downloaded(bytes: 1234))
        XCTAssertEqual(store.state(of: regions[1]), .notDownloaded)
        XCTAssertEqual(store.usedBytes, 1234)

        // Without a base URL nothing starts.
        store.download(regions[1])
        XCTAssertEqual(store.state(of: regions[1]), .notDownloaded)

        store.delete(regions[0])
        XCTAssertTrue(store.downloadedRegions.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL(for: regions[0]).path))
    }

    func testMoveDownloadedFileReplacesOldFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let source = dir.appendingPathComponent("new.tmp")
        let destination = dir.appendingPathComponent("area.pmtiles")
        try Data(count: 10).write(to: destination)
        try Data(count: 42).write(to: source)
        XCTAssertEqual(OfflineMapStore.moveDownloadedFile(from: source, to: destination), 42)
        XCTAssertNil(OfflineMapStore.moveDownloadedFile(from: source, to: destination), "Source is gone")
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path), "A failed move keeps the old file")
    }
}
