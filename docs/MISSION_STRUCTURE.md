# Mission structure and campaign progression

Status: confirmed product rules with explicit remaining design questions. No gameplay is implemented.

## Setting and map

Working setting: Latvia around 1946. Region and exact settlement remain open. Start with one handcrafted map; a Latvian town/city is an example. Supplies and selected portions vary randomly between outings. This does not commit to a fully procedural city: the degree of variation is undecided. Candidate approaches include authored alternate interiors, blocked routes, or modular areas, to be evaluated rather than treated as requirements.

Generate each session's variation once under host authority. Reconnecting must return to the same world, loot, and time state.

## Quests, returns, and survival are separate

Players may leave early with carried supplies and rescued civilians even if they have not completed the main objective. Returning alive does not itself complete a quest. Incomplete quests do not advance the main chain or grant completion rewards. Whether sub-objective progress persists across attempts, and what counts as completing/turning in an objective, remain open.

Main-quest completion unlocks more missions and provides construction-material rewards. The long-term goal for now is developing the camp and resisting; no final ending is specified. Reward amounts, replay rules, upgrade dependencies, and additional equipment/location unlocks remain to be designed.

Optional scavenging outings allow recovery when the group lacks supplies for main missions. Scavenging is an activity on the mission map, not approval for a separate faction, free random loadout, PvP mode, or automatic supply grant.

## Outcomes

| Event | Confirmed result |
|---|---|
| Early safe return with objective incomplete | Preserve safely returned supplies and secure rescued civilians; main quest remains incomplete |
| Main quest completed | Advance the relevant chain and award its construction materials under the eventual completion/turn-in rule |
| Individual mission death | Return that player to camp; carried gear stays behind; no same-mission redeployment; survivors continue |
| Rescuer dies, teammates safely return | Teammates can still secure the group's pending recruits |
| Solo/total-group mission death | Pending recruits are lost or die en route; carried gear is not brought home |
| Mission deadline expires | Fail the outing; players still on the map suffer mission death, losing carried gear and pending civilians |
| Non-host disconnect | Character remains present and vulnerable; reconnect can restore control if alive |
| Host crash | End the outing; restore the entire campaign to the pre-mission baseline, as if the outing never happened |

Existing camp residents are unaffected by an ordinary pending-recruit loss, but can separately die from camp shortages. A crash rollback also restores their pre-mission state.

## Deadline and returns

Outings last a maximum of one hour. Deadline expiry is confirmed as mission death for players still on the map, not a safe automatic return. Exact clock basis, shorter mission limits, warning schedule, exit interaction, and how to resolve return/death at the deadline need implementation rules.

Players who already returned safely are not still on-map and must not be killed by a later timeout. How shared civilian arrivals and quest outcomes commit when players leave at different times, especially when others later time out, must be settled explicitly. Do not silently erase secured returns or award pending arrivals twice.

## Disconnection and hosting

Non-host disconnection is not a safe exit. The same character remains in the mission until killed or otherwise normally resolved. Reconnecting resumes that living character; death lockout still applies if they died while disconnected. Uncontrolled posture/behavior, grace periods if any, authenticated identity, and intentional quit behavior remain to design. Host-character death is separate and does not stop the session.

First pass: a host crash ends the mission and rolls back every player and the entire campaign, including concurrent camp building, cooking, material use, resident state, rewards, and mission outcomes, to before deployment. Earlier safe returns within that running outing are also undone by a crash rollback. Save a consistent durable baseline before mission side effects begin.

Intentional shutdown, crash detection, and commit-boundary behavior still need specification. Later dedicated-server support is a confirmed goal, inspired by the owner's Valheim reference; hosting/security/deployment operations are not part of the first prototype.

## Camp economy and recovery

Civilians construct, cook, and perform similar jobs; players may assist as foremen. Some residents can be ordinary NPCs rather than workers. Main-mission rewards supply construction materials, with quantities and additional sources undecided.

Shortages can kill civilians and leave the group unable to prepare for main-quest outings. There is no permanent campaign game-over. Optional scavenging must allow recovery, including a viable design for having no workers or almost no equipment. Exact minimum loadout, civilian-needs rates, warnings, and deployment gates remain open; do not invent free supplies or a hard soft-lock.

