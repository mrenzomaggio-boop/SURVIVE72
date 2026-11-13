import Foundation

/// First aid cards of SURVIVE MEDICAL, written in plain words by SURVIVE 72
/// following the European Resuscitation Council 2025 guidelines (Italian
/// edition by IRC). Not yet reviewed by a doctor: every card shows that
/// warning, the 112 line and the disclaimer.
enum MedicalLibraryContent {
    private static let call112 = MedicalStep(symbol: "phone.fill", text: String(localized: "Call 112."))

    private static func step(_ symbol: String, _ text: String) -> MedicalStep {
        MedicalStep(symbol: symbol, text: text)
    }

    static let entries: [MedicalEntry] = [
        MedicalEntry(
            id: "medical.cardiac-arrest", category: .lifeThreatening,
            title: String(localized: "Not responding and not breathing"),
            summary: String(localized: "Cardiac arrest: call 112, push hard and fast on the chest, use a defibrillator."),
            steps: [
                step("exclamationmark.shield.fill", String(localized: "Make sure the place is safe for you.")),
                step("person.wave.2.fill", String(localized: "Gently shake the person and call them loudly.")),
                step("phone.fill", String(localized: "If they do not respond and are not breathing normally, call 112 with the speaker on.")),
                step("bolt.heart.fill", String(localized: "Ask someone to bring a defibrillator (AED).")),
                step("hand.point.down.fill", String(localized: "Start chest compressions at once: in the centre of the chest, push hard (5-6 cm) and fast (100-120 per minute).")),
                step("lungs.fill", String(localized: "If you are trained, give 30 compressions and 2 rescue breaths. Otherwise give compressions only, without stopping.")),
                step("speaker.wave.3.fill", String(localized: "When the AED arrives, switch it on and follow the voice."))
            ],
            keywords: [String(localized: "CPR"), String(localized: "heart"), String(localized: "AED"),
                       String(localized: "resuscitation"), String(localized: "unconscious")],
            showsCompressionRhythm: true),
        MedicalEntry(
            id: "medical.choking", category: .lifeThreatening,
            title: String(localized: "Choking (adult)"),
            summary: String(localized: "Something is blocking the airway: back blows and abdominal thrusts."),
            steps: [
                step("lungs.fill", String(localized: "If the person can cough, encourage them to keep coughing.")),
                step("hand.raised.fill", String(localized: "If they can no longer cough or breathe, give 5 blows between the shoulder blades, then 5 abdominal thrusts (Heimlich manoeuvre). Keep alternating.")),
                step("phone.fill", String(localized: "If they become unconscious, call 112 and start resuscitation.")),
                step("stethoscope", String(localized: "Even if it clears, have the person checked by a doctor."))
            ],
            keywords: [String(localized: "airway"), String(localized: "Heimlich"), String(localized: "food")]),
        MedicalEntry(
            id: "medical.recovery-position", category: .lifeThreatening,
            title: String(localized: "Unconscious but breathing"),
            summary: String(localized: "Put the person on their side in the recovery position and keep checking their breathing."),
            steps: [
                step("rotate.right.fill", String(localized: "Put the person in the recovery position: on their side, head slightly tilted back.")),
                call112,
                step("lungs.fill", String(localized: "Keep checking that they are breathing until help arrives."))
            ],
            keywords: [String(localized: "recovery position"), String(localized: "fainted"), String(localized: "unconscious")]),
        MedicalEntry(
            id: "medical.bleeding", category: .injuries,
            title: String(localized: "Severe bleeding"),
            summary: String(localized: "Press hard on the wound. On an arm or leg, use a tourniquet if the bleeding does not stop."),
            steps: [
                step("hand.raised.fill", String(localized: "Press hard and directly on the wound with your hands or a clean cloth.")),
                step("bandage.fill", String(localized: "Put a dressing or cloth on it and keep pressing.")),
                step("clock.fill", String(localized: "If the bleeding does not stop and the wound is on an arm or leg, apply a tourniquet as soon as possible, above the wound, and write down the time.")),
                call112
            ],
            keywords: [String(localized: "blood"), String(localized: "wound"), String(localized: "tourniquet")]),
        MedicalEntry(
            id: "medical.burns", category: .injuries,
            title: String(localized: "Burns"),
            summary: String(localized: "Cool the burn with running water and cover it with something clean."),
            steps: [
                step("drop.fill", String(localized: "Cool the area straight away with cool running water (not ice) for at least 20 minutes.")),
                step("applewatch", String(localized: "Remove rings and watches before it swells.")),
                step("bandage.fill", String(localized: "Cover with cling film or a clean cloth. Do not apply creams, oil or butter.")),
                step("phone.fill", String(localized: "For large burns, burns on the face or burns on children, call 112."))
            ],
            keywords: [String(localized: "burn"), String(localized: "fire"), String(localized: "skin")]),
        MedicalEntry(
            id: "medical.heatstroke", category: .environment,
            title: String(localized: "Heatstroke"),
            summary: String(localized: "Move the person somewhere cool and cool them down quickly."),
            steps: [
                step("beach.umbrella.fill", String(localized: "Move the person into the shade or somewhere cool and remove excess clothing.")),
                step("drop.fill", String(localized: "Cool them down at once: if possible, immerse them in cool or cold water up to the neck. Otherwise wet their skin and fan them.")),
                step("phone.fill", String(localized: "Call 112 if they are confused or not responding well."))
            ],
            keywords: [String(localized: "heat"), String(localized: "sun"), String(localized: "temperature")]),
        MedicalEntry(
            id: "medical.hypothermia", category: .environment,
            title: String(localized: "Hypothermia"),
            summary: String(localized: "Protect the person from wind and cold and replace wet clothes with dry ones."),
            steps: [
                step("wind", String(localized: "Move the person out of the wind.")),
                step("tshirt.fill", String(localized: "Remove wet clothes and cover them with dry blankets, insulating them from the ground too.")),
                call112
            ],
            keywords: [String(localized: "cold"), String(localized: "winter"), String(localized: "temperature")]),
        MedicalEntry(
            id: "medical.stroke", category: .illness,
            title: String(localized: "Stroke"),
            summary: String(localized: "Recognise it with FAST and call 112 at once."),
            steps: [
                step("face.smiling", String(localized: "Face: one side of the face droops.")),
                step("figure.arms.open", String(localized: "Arm: one arm is weak or cannot be lifted.")),
                step("bubble.left.fill", String(localized: "Speech: words are slurred or confused.")),
                step("clock.fill", String(localized: "Time: call 112 at once and note the time the symptoms started."))
            ],
            keywords: [String(localized: "FAST"), String(localized: "brain"), String(localized: "speech")]),
        MedicalEntry(
            id: "medical.anaphylaxis", category: .illness,
            title: String(localized: "Severe allergic reaction"),
            summary: String(localized: "Anaphylaxis: call 112 and help the person use their adrenaline pen."),
            steps: [
                step("allergens", String(localized: "Signs: swollen lips or throat, difficulty breathing, widespread hives, hoarse voice.")),
                call112,
                step("syringe.fill", String(localized: "If the person has their own adrenaline pen, help them use it."))
            ],
            keywords: [String(localized: "allergy"), String(localized: "anaphylaxis"), String(localized: "adrenaline")])
    ]

    static let ids: Set<String> = Set(entries.map(\.id))
}
