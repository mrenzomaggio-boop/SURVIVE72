import Foundation

/// One area of the world that can be downloaded for offline use.
/// The list lives in `MapStyle/regions.json`, shared with the workflow that
/// cuts the map files, so the app and the files always use the same ids.
struct MapRegion: Identifiable, Hashable, Decodable {
    let id: String
    /// Italian region name. Countries use `iso` instead and are named in the
    /// iPhone language.
    let name: String?
    /// ISO 3166 country code, for whole countries.
    let iso: String?
    /// [west, south, east, north] in degrees.
    let bbox: [Double]
    let maxzoom: Int
    let estimatedMB: Int

    var isCountry: Bool { iso != nil }

    var title: String {
        if let iso {
            return Locale.current.localizedString(forRegionCode: iso) ?? iso
        }
        return name ?? id
    }

    var west: Double { bbox[0] }
    var south: Double { bbox[1] }
    var east: Double { bbox[2] }
    var north: Double { bbox[3] }
    var centerLatitude: Double { (south + north) / 2 }
    var centerLongitude: Double { (west + east) / 2 }

    /// Zoom level that shows the whole area on a phone screen about 390
    /// points wide.
    var fittingZoom: Double {
        let span = max(east - west, (north - south) * 1.4, 0.01)
        return max(2, min(14, log2(390 * 360 / (256 * span)) - 0.3))
    }

    var isValid: Bool {
        bbox.count == 4 && west < east && south < north
            && (-180...180).contains(west) && (-180...180).contains(east)
            && (-90...90).contains(south) && (-90...90).contains(north)
            && (0...15).contains(maxzoom) && estimatedMB > 0
    }

    /// Name of the file, both online and on the device.
    var fileName: String { "\(id).pmtiles" }
}

private struct MapRegionFile: Decodable {
    let regions: [MapRegion]
}

/// The downloadable areas bundled with the app.
enum MapRegionCatalog {
    /// Where the map files are published. Nil until the hosting is decided:
    /// the app then shows the areas but cannot download them yet.
    static let downloadBaseURL: URL? = nil

    static func load(bundle: Bundle = .main) -> [MapRegion] {
        guard let url = bundle.url(forResource: "regions", withExtension: "json", subdirectory: "MapStyle"),
              let data = try? Data(contentsOf: url) else { return [] }
        return decode(data)
    }

    static func decode(_ data: Data) -> [MapRegion] {
        guard let file = try? JSONDecoder().decode(MapRegionFile.self, from: data) else { return [] }
        return file.regions.filter(\.isValid)
    }

    static func downloadURL(for region: MapRegion, base: URL? = downloadBaseURL) -> URL? {
        base?.appendingPathComponent(region.fileName)
    }
}

/// Builds the MapLibre style for the downloaded areas. The style, fonts and
/// symbols ship with the app (Protomaps basemaps, BSD-3-Clause; Noto Sans,
/// SIL OFL), so the map draws with no connection at all.
enum OfflineMapStyle {
    static let sourcePrefix = "area-"

    static var resourcesURL: URL? {
        Bundle.main.url(forResource: "MapStyle", withExtension: nil)
    }

    /// The style as JSON data. `regions` are the downloaded areas with the
    /// local path of their file; without areas the style is a plain
    /// background.
    static func build(regions: [(id: String, file: URL)], dark: Bool, resources: URL) throws -> Data {
        let flavor = dark ? "dark" : "light"
        let layersData = try Data(contentsOf: resources.appendingPathComponent("layers-\(flavor).json"))
        guard let template = try JSONSerialization.jsonObject(with: layersData) as? [[String: Any]] else {
            throw CocoaError(.fileReadCorruptFile)
        }

        var sources: [String: Any] = [:]
        var layers: [[String: Any]] = template.filter { ($0["type"] as? String) == "background" }
        for region in regions {
            let sourceID = sourcePrefix + region.id
            sources[sourceID] = [
                "type": "vector",
                "url": "pmtiles://" + region.file.absoluteString,
                "attribution": "© OpenStreetMap",
            ]
            for layer in template where (layer["type"] as? String) != "background" {
                var copy = layer
                copy["id"] = "\(region.id)-\(layer["id"] as? String ?? "layer")"
                copy["source"] = sourceID
                layers.append(copy)
            }
        }

        let fonts = resources.appendingPathComponent("fonts", isDirectory: true).absoluteString
        let sprite = resources.appendingPathComponent("sprites", isDirectory: true)
            .appendingPathComponent(flavor).absoluteString
        let style: [String: Any] = [
            "version": 8,
            "name": "SURVIVE 72 offline",
            "glyphs": fonts + "{fontstack}/{range}.pbf",
            "sprite": sprite,
            "sources": sources,
            "layers": layers,
        ]
        return try JSONSerialization.data(withJSONObject: style)
    }
}