A medical facility unlocks after a handful of completed main missions and speeds healing. Exact duration, unlock count, and recovery multiplier are intentionally deferred.

## Mission framework (implemented, 2026-11-02)

Every mission uses the same pieces, so a new mission is content plus map markers, never new screens:

- **Definition** (`missions/<id>.tres`, `scripts/missions/mission_definition.gd`): title, briefing, objectives (`mission_objective.gd`; kind `carry_out` so far), exit time, and time limit (default one hour; time running out is mission death for anyone still in the area).
- **Map markers**: `ObjectiveSpot` (a tag; the mission places each objective item at a random spot with its tag) and `MissionExit` (an exit area with posts and a sign).
- **Rules** (`mission_run.gd`, no scene nodes): one record per participant, up to four. Each ends individually: extracted, killed, or timed out. A `carry_out` objective is done when someone extracts carrying the item; a fallen carrier leaves it on the body. Whole-mission outcome: success (required objectives carried out), returned (someone got out without them), failed (nobody got out). Missions can add counters (`count("Enemies killed")`).
- **Report** (`mission_report.gd`): one shape for every mission and outcome: title, headline, and sections Objectives / Outing / Equipment / Condition of label-value rows.
- **Presentation**: `MissionController` (one node per map) drives the rules for the mission players and shows the shared objective HUD (`ui/missions/mission_hud.gd`) and summary screen (`ui/missions/mission_summary_screen.gd`) to the local player.

**Regions (2026-11-02, owner direction "selecting different regions and doing missions. Kind of like how tarkov works").** The mission map offers regions (`MissionRegion`: world scene, time limit, exit names, standing enemy population, board position, and its missions), as a raid shooter offers locations. The player picks a region, ticks any of its open missions (several per outing, owner choice), or none for a scavenging outing, and deploys. `MissionRegion.compose()` merges the region's rules with the ticked missions' objectives and extra enemies into one `MissionDefinition`, so `MissionRun`, the HUD and the summary are unchanged. The summary adds a Missions section; each mission is recorded separately (completed if its objectives were carried out). A completed mission is no longer offered for the rest of the game run; there is no campaign save yet. A mission's own time limit and scene are ignored inside a region; a standalone definition (the combat arena) still plays directly.

**From the camp (2026-11-02, owner direction: connect from the camp, no main-menu changes).** The camp's HQ station (camp test scene, reached through Training) is the mission-planning table: it opens the mission map or the combat arena. The map has Back to camp; an outing's summary and the arena's summary return to camp. `MissionLaunch.camp_scene` remembers the scene to return to; when that is the startup scene, the return sets the startup route to `training` so it lands in the camp rather than the main menu. The camp reloads on return, so its session-only work (stock, jobs, residents) does not carry over yet; that needs the campaign save. Opened on their own, the map and arena behave as before.

**Characters and worlds (2026-11-02, owner direction: "selecting a character ... a server you are joining. Kind of like how valheim works. What's on your character is persisted. The camp is also persisted").** Main menu Play opens character selection (create with a name; placeholder silhouette while character art is frozen), then world selection (create or join). A character file (`user://saves/characters/`) holds the name and what the character carries and wears, and goes into any world (owner choice: gear travels with the character). A world file (`user://saves/worlds/`) holds the camp (stores, residents, plans, shelter, trench, test patient) and mission results. `scripts/state/save_store.gd` reads and writes them; `scripts/state/game_session.gd` holds the playing character and world across scenes. Saves happen when the camp is left (to the menu, the mission map or the arena), every 30 s in camp, and when an outing ends: extraction keeps carried gear (objective items are handed in), mission death or timeout loses it and the character returns with the standard kit (placeholder until camp issue of weapons exists). Saving at deployment and at the outing's end means a crash mid-outing leaves both files as before deployment. Jobs in progress are not saved; their reserved supplies return to the stores. Training is a sandbox and saves nothing; the combat arena does not change the character. Worlds are local; joining over the network comes with the two-instance networking work.

