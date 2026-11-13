import XCTest
@testable import SURVIVE72

final class OfflineMapTests: XCTestCase {

    // MARK: Catalog

    func testBundledCatalogCoversTheWorld() {
        let regions = MapRegionCatalog.load()
        XCTAssertGreaterThan(regions.count, 500)
        XCTAssertEqual(Set(regions.map(\.id)).count, regions.count, "Ids must be unique")
        XCTAssertEqual(regions.filter { $0.parent == "IT" }.count, 20, "All 20 Italian regions")
        let countries = regions.filter(\.isCountry)
        XCTAssertGreaterThan(countries.count, 200)
        for code in ["IT", "FR", "US", "BR", "CN", "AU", "ZA", "JP", "TW"] {
            XCTAssertTrue(countries.contains { $0.iso == code }, code)
        }
        let codes = Set(countries.compactMap(\.iso))
        for region in regions {
            XCTAssertNotNil(region.mapContinent, region.id)
            if let iso = region.iso {
                XCTAssertTrue(iso.count == 2 && iso == iso.uppercased(), region.id)
            }
            if let parent = region.parent {
                XCTAssertTrue(codes.contains(parent), "\(region.id): parent country is listed")
                XCTAssertNotNil(region.name, region.id)
            }
        }
        for continent in MapContinent.allCases {
            XCTAssertFalse(MapRegionIndex.countries(in: continent, of: regions).isEmpty, continent.rawValue)
        }
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

    func testSearchFindsRegionsAndCountries() {
        let regions = MapRegionCatalog.load()
        XCTAssertEqual(MapRegionIndex.search("lombard", in: regions).map(\.id), ["it-lombardia"])
        XCTAssertEqual(MapRegionIndex.search("  PIEMONTE ", in: regions).map(\.id), ["it-piemonte"])
        let italy = MapRegionIndex.search("IT", in: regions)
        XCTAssertTrue(italy.contains { $0.id == "country-it" })
        XCTAssertTrue(MapRegionIndex.search("", in: regions).isEmpty)
        XCTAssertTrue(MapRegionIndex.search("zzzz", in: regions).isEmpty)
        let parts = MapRegionIndex.parts(of: "IT", in: regions)
        XCTAssertEqual(parts.count, 20)
        XCTAssertTrue(parts.allSatisfy { !$0.isCountry })
    }

    @MainActor
    func testPublishedSizesDecideSizeAndAvailability() throws {
        let regions = MapRegionCatalog.load()
        let lombardia = try XCTUnwrap(regions.first { $0.id == "it-lombardia" })
        let alaska = try XCTUnwrap(regions.first { $0.id == "us-alaska" })
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = OfflineMapStore(regions: regions, directory: dir, baseURL: nil)

        // Before the list is read: estimates, and everything can be tried.
        XCTAssertEqual(store.expectedBytes(of: lombardia), Int64(lombardia.estimatedMB) * 1_000_000)
        XCTAssertNil(store.expectedBytes(of: alaska))
        XCTAssertTrue(store.isPublished(alaska))

        let json = #"{"source_build": "20261113", "areas": [{"id": "it-lombardia", "bytes": 596716534, "maxzoom": 15}]}"#
        let catalog = try XCTUnwrap(MapSizeCatalog.decode(Data(json.utf8)))
        store.applyCatalog(catalog)
        XCTAssertEqual(store.expectedBytes(of: lombardia), 596_716_534)
        XCTAssertTrue(store.isPublished(lombardia))
        XCTAssertFalse(store.isPublished(alaska))
        XCTAssertNil(MapSizeCatalog.decode(Data("[]".utf8)))
    }

    func testInvalidRegionsAreDropped() {
        let json = """
        {"regions": [
          {"id": "ok", "name": "Ok", "bbox": [7, 44, 8, 45], "maxzoom": 15, "estimatedMB": 10},
          {"id": "new", "name": "New", "parent": "US", "continent": "north-america", "bbox": [7, 44, 8, 45], "maxzoom": 14, "estimatedMB": 0},
          {"id": "swapped", "name": "Bad", "bbox": [8, 44, 7, 45], "maxzoom": 15, "estimatedMB": 10},
          {"id": "short", "name": "Bad", "bbox": [8, 44], "maxzoom": 15, "estimatedMB": 10}
        ]}
        """
        XCTAssertEqual(MapRegionCatalog.decode(Data(json.utf8)).map(\.id), ["ok", "new"])
        XCTAssertTrue(MapRegionCatalog.decode(Data("not json".utf8)).isEmpty)
    }

    func testDownloadsPointToTheMapsRelease() throws {
        let region = try XCTUnwrap(MapRegionCatalog.load().first)
        XCTAssertEqual(MapRegionCatalog.catalogURL()?.absoluteString,
                       "https://github.com/mrenzomaggio-boop/survive72-maps/releases/download/maps/catalog.json")
        XCTAssertEqual(MapRegionCatalog.downloadURL(for: region)?.absoluteString,
                       "https://github.com/mrenzomaggio-boop/survive72-maps/releases/download/maps/\(region.id).pmtiles")
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
