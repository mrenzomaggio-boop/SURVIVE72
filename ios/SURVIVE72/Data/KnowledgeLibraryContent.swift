import Foundation

/// Bundled demo articles. They are placeholders that describe what each
/// article will cover; they contain no instructions and no medical guidance.
/// Every article is marked TO BE VERIFIED until reviewed content replaces it.
enum KnowledgeLibraryContent {
    private static let notice =
        String(localized: "Demo content. This article is a placeholder and has not been reviewed. Do not rely on it.")

    static let articles: [KnowledgeArticle] = [
        KnowledgeArticle(
            id: "water.sources", category: .water,
            title: String(localized: "Finding water sources"),
            summary: String(localized: "Overview of where water may be found in different environments."),
            paragraphs: [notice,
                         String(localized: "Planned topics: rain collection, natural sources, and storage containers."),
                         String(localized: "Reviewed text will be added after verification by qualified sources.")]),
        KnowledgeArticle(
            id: "water.storage", category: .water,
            title: String(localized: "Storing drinking water"),
            summary: String(localized: "How household water reserves can be organised and rotated."),
            paragraphs: [notice,
                         String(localized: "Planned topics: container types, labelling, rotation schedule.")]),

        KnowledgeArticle(
            id: "shelter.basics", category: .shelter,
            title: String(localized: "Shelter basics"),
            summary: String(localized: "Why protection from wind, rain and cold matters in the first hours."),
            paragraphs: [notice,
                         String(localized: "Planned topics: choosing a location, insulation from the ground, staying dry.")]),
        KnowledgeArticle(
            id: "shelter.home", category: .shelter,
            title: String(localized: "Sheltering at home"),
            summary: String(localized: "Preparing a safe room and household plan."),
            paragraphs: [notice,
                         String(localized: "Planned topics: safe room selection, family meeting point, home supplies.")]),

        KnowledgeArticle(
            id: "fire.safety", category: .fire,
            title: String(localized: "Fire safety"),
            summary: String(localized: "General awareness about fire risks during emergencies."),
            paragraphs: [notice,
                         String(localized: "Planned topics: smoke detectors, extinguishers, evacuation routes.")]),
        KnowledgeArticle(
            id: "fire.warmth", category: .fire,
            title: String(localized: "Staying warm"),
            summary: String(localized: "Keeping warm when power and heating are unavailable."),
            paragraphs: [notice,
                         String(localized: "Planned topics: layered clothing, blankets, shared body heat.")]),

        KnowledgeArticle(
            id: "food.supplies", category: .food,
            title: String(localized: "Emergency food supplies"),
            summary: String(localized: "Building a three-day stock of non-perishable food."),
            paragraphs: [notice,
                         String(localized: "Planned topics: shelf life, rotation, special dietary needs.")]),
        KnowledgeArticle(
            id: "food.cooking", category: .food,
            title: String(localized: "Cooking without power"),
            summary: String(localized: "Options for preparing meals during a blackout."),
            paragraphs: [notice,
                         String(localized: "Planned topics: no-cook meals, camping stoves, ventilation.")]),

        KnowledgeArticle(
            id: "navigation.compass", category: .navigation,
            title: String(localized: "Using a compass"),
            summary: String(localized: "Introduction to orienting yourself without GPS."),
            paragraphs: [notice,
                         String(localized: "Planned topics: compass parts, taking a bearing, paper maps.")]),
        KnowledgeArticle(
            id: "navigation.landmarks", category: .navigation,
            title: String(localized: "Landmarks and routes"),
            summary: String(localized: "Planning evacuation routes in advance."),
            paragraphs: [notice,
                         String(localized: "Planned topics: primary and backup routes, meeting points, landmarks.")]),

        KnowledgeArticle(
            id: "communication.radio", category: .communication,
            title: String(localized: "Emergency radio"),
            summary: String(localized: "Receiving official updates when phone networks are down."),
            paragraphs: [notice,
                         String(localized: "Planned topics: hand-crank radios, broadcast channels, battery use.")]),
        KnowledgeArticle(
            id: "communication.signals", category: .communication,
            title: String(localized: "Signalling for help"),
            summary: String(localized: "Ways to attract attention when you cannot call."),
            paragraphs: [notice,
                         String(localized: "Planned topics: whistle signals, light signals, visible markers.")])
    ]
}
