import XCTest
@testable import SURVIVE72

/// Saved user data must survive app updates and damaged values:
/// nothing is silently thrown away and overwritten.
final class PersistenceSafetyTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SURVIVE72Tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func save(_ json: String, forKey key: String) {
        defaults.set(Data(json.utf8), forKey: key)
    }

    // MARK: Unreadable data is kept, never overwritten

    func testUnreadableDataIsBackedUpBeforeTheNextSave() throws {
        let broken = Data("not json".utf8)
        defaults.set(broken, forKey: AlertPlanStore.storageKey)

        let store = AlertPlanStore(defaults: defaults)
        store.addContact(name: "Ada", phone: "", relationship: "")

        let backup = try XCTUnwrap(defaults.data(forKey: AlertPlanStore.storageKey + LocalStorage.unreadableSuffix))
        XCTAssertEqual(backup, broken)
        XCTAssertEqual(AlertPlanStore(defaults: defaults).contacts.map(\.name), ["Ada"])
    }

    func testAnOlderBackupIsNeverReplaced() {
        let first = Data("first broken".utf8)
        defaults.set(first, forKey: SettingsStore.storageKey)
        _ = SettingsStore(defaults: defaults)

        defaults.set(Data("second broken".utf8), forKey: SettingsStore.storageKey)
        _ = SettingsStore(defaults: defaults)

        XCTAssertEqual(defaults.data(forKey: SettingsStore.storageKey + LocalStorage.unreadableSuffix), first)
    }

    func testEraseAllAlsoRemovesBackups() {
        let keys = [AlertPlanStore.storageKey, SettingsStore.storageKey, ConnectStore.storageKey,
                    MapsStore.storageKey, MedicalStore.storageKey]
        for key in keys { defaults.set(Data("broken".utf8), forKey: key) }

        let kit = KitChecklistStore(defaults: defaults)
        let alert = AlertPlanStore(defaults: defaults)
        let settings = SettingsStore(defaults: defaults)
        let downloads = DownloadsStore(defaults: defaults)
        let connect = ConnectStore(defaults: defaults)
        let maps = MapsStore(defaults: defaults)
        let medical = MedicalStore(defaults: defaults)
        for key in keys {
            XCTAssertNotNil(defaults.object(forKey: key + LocalStorage.unreadableSuffix), key)
        }

        LocalDataReset.perform(kit: kit, alert: alert, settings: settings, downloads: downloads,
                               connect: connect, maps: maps, medical: medical, tools: ToolsState())

        for key in keys {
            XCTAssertNil(defaults.object(forKey: key), key)
            XCTAssertNil(defaults.object(forKey: key + LocalStorage.unreadableSuffix), key)
        }
    }

    // MARK: Format changes keep the user's data

    func testAlertPlanKeepsDataWhenFieldsAreMissingOrUnknown() {
        save("""
        {"plan": {"name": "Ada", "futureField": 1},
         "contacts": [{"name": "Bob"}, {"name": "Cy", "phone": "123", "relationship": "Brother"}],
         "anotherFutureField": true}
        """, forKey: AlertPlanStore.storageKey)

        let store = AlertPlanStore(defaults: defaults)
        XCTAssertEqual(store.plan.name, "Ada")
        XCTAssertEqual(store.plan.meetingPoint, "")
        XCTAssertEqual(store.contacts.map(\.name), ["Bob", "Cy"])
        XCTAssertEqual(store.contacts[1].phone, "123")
        XCTAssertNil(store.data.messageDraft)
    }

    func testOneDamagedContactDoesNotLoseTheOthers() {
        save("""
        {"contacts": [{"name": "Ada"}, {"phone": "no name"}, {"name": 42}, {"name": "Bob"}]}
        """, forKey: AlertPlanStore.storageKey)

        XCTAssertEqual(AlertPlanStore(defaults: defaults).contacts.map(\.name), ["Ada", "Bob"])
    }

    func testSettingsKeepOtherPreferencesWhenOneValueIsUnknown() {
        save("""
        {"unitSystem": "nautical", "highContrast": false, "batterySaver": true}
        """, forKey: SettingsStore.storageKey)

        let settings = SettingsStore(defaults: defaults).settings
        XCTAssertEqual(settings.unitSystem, .metric)
        XCTAssertFalse(settings.highContrast)
        XCTAssertTrue(settings.batterySaver)
    }

    func testMapsKeepValidPlacesWhenOneIsDamaged() {
        save("""
        {"places": [{"name": "Home", "latitude": 45.1, "longitude": 9.2},
                    {"name": "Broken", "latitude": "north"}],
         "preparedAreaIDs": []}
        """, forKey: MapsStore.storageKey)

        XCTAssertEqual(MapsStore(defaults: defaults).places.map(\.name), ["Home"])
    }

    func testConnectKeepsMessagesAndNeverReusesAnOrder() throws {
        save("""
        {"conversations": [{"id": "family", "title": "Family", "subtitle": ""}],
         "messages": [{"conversationID": "family", "text": "Hello", "isOutgoing": true,
                       "createdAt": 0, "sequence": 7, "queueOrder": 9, "state": "queued"}],
         "nextOrder": 3}
        """, forKey: ConnectStore.storageKey)

        let store = ConnectStore(defaults: defaults)
        XCTAssertEqual(store.history(in: "family").map(\.text), ["Hello"])
        XCTAssertEqual(store.data.nextOrder, 10)

        let sent = try XCTUnwrap(store.send("Second", to: "family"))
        XCTAssertEqual(sent.sequence, 10)
    }

    func testConnectWithoutConversationsFallsBackToDemoConversations() {
        save("""
        {"messages": []}
        """, forKey: ConnectStore.storageKey)

        XCTAssertEqual(ConnectStore(defaults: defaults).conversations, ConnectDemoContent.conversations)
    }

    func testMedicalKeepsFavoritesWhenCategoryIsDamaged() throws {
        let id = try XCTUnwrap(MedicalLibraryContent.ids.sorted().first)
        save("""
        {"favoriteIDs": ["\(id)"], "lastCategory": 12}
        """, forKey: MedicalStore.storageKey)

        let store = MedicalStore(defaults: defaults)
        XCTAssertEqual(store.favoriteIDs, [id])
        XCTAssertNil(store.lastCategory)
    }

    // MARK: Round trips are unchanged

    func testSavedValuesStillRoundTrip() throws {
        let plan = AlertPlanData(
            plan: PersonalPlan(name: "Ada", meetingPoint: "Square", note: "Keys"),
            contacts: [EmergencyContact(name: "Bob", phone: "1", relationship: "Friend")],
            messageDraft: "Custom")
        XCTAssertEqual(try JSONDecoder().decode(AlertPlanData.self, from: JSONEncoder().encode(plan)), plan)

        let connect = ConnectDemoContent.initialData()
        XCTAssertEqual(try JSONDecoder().decode(ConnectData.self, from: JSONEncoder().encode(connect)), connect)

        let maps = MapsData(places: [SavedPlace(name: "Home", latitude: 1, longitude: 2, note: "n")],
                            preparedAreaIDs: [])
        XCTAssertEqual(try JSONDecoder().decode(MapsData.self, from: JSONEncoder().encode(maps)), maps)

        let settings = AppSettings(unitSystem: .imperial, highContrast: false, batterySaver: true)
        XCTAssertEqual(try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings)), settings)
    }
}
