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
    /// For a part of a country (Italian region, US state…): the country code.
    let parent: String?
    /// One of `MapContinent`'s raw values.
    let continent: String?
    /// [west, south, east, north] in degrees.
    let bbox: [Double]
    let maxzoom: Int
    let estimatedMB: Int

    var isCountry: Bool { iso != nil }

    /// The country this area is, or belongs to.
    var countryCode: String? { iso ?? parent }

    var mapContinent: MapContinent? { continent.flatMap(MapContinent.init(rawValue:)) }

    /// Name of the country this area belongs to, for parts of a country.
    var parentTitle: String? {
        parent.map { Locale.current.localizedString(forRegionCode: $0) ?? $0 }
    }

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
            && (0...15).contains(maxzoom) && estimatedMB >= 0
    }

    /// Name of the file, both online and on the device.
    var fileName: String { "\(id).pmtiles" }
}

/// Continents used to group the countries in the list.
enum MapContinent: String, CaseIterable, Identifiable {
    case europe, asia, africa, northAmerica = "north-america", southAmerica = "south-america", oceania

    var id: String { rawValue }

    var title: String {
        switch self {
        case .europe: String(localized: "Europe")
        case .asia: String(localized: "Asia")
        case .africa: String(localized: "Africa")
        case .northAmerica: String(localized: "North and Central America")
        case .southAmerica: String(localized: "South America")
        case .oceania: String(localized: "Oceania")
        }
    }

    var systemImage: String {
        switch self {
        case .europe, .africa: "globe.europe.africa.fill"
        case .asia, .oceania: "globe.asia.australia.fill"
        case .northAmerica, .southAmerica: "globe.americas.fill"
        }
    }
}

/// Real file sizes published next to the map files (`catalog.json`).
struct MapSizeCatalog: Decodable, Equatable {
    struct Area: Decodable, Equatable {
        let id: String
        let bytes: Int64
    }

    let areas: [Area]

    var bytesByID: [String: Int64] {
        Dictionary(areas.map { ($0.id, $0.bytes) }, uniquingKeysWith: { first, _ in first })
    }

    static func decode(_ data: Data) -> MapSizeCatalog? {
        try? JSONDecoder().decode(MapSizeCatalog.self, from: data)
    }
}

/// Search and grouping of the areas, kept out of the views so it can be tested.
enum MapRegionIndex {
    static func sortedByTitle(_ regions: [MapRegion]) -> [MapRegion] {
        regions.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// Whole countries of a continent.
    static func countries(in continent: MapContinent, of regions: [MapRegion]) -> [MapRegion] {
        sortedByTitle(regions.filter { $0.isCountry && $0.mapContinent == continent })
    }

    /// Parts (regions, states) of a country.
    static func parts(of countryCode: String, in regions: [MapRegion]) -> [MapRegion] {
        sortedByTitle(regions.filter { !$0.isCountry && $0.parent == countryCode })
    }

    /// Areas whose name, or country name, contains the text. Ignores case and accents.
    static func search(_ text: String, in regions: [MapRegion]) -> [MapRegion] {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let found = regions.filter { region in
            region.title.range(of: query, options: options) != nil
                || (region.parentTitle?.range(of: query, options: options) != nil)
                || (region.countryCode?.caseInsensitiveCompare(query) == .orderedSame)
        }
        // Whole countries first, then their parts.
        return sortedByTitle(found.filter(\.isCountry)) + sortedByTitle(found.filter { !$0.isCountry })
    }
}

private struct MapRegionFile: Decodable {
    let regions: [MapRegion]
}

/// The downloadable areas bundled with the app.
enum MapRegionCatalog {
    /// Where the map files are published: the "maps" release of the public
    /// survive72-maps repository, rebuilt every month by its workflow.
    /// Nil would show the areas without letting them be downloaded.
    static let downloadBaseURL: URL? = URL(string: "https://github.com/mrenzomaggio-boop/survive72-maps/releases/download/maps")

    static func load(bundle: Bundle = .main) -> [MapRegion] {
        guard let url = bundle.url(forResource: "regions", withExtension: "json", subdirectory: "MapStyle"),
              let data = try? Data(contentsOf: url) else { return [] }
        return decode(data)
    }

    static func decode(_ data: Data) -> [MapRegion] {
        guard let file = try? JSONDecoder().decode(MapRegionFile.self, from: data) else { return [] }
        return file.regions.filter(\.isValid)
    }

    static func catalogURL(base: URL? = downloadBaseURL) -> URL? {
        base?.appendingPathComponent("catalog.json")
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
