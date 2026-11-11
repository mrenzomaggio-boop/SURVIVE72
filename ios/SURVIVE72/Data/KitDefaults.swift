import Foundation

/// Built-in starting list for the first 72 hours, bundled with the app.
/// Item IDs are persisted: never change an existing ID, only add new ones.
enum KitDefaults {
    static let items: [KitItem] = [
        // Water
        KitItem(id: "water.drinking", category: .water,
                title: "Drinking water", detail: "About 4 L per person per day, for 3 days"),
        KitItem(id: "water.purification", category: .water,
                title: "Water purification", detail: "Tablets or a portable filter"),
        KitItem(id: "water.bottle", category: .water,
                title: "Refillable bottle", detail: "Sturdy, with a sealed cap"),

        // Food
        KitItem(id: "food.nonperishable", category: .food,
                title: "Non-perishable food", detail: "Ready to eat, for 3 days"),
        KitItem(id: "food.canopener", category: .food,
                title: "Manual can opener", detail: "Works without power"),
        KitItem(id: "food.energy", category: .food,
                title: "Energy bars", detail: "Compact and long-lasting"),

        // Health
        KitItem(id: "health.firstaid", category: .health,
                title: "First aid kit", detail: "Check contents and expiry dates"),
        KitItem(id: "health.medications", category: .health,
                title: "Personal medications", detail: "Enough for at least 7 days"),
        KitItem(id: "health.hygiene", category: .health,
                title: "Hygiene supplies", detail: "Hand sanitizer, wipes, tissues"),
        KitItem(id: "health.masks", category: .health,
                title: "Face masks", detail: "For dust or smoke"),

        // Lighting
        KitItem(id: "lighting.flashlight", category: .lighting,
                title: "Flashlight", detail: "One per person if possible"),
        KitItem(id: "lighting.headlamp", category: .lighting,
                title: "Headlamp", detail: "Keeps both hands free"),
        KitItem(id: "lighting.batteries", category: .lighting,
                title: "Spare batteries", detail: "Matching your devices"),
        KitItem(id: "lighting.fire", category: .lighting,
                title: "Matches or lighter", detail: "Stored in a waterproof container"),

        // Documents
        KitItem(id: "documents.id", category: .documents,
                title: "ID copies", detail: "In a waterproof bag"),
        KitItem(id: "documents.contacts", category: .documents,
                title: "Emergency contacts", detail: "Written on paper"),
        KitItem(id: "documents.cash", category: .documents,
                title: "Cash", detail: "Small bills and coins"),
        KitItem(id: "documents.insurance", category: .documents,
                title: "Insurance and medical records", detail: "Paper copies"),

        // Gear
        KitItem(id: "gear.radio", category: .gear,
                title: "Battery or hand-crank radio", detail: "To receive official updates"),
        KitItem(id: "gear.powerbank", category: .gear,
                title: "Power bank", detail: "Fully charged, with cable"),
        KitItem(id: "gear.multitool", category: .gear,
                title: "Multi-tool", detail: "Knife, pliers, screwdriver"),
        KitItem(id: "gear.whistle", category: .gear,
                title: "Whistle", detail: "To signal for help"),
        KitItem(id: "gear.blanket", category: .gear,
                title: "Emergency blanket", detail: "Thermal, compact"),
        KitItem(id: "gear.clothing", category: .gear,
                title: "Warm clothes and rain gear", detail: "One change per person")
    ]
}
