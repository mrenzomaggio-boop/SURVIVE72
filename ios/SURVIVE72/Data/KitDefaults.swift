import Foundation

/// Built-in starting list for the first 72 hours, bundled with the app.
/// Item IDs are persisted: never change an existing ID, only add new ones.
enum KitDefaults {
    static let items: [KitItem] = [
        // Water
        KitItem(id: "water.drinking", category: .water,
                title: String(localized: "Drinking water"), detail: String(localized: "About 4 L per person per day, for 3 days")),
        KitItem(id: "water.purification", category: .water,
                title: String(localized: "Water purification"), detail: String(localized: "Tablets or a portable filter")),
        KitItem(id: "water.bottle", category: .water,
                title: String(localized: "Refillable bottle"), detail: String(localized: "Sturdy, with a sealed cap")),

        // Food
        KitItem(id: "food.nonperishable", category: .food,
                title: String(localized: "Non-perishable food"), detail: String(localized: "Ready to eat, for 3 days")),
        KitItem(id: "food.canopener", category: .food,
                title: String(localized: "Manual can opener"), detail: String(localized: "Works without power")),
        KitItem(id: "food.energy", category: .food,
                title: String(localized: "Energy bars"), detail: String(localized: "Compact and long-lasting")),

        // Health
        KitItem(id: "health.firstaid", category: .health,
                title: String(localized: "First aid kit"), detail: String(localized: "Check contents and expiry dates")),
        KitItem(id: "health.medications", category: .health,
                title: String(localized: "Personal medications"), detail: String(localized: "Enough for at least 7 days")),
        KitItem(id: "health.hygiene", category: .health,
                title: String(localized: "Hygiene supplies"), detail: String(localized: "Hand sanitizer, wipes, tissues")),
        KitItem(id: "health.masks", category: .health,
                title: String(localized: "Face masks"), detail: String(localized: "For dust or smoke")),

        // Lighting
        KitItem(id: "lighting.flashlight", category: .lighting,
                title: String(localized: "Flashlight"), detail: String(localized: "One per person if possible")),
        KitItem(id: "lighting.headlamp", category: .lighting,
                title: String(localized: "Headlamp"), detail: String(localized: "Keeps both hands free")),
        KitItem(id: "lighting.batteries", category: .lighting,
                title: String(localized: "Spare batteries"), detail: String(localized: "Matching your devices")),
        KitItem(id: "lighting.fire", category: .lighting,
                title: String(localized: "Matches or lighter"), detail: String(localized: "Stored in a waterproof container")),

        // Documents
        KitItem(id: "documents.id", category: .documents,
                title: String(localized: "ID copies"), detail: String(localized: "In a waterproof bag")),
        KitItem(id: "documents.contacts", category: .documents,
                title: String(localized: "Emergency contacts"), detail: String(localized: "Written on paper")),
        KitItem(id: "documents.cash", category: .documents,
                title: String(localized: "Cash"), detail: String(localized: "Small bills and coins")),
        KitItem(id: "documents.insurance", category: .documents,
                title: String(localized: "Insurance and medical records"), detail: String(localized: "Paper copies")),

        // Gear
        KitItem(id: "gear.radio", category: .gear,
                title: String(localized: "Battery or hand-crank radio"), detail: String(localized: "To receive official updates")),
        KitItem(id: "gear.powerbank", category: .gear,
                title: String(localized: "Power bank"), detail: String(localized: "Fully charged, with cable")),
        KitItem(id: "gear.multitool", category: .gear,
                title: String(localized: "Multi-tool"), detail: String(localized: "Knife, pliers, screwdriver")),
        KitItem(id: "gear.whistle", category: .gear,
                title: String(localized: "Whistle"), detail: String(localized: "To signal for help")),
        KitItem(id: "gear.blanket", category: .gear,
                title: String(localized: "Emergency blanket"), detail: String(localized: "Thermal, compact")),
        KitItem(id: "gear.clothing", category: .gear,
                title: String(localized: "Warm clothes and rain gear"), detail: String(localized: "One change per person"))
    ]
}