**Rewards (2026-11-02).** A mission's `rewards` (camp stock id -> amount) are paid into the world's camp stores the first time it is completed; the mission map shows them under the briefing and the summary names them. Amounts are placeholders.

**Money (2026-11-02, owner request "We need currency, rubles and lats").** Rubles and lats are carried items (`SupplyCatalog` entries with `money`, amount in `uses`): never used like supplies, lost on the body at death, kept in the character's save otherwise. The camp quartermaster deposits carried money into the treasury (camp stock `rubles`/`lats`, saved with the world). The camp contact sells medicine, cartridges, parts, cloth and food at fixed prices (`CampRuntime.PRICES`) in rubles or lats; goods go to the communal stores. Money comes from mission rewards, a bundle of rubles (and often a few lats) hidden at a free objective spot in each region, and a few rubles on enemy bodies. Historical basis: the Soviet ruble replaced the lats on 25 March 1941 and was the only legal tender ([Bank of Latvia](https://www.bank.lv/en/component/content/article/562-about-the-bank-of-latvia/2611-the-national-currency-of-latvia)); lats as hidden savings valued by locals is a game premise, not a researched claim. Amounts and prices are placeholders. The camp cash chest (`scripts/camp/cash_chest.gd`, beside the quartermaster) is the treasury as a container: F opens it beside the carried inventory, money is dragged or ctrl-clicked in and out, and its totals are the treasury (owner request "a chest that's like an inventory of cash"). Bribes are planned, not built.

To add a mission: write a definition `.tres` (title, briefing, objectives, `area_name`, `rewards`, and the `enemy_groups` it adds per `EnemySpawn` tag) and add it to its region's `missions`. Make sure the region's world has at least two `ObjectiveSpot` markers with the objective's tag and the `EnemySpawn` tags the mission asks for. To add a region: write a `MissionRegion` `.tres`, add it to `missions/catalog.tres`, and build its world as a subclass of `scripts/missions/region_world.gd` that lays out the map in `_build_map()` from the environment library, with objective spots, enemy posts and `MissionExit` markers matching `exit_names`.

**Mission map and first mission world (2026-11-02, owner request "a basic mission scene world. A map to choose missions").** `scenes/missions/mission_board.tscn` is the mission map: a paper district map with one pin per catalog mission, a briefing (place, objective, time limit, a rough resistance level, last result) and Deploy. `scenes/missions/mission_world.tscn` is a district (forest edge, farmstead and barn, three cottages, a road checkpoint, west and south exits) built from the environment library: pine/spruce/birch, deadwood, boulders, ferns, grass and litter, crates and the moss ground material, with the training forest's trunk and deadwood colliders. The library has no buildings, sandbags or roads yet, so walls, fences and the barrier are plain shapes in the library's weathered wood, and there is no road surface. It plays whichever outing `MissionLaunch` hands it, posts enemies at its tagged spawns, and returns to the mission map after the summary. Three fictional missions use it: the courier's dispatch (farm), medicine for the camp (village) and the checkpoint codebook. Results last for one run of the game; there is no campaign save. Open the mission map directly for now: linking it to the main menu (another agent's work) and the camp's planning table needs owner direction. `scenes/missions/forest_world.tscn` (Deep forest region) is the second region: close forest, a forester's hut, an old dug-in bunker and an open bog of snags and boulders, with a north trail and a logging-track exit, and two fictional missions (the forester's map; rations for the winter). Not built yet: other objective kinds (rescue, reach, destroy), camp-side rewards, persistence, and network authority for who holds an item.

## Questions still requiring decisions

- Physical exit locations, exit requirements, and whether players can return independently.
- When returned supplies/recruits become usable during staggered co-op returns.
- Partial quest progress, required return/turn-in items, and objective completion if a player later dies or times out.
- Which authored map portions vary, and whether new outings reset all supplies.
- Civilian work assignment and player assistance behavior.
- Shortage warnings, population consumption, and how an almost empty camp can recover.
- Clock behavior, planning/pause rules, and intentional host shutdown.
- Concrete combat and enemy-perception rules: see [combat design](COMBAT_DESIGN.md).
