import Foundation

/// Bundled demo articles. They are placeholders that describe what each
/// article will cover; they contain no instructions and no medical guidance.
/// Every article is marked TO BE VERIFIED until reviewed content replaces it.
enum KnowledgeLibraryContent {
    private static let notice =
        "Demo content. This article is a placeholder and has not been reviewed. Do not rely on it."

    static let articles: [KnowledgeArticle] = [
        KnowledgeArticle(
            id: "water.sources", category: .water,
            title: "Finding water sources",
            summary: "Overview of where water may be found in different environments.",
            paragraphs: [notice,
                         "Planned topics: rain collection, natural sources, and storage containers.",
                         "Reviewed text will be added after verification by qualified sources."]),
        KnowledgeArticle(
            id: "water.storage", category: .water,
            title: "Storing drinking water",
            summary: "How household water reserves can be organised and rotated.",
            paragraphs: [notice,
                         "Planned topics: container types, labelling, rotation schedule."]),

        KnowledgeArticle(
            id: "shelter.basics", category: .shelter,
            title: "Shelter basics",
            summary: "Why protection from wind, rain and cold matters in the first hours.",
            paragraphs: [notice,
                         "Planned topics: choosing a location, insulation from the ground, staying dry."]),
        KnowledgeArticle(
            id: "shelter.home", category: .shelter,
            title: "Sheltering at home",
            summary: "Preparing a safe room and household plan.",
            paragraphs: [notice,
                         "Planned topics: safe room selection, family meeting point, home supplies."]),

        KnowledgeArticle(
            id: "fire.safety", category: .fire,
            title: "Fire safety",
            summary: "General awareness about fire risks during emergencies.",
            paragraphs: [notice,
                         "Planned topics: smoke detectors, extinguishers, evacuation routes."]),
        KnowledgeArticle(
            id: "fire.warmth", category: .fire,
            title: "Staying warm",
            summary: "Keeping warm when power and heating are unavailable.",
            paragraphs: [notice,
                         "Planned topics: layered clothing, blankets, shared body heat."]),

        KnowledgeArticle(
            id: "food.supplies", category: .food,
            title: "Emergency food supplies",
            summary: "Building a three-day stock of non-perishable food.",
            paragraphs: [notice,
                         "Planned topics: shelf life, rotation, special dietary needs."]),
        KnowledgeArticle(
            id: "food.cooking", category: .food,
            title: "Cooking without power",
            summary: "Options for preparing meals during a blackout.",
            paragraphs: [notice,
                         "Planned topics: no-cook meals, camping stoves, ventilation."]),

        KnowledgeArticle(
            id: "navigation.compass", category: .navigation,
            title: "Using a compass",
            summary: "Introduction to orienting yourself without GPS.",
            paragraphs: [notice,
                         "Planned topics: compass parts, taking a bearing, paper maps."]),
        KnowledgeArticle(
            id: "navigation.landmarks", category: .navigation,
            title: "Landmarks and routes",
            summary: "Planning evacuation routes in advance.",
            paragraphs: [notice,
                         "Planned topics: primary and backup routes, meeting points, landmarks."]),

        KnowledgeArticle(
            id: "communication.radio", category: .communication,
            title: "Emergency radio",
            summary: "Receiving official updates when phone networks are down.",
            paragraphs: [notice,
                         "Planned topics: hand-crank radios, broadcast channels, battery use."]),
        KnowledgeArticle(
            id: "communication.signals", category: .communication,
            title: "Signalling for help",
            summary: "Ways to attract attention when you cannot call.",
            paragraphs: [notice,
                         "Planned topics: whistle signals, light signals, visible markers."])
    ]
}
