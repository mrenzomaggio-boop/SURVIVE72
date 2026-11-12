import Foundation

/// Bundled articles, adapted and summarised from the "Io non rischio" campaign
/// of the Italian Civil Protection Department (CC BY 4.0). Every article shows
/// the mandatory credit through `ContentSource.ioNonRischio`.
enum KnowledgeLibraryContent {
    private static let before = String(localized: "Before")
    private static let after = String(localized: "After")

    private static func point(_ symbol: String, _ text: String) -> KnowledgePoint {
        KnowledgePoint(symbol: symbol, text: text)
    }

    static let articles: [KnowledgeArticle] = [
        KnowledgeArticle(
            id: "earthquake.what-to-do", category: .earthquake,
            title: String(localized: "Earthquake: what to do"),
            summary: String(localized: "How to prepare your home, where to shelter during the shaking and what to do afterwards."),
            sections: [
                KnowledgeSection(heading: before, symbol: "calendar.badge.clock", points: [
                    point("wrench.and.screwdriver.fill", String(localized: "Ask a qualified technician whether your home needs strengthening.")),
                    point("sofa.fill", String(localized: "Move heavy furniture away from beds and sofas. Fix shelves, bookcases and tall furniture to the wall.")),
                    point("books.vertical.fill", String(localized: "Keep heavy objects on low shelves.")),
                    point("spigot.fill", String(localized: "Learn where and how to shut off gas, water and the main electricity switch.")),
                    point("backpack.fill", String(localized: "Prepare an emergency kit with documents, a first aid kit, a torch and a battery radio.")),
                    point("house.fill", String(localized: "Find the safe spots in your home and read your municipality's civil protection plan."))
                ]),
                KnowledgeSection(heading: String(localized: "During: indoors"), symbol: "house.fill", points: [
                    point("table.furniture.fill", String(localized: "Shelter under a sturdy table, in a doorway in a load-bearing wall or next to a load-bearing wall.")),
                    point("xmark.octagon.fill", String(localized: "Stay away from the middle of the room, where objects and furniture can fall on you.")),
                    point("figure.stand", String(localized: "Do not rush outside: wait until the shaking stops."))
                ]),
                KnowledgeSection(heading: String(localized: "During: outdoors"), symbol: "tree.fill", points: [
                    point("building.2.fill", String(localized: "Move away from buildings, trees, street lights and power lines.")),
                    point("exclamationmark.triangle.fill", String(localized: "Watch out for damaged bridges, landslides and gas leaks."))
                ]),
                KnowledgeSection(heading: after, symbol: "checkmark.circle.fill", points: [
                    point("person.2.fill", String(localized: "Check on the people around you and give first aid if needed.")),
                    point("shoe.fill", String(localized: "Before going out, shut off gas, water and electricity and put on shoes.")),
                    point("stairs", String(localized: "Do not use the lift and be careful on the stairs, which may be damaged.")),
                    point("water.waves", String(localized: "If you are near the sea, move away from the beach to higher ground.")),
                    point("phone.down.fill", String(localized: "Use the phone as little as possible and the car only if necessary, to keep the way clear for rescuers.")),
                    point("mappin.and.ellipse", String(localized: "Go to the waiting areas listed in your municipality's civil protection plan."))
                ])
            ]),

        KnowledgeArticle(
            id: "flood.what-to-do", category: .flood,
            title: String(localized: "Flood: what to do"),
            summary: String(localized: "How to prepare, what to do during a weather alert and how to stay safe when water rises."),
            sections: [
                KnowledgeSection(heading: before, symbol: "calendar.badge.clock", points: [
                    point("exclamationmark.bubble.fill", String(localized: "Report blocked drains, abandoned waste and obstructed streams to your municipality.")),
                    point("map.fill", String(localized: "Read your municipality's civil protection plan: flood-prone areas, escape routes and safe areas.")),
                    point("figure.roll", String(localized: "Tell your municipality if someone in your family needs special assistance.")),
                    point("backpack.fill", String(localized: "Prepare an emergency kit and do not keep valuables in cellars or basements."))
                ]),
                KnowledgeSection(heading: String(localized: "During an alert"), symbol: "exclamationmark.triangle.fill", points: [
                    point("bell.fill", String(localized: "Follow the alerts of your region and the measures taken by your municipality.")),
                    point("bed.double.fill", String(localized: "Do not sleep or stay in basements.")),
                    point("door.left.hand.closed", String(localized: "Protect ground-floor rooms, but only if it does not put you in danger.")),
                    point("map.fill", String(localized: "Before moving, check your route and avoid flood-prone areas.")),
                    point("graduationcap.fill", String(localized: "Make sure your children's school knows about the alert."))
                ]),
                KnowledgeSection(heading: String(localized: "During the flood: indoors"), symbol: "house.fill", points: [
                    point("car.fill", String(localized: "Do not go down to cellars or garages and do not go out to move the car.")),
                    point("arrow.up.circle.fill", String(localized: "Go to the upper floors and do not use the lift.")),
                    point("figure.roll", String(localized: "Help elderly people and people with disabilities in the building.")),
                    point("powerplug.fill", String(localized: "Shut off the gas and the electricity. Do not touch electrical devices if you are wet.")),
                    point("spigot.fill", String(localized: "Do not drink tap water: it may be contaminated."))
                ]),
                KnowledgeSection(heading: String(localized: "During the flood: outdoors"), symbol: "tree.fill", points: [
                    point("figure.walk", String(localized: "Move away from the water: even a few centimetres of flowing water can knock you over.")),
                    point("mountain.2.fill", String(localized: "Reach the nearest high ground, away from slopes and embankments that could collapse.")),
                    point("car.fill", String(localized: "Do not drive. Avoid underpasses, riverbanks and bridges.")),
                    point("exclamationmark.triangle.fill", String(localized: "Watch where you step: there may be holes and open manholes."))
                ]),
                KnowledgeSection(heading: after, symbol: "checkmark.circle.fill", points: [
                    point("house.fill", String(localized: "Go back home only when the authorities say so.")),
                    point("wrench.and.screwdriver.fill", String(localized: "Have gas and electricity checked before switching them back on.")),
                    point("road.lanes", String(localized: "Do not walk or drive on flooded roads.")),
                    point("spigot.fill", String(localized: "Do not drink tap water until your municipality allows it. Throw away food that touched the flood water."))
                ])
            ]),

        KnowledgeArticle(
            id: "tsunami.what-to-do", category: .tsunami,
            title: String(localized: "Tsunami: what to do"),
            summary: String(localized: "The warning signs of a tsunami and how to reach safety on the coast or at sea."),
            sections: [
                KnowledgeSection(heading: String(localized: "Warning signs"), symbol: "eye.fill", points: [
                    point("bell.fill", String(localized: "An official alert message.")),
                    point("waveform", String(localized: "A strong earthquake felt on the coast.")),
                    point("water.waves", String(localized: "The sea suddenly drawing back, a large wave or a deep, growing roar from the sea."))
                ]),
                KnowledgeSection(heading: before, symbol: "calendar.badge.clock", points: [
                    point("map.fill", String(localized: "If you live or stay in an area at risk, learn the escape routes and waiting areas of the municipality.")),
                    point("person.3.fill", String(localized: "Agree with your family where to meet."))
                ]),
                KnowledgeSection(heading: String(localized: "During"), symbol: "exclamationmark.triangle.fill", points: [
                    point("mountain.2.fill", String(localized: "Move straight away to the nearest high place: a hill or the upper floors of a building.")),
                    point("megaphone.fill", String(localized: "Warn the people around you.")),
                    point("car.fill", String(localized: "Do not use the car: it can become a trap.")),
                    point("sailboat.fill", String(localized: "On a boat, keep listening to the radio. If you are at sea, head out to open water. If you are in port, leave the boat and go to high ground."))
                ]),
                KnowledgeSection(heading: after, symbol: "checkmark.circle.fill", points: [
                    point("hand.raised.fill", String(localized: "Stay where you are: more waves, even stronger ones, may arrive.")),
                    point("person.badge.shield.checkmark.fill", String(localized: "Follow the instructions of the authorities.")),
                    point("spigot.fill", String(localized: "Do not drink tap water and do not eat food touched by sea water.")),
                    point("house.fill", String(localized: "Do not go back into your home until you are allowed to."))
                ])
            ]),

        KnowledgeArticle(
            id: "preparedness.kit", category: .preparedness,
            title: String(localized: "Emergency kit"),
            summary: String(localized: "What to keep ready at home for any emergency."),
            sections: [
                KnowledgeSection(heading: String(localized: "What to keep ready"), symbol: "backpack.fill", points: [
                    point("doc.fill", String(localized: "Copies of your documents.")),
                    point("cross.case.fill", String(localized: "A first aid kit and your personal medicines.")),
                    point("flashlight.on.fill", String(localized: "A torch and a battery radio.")),
                    point("takeoutbag.and.cup.and.straw.fill", String(localized: "Supplies of water and food."))
                ]),
                KnowledgeSection(heading: String(localized: "Plan ahead"), symbol: "map.fill", points: [
                    point("mappin.and.ellipse", String(localized: "Read your municipality's civil protection plan and find the nearest waiting area.")),
                    point("figure.roll", String(localized: "Tell your municipality if someone in your family needs special assistance.")),
                    point("person.3.fill", String(localized: "Agree with your family on a plan to reach escape routes and waiting areas."))
                ])
            ])
    ]
}
