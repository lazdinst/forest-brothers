# Missions, casualties, and medicine

Status: confirmed mission rules with proposed medical mechanics. This is game design, not a medical treatment guide. Numerical values and exact item requirements are intentionally unset.

## Confirmed by the owner — 2026-11-01

- Players go on missions from camp, alone or in co-op with a maximum of four players.
- Death ends that player's participation in the mission and sends them back to camp.
- Surviving friends can continue; one death does not fail or end the mission for everyone.
- Incapacitation includes a limited bleed-out window during which teammates can revive the player.
- There should be multiple meaningful medical resources, including treatment for light/heavy bleeding, broken limbs, and morphine, fitting the historical period.
- Starting rule: carried equipment stays on the body after death for teammate recovery; camp-stored supplies remain safe. Recovery ownership and body persistence are undecided.
- Dead players cannot rejoin that same mission. They can organize equipment, build, dig trenches, cook, collect water, repair weapons, and perform other confirmed camp tasks while friends continue.
- Solo incapacitation or all remaining mission players becoming incapacitated resolves as mission death and return to camp. No AI or self-revival exception is approved.
- Revival preserves injuries and reduced capability for a duration. Timings, penalty strength, and treatment interactions remain undecided.

These are mission-level death rules, not a confirmed permanent character-death system. Returning to camp is a gameplay rule; its narrative explanation is unresolved.

## Proposed player flow

`At camp -> On mission -> Incapacitated -> Revived on mission OR Dead for this mission -> At camp`

A successful return also leads from mission to camp. Revived characters retain injuries and temporarily reduced capability and may be incapacitated again. Death is final for that mission; a late medical action cannot reverse it, and the player cannot re-enter until a later outing. Track mission identity so reconnecting cannot bypass this rule.

Separate the player's condition from the group's mission status. Mission completion can still be achieved by survivors after another player has returned to camp. Do not automatically launch a new group mission or reset the current one when an individual returns.

Proposed first implementation: use a readable countdown or equivalent clear indicator for the rescue window. Bleeding severity should influence urgency, but the deadline, extension rules, instant-fatal damage exceptions, and whether treatment pauses deterioration require design decisions and playtests.

## Treatment philosophy — proposed

Make medical choices understandable: identify the problem, use an appropriate resource, and see what improved. Avoid a single item that cures every injury. A finite rescue window is a game abstraction, not a claim about how real casualties recover.

Distinguish three outcomes:
1. **Stabilization:** control an immediate deterioration, such as bleeding.
2. **Revival:** regain the ability to participate, once the game's rescue conditions are met.
3. **Recovery:** restore capability over a duration while injuries persist after revival. Camp care, treatment acceleration, and timer behavior remain proposals to settle.

These need not be three separate interaction buttons. The important rule is that standing up does not silently cure every injury. Exact prerequisites and whether some conditions can be combined into one treatment action are open.

## Candidate conditions and resources

All effects below are proposed gameplay abstractions. Specific item origins and local availability need further research.

| Condition | Intended gameplay consequence | Candidate resource | Proposed limit |
|---|---|---|---|
| Light bleeding | Gradual deterioration that competes with the mission objective | Cloth bandage or field dressing | Controls the bleed; does not restore lost blood or cure a fracture |
| Heavy bleeding | Faster deterioration and a more urgent rescue situation | More substantial dressing; period-appropriate tourniquet as a separate research candidate | Requires an appropriate treatment; modern tactical products are not default assets |
| Broken limb | Leg mobility or arm/weapon-handling penalties | Splint and securing bandages | Stabilizes function; does not instantly heal the bone |
| Pain | Impaired movement, steadiness, or perception | Morphine, presented in a researched period format | Temporary symptom relief; not a bleed cure, fracture repair, or automatic revival item |
| Blood loss / severe trauma | Reduced capability after bleeding is controlled | Camp rest/care; advanced supplies only if researched and approved | Revival does not automatically restore full condition |
| Infection risk, if later approved | A reason for ongoing care rather than an immediate combat status | Period antiseptic or sulfonamide candidate | Deferred; these are not instant healing or revival resources |

The owner wants varied treatment resources; the final inventory, classifications, durations, side effects, and resource costs have not been approved. Avoid implementing infection, transfusion, detailed physiology, or a full medical simulation merely because a historical item exists.

## Historical basis and limits

Museum evidence establishes that morphine, bandages, splints, and other medical supplies existed in WWII-era military medicine. It does not establish that a Latvian forest group had reliable access to the same kits.

- [DEA Museum: Morphine Syrette](https://museum.dea.gov/museum-collection/collection-spotlight/artifact/morphine-syrette) documents American wartime morphine syrettes. This supports period existence, not local supply or American packaging for Latvian partisans.
- [Canadian War Museum: Morphine Syringe](https://www.warmuseum.ca/collections/artifact/1338023/) catalogs a WWII-era morphine syringe. Research local provenance before selecting the game's delivery device.
- [National Museum of the Pacific War: Medicine on the Frontlines](https://www.pacificwarmuseum.org/learn/articles/medicine-on-the-frontlines) describes wartime dressings, morphine, wire splints, sulfonamide supplies, and stabilization before evacuation. This is an Allied comparator, not a Latvian supply inventory.

Further research should focus on Soviet, German, and Latvian civilian medical equipment, local sourcing, terminology, and the selected year/region. Treat rare medicines as candidate scavenged, traded, or supplied resources only after their provenance makes sense. Do not assume a modern injector, branded trauma dressing, modern hemostatic product, or surgical repair kit belongs in the period.

No specific tourniquet design, antibiotic access, or field blood-replacement system is approved. Describe mechanics through fictional game effects rather than real dosages or treatment procedures.

## Co-op behavior and verification

- A downed player remains part of the active mission during the rescue window.
- A teammate's treatment consumes validated resources and produces a shared result. Exact treatment steps and resource ownership remain open.
- Dying returns only the affected player to camp. Survivors keep their current state and objectives.
- If the host's character dies, the network session continues. Host process disconnection is a separate technical problem.
- Two or more simultaneous casualties must resolve per player. Do not use one global dead/downed flag.
- Test treatment interrupted by movement, damage, disconnect, target death, and resource loss. Decide which events actually cancel it before implementing that behavior.
- Test four participants, including one at camp while others remain on mission, and two rescuers attempting to treat the same casualty.
- Preserve carried equipment on a recoverable body under the starting rule; keep camp storage safe. Resolve solo/all-incapacitated players as mission deaths. Group rewards, body lifetime, recovered-item ownership, and recovery timing still need explicit rules. Do not invent transfers or rewards.

## Open design questions

1. How long is the rescue window, and can stabilization extend or pause it?
2. Which injuries cause incapacitation, and can any damage bypass the rescue window?
3. What conditions and supplies are required to revive, and how long do preserved injuries and reduced capability last?
4. How are simultaneous casualties resolved consistently, given that solo/all-incapacitated outcomes are confirmed as mission death?
5. Who owns recovered gear, how long do bodies remain, and what happens to uncollected gear when the mission ends?
6. How should reconnecting and saved mission results preserve the confirmed same-mission death lockout?
7. How do injury penalties affect the confirmed camp activities? Is optional spectating also desirable?
8. What recovery, cost, or delay applies at camp, and how is return after death explained?
9. How do mission completion and rewards affect players who died earlier?
10. Which exact historical year and sources establish the medical item list and packaging?
