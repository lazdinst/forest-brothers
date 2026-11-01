# Technical direction

Status: initial Godot movement/interaction prototype exists. Networking, campaign architecture, and later systems below remain design guidance, not implemented features. See `GETTING_STARTED.md` for the executable scope and verification commands.

## Engine and platform

Selected initial toolchain: Godot 4.7.2 standard, GDScript, Compatibility renderer, Windows PC. Steam remains the intended distribution destination. Keep this version explicit; evaluate upgrades deliberately rather than silently following the latest release.

Use simple 3D environments and prototype sprite characters. Validate readability, editor usability, and performance on the owner's machine before increasing visual scope.

## Solo and multiplayer

Recommended starting model: a host runs the campaign and authoritative world simulation. Solo uses the same gameplay rules with one local player; it must work offline. Supporting this does not require a separate server process for solo play.

- Clients request actions; the host validates shared changes such as pickups, damage, doors, mission results, and camp supplies.
- Separate input and camera/UI presentation from game rules. Each player has an identity and their own character/inventory state.
- Avoid hard-coded player-one references in shared systems.
- Keep enemy decisions and shared campaign progression under host authority.
- Introduce stable IDs where items, players, or world objects must survive save/load or be referenced across the network.
- Plan movement replication and responsiveness explicitly. Generic property synchronization alone does not solve shooter latency or perceived input delay.
- Test two clients competing for the same pickup, disconnecting, and observing the same mission result.

First-pass host crash ends the outing and restores the entire campaign to pre-mission data, including concurrent camp work. Non-host disconnection leaves the character in the mission and vulnerable; reconnect restores the same surviving character. Host-character death is a gameplay event and must never terminate hosting. Proposed initial constraints: friends join at camp before deployment and the host holds the save. Intentional host shutdown and late join remain open. Dedicated-server support is a confirmed later goal; the co-op cap remains four.

Godot references, to re-check against the selected version:
- [High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [MultiplayerSpawner](https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html)
- [MultiplayerSynchronizer](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html)

Steam invitations, lobbies, and networking transport integration are later work. Local two-instance testing does not prove internet connectivity. Verify any Steam integration dependency and its license before selecting it.

## Mission participation and injury state

Confirmed rules and proposed treatment design are in [missions and medicine](MISSIONS_AND_MEDICINE.md).

- Keep session membership, per-player mission participation, character condition, and group mission status separate. One character dying does not end the mission or disconnect that player.
- Support an interactive camp and an active mission concurrently within the same session. Camp-side players can build, cook, collect water, organize equipment, and repair weapons while survivors continue. Do not use a global scene transition that pulls survivors back to camp. Whether these are separate loaded maps or another layout is not chosen.
- The host remains authoritative even when their own character is incapacitated, dead, or at camp. Actual host disconnection remains a separate session-lifetime limitation.
- Represent wounds separately from consciousness/mobility. Revived does not imply all bleeding, fractures, pain, or blood loss are cleared.
- Authoritative logic owns bleed-out deadlines, treatment completion, resource consumption, death, and mission results. Clients display those outcomes; they do not independently decide death from a local timer.
- Treatment actions must validate the target, active mission, item availability, range, and current condition. Interruption, duplicated requests, and concurrent treatment must not duplicate items, revive a dead character, or apply a completed treatment twice.
- Resolve the race between death and treatment completion explicitly, and test it. Disconnecting must not silently reset wounds or revive timers.
- A player's death resolves only their participation and locks them out of that mission ID. Solo/all-incapacitated cases resolve as mission death. Keep reconnect identity and mission outcomes authoritative; exact quest reward/commit conditions remain unresolved; the full-campaign host-crash rollback policy is confirmed.
- Validate host-character death with survivors continuing, not only a non-host dying. Test the intended four-player capacity; early two-player tests are insufficient to claim full co-op support.

## Combat state and ammunition consistency

See [combat design](COMBAT_DESIGN.md) for confirmed behavior and open balance.

- Separate loose-ammunition stock from identifiable magazines and their contents. Moving cartridges into a magazine transfers quantities; it does not create ammunition. Retain partial-magazine state across inventory transfers, death/body recovery, reconnects, and saves.
- Authoritative rules validate loading, unloading where supported, reloading, shots, and ammunition consumption. Concurrent actions and interrupted operations must not duplicate or destroy rounds. If chamber state is modeled, include it explicitly in conservation checks; its detail is not yet a product decision.
- Track maintenance state in an agreed representation and make neglected weapons more likely to jam. The host resolves shared jam/fire outcomes; clients must not independently decide incompatible results. Exact formulas and cleaning/service actions are unchosen.
- Friendly-fire hits use the normal injury/incapacitation/death rules; a player-team filter must not silently discard teammate damage. Damage scaling and optional safeguards require decisions.
- Enemy knowledge is based on perceived events and communicated alerts. Breaking sight must not leave enemies with a live player-position feed. Search expiry/escalation thresholds remain balance parameters.
- Full host-crash rollback includes magazine contents, loose cartridges, weapon condition/maintenance, and jam state along with all other campaign state.

## Concurrent camp activity

See [camp and progression](CAMP_AND_PROGRESSION.md) for confirmed scope and proposals.

- Persist built structures, storage contents, water/food stocks, weapon condition, and approved camp changes with stable identities when implemented.
- Camp work must remain authoritative while mission actors are active. Validate shared-resource reservations and completion so two players cannot consume or receive the same materials twice.
- Keep the death lockout independent from player location or equipment: preparing at camp must not enable same-mission deployment.
- Preserve carried inventory on the mission body when returning a dead player to camp; never duplicate that inventory onto the returned character. Recovered equipment is communal; retrieval/deposit and physical access rules remain unresolved.
- Track post-revival penalties explicitly. Timer units, offline progression, treatment acceleration, and which camp actions injuries affect must be decided before implementing those behaviors.
- Support both freely placed pieces and predefined facility sites/upgrades in the construction design. Placement validation and persistence must distinguish placed-piece identity from facility-site identity when implemented. Snapping, supported terrain changes, persistence size, and resource permissions still require deliberate scope choices. Trench digging does not itself require arbitrary terrain deformation.
- Camp and mission time need a coherent shared rule; do not implement a global sleep/time skip that advances or disrupts an active mission without an approved design.

## Communal inventory and construction plans

- All stock is group-owned. Track item location/custody separately from ownership, including camp stores, carried inventories, reservations, and recoverable mission bodies. A stock summary must not itself grant remote access.
- Derive visible totals from the authoritative item/resource state; do not maintain an unrelated editable UI total. Distinguish available, reserved, and physically unavailable quantities under an agreed accounting rule.
- The headquarters mission table and build-planning table are in-world entry points. A player's planning camera/UI must not change everyone else's camera or globally pause an active mission.
- Keep plans separate from completed structures. Plan identity, placement, resource reservation/consumption, cancellation, upgrade state, and completion must be consistent across clients and saved when implemented. Exact reservation and job rules are unresolved.
- Building upgrades must preserve or explicitly migrate container contents and station state; do not replace a building and silently lose or duplicate its stock.
- Civilian construction/cooking and player foreman assistance are confirmed. Begin with a bounded job prototype; do not infer autonomous harvesting, elaborate pathfinding, or a broad economy simulation from these roles.
- Test the same buildings from first-person and the planning camera. A sprite that looks correct from the player camera may fail in a city-builder view; rendering choices remain open.

## Civilian recruitment and pending arrivals

- Keep confirmed camp residents separate from civilians pending arrival on a mission. A civilian departing the mission is not yet a resident or available worker.
- Track civilian and mission identities so repeated rescue interactions, multiple players, reconnects, or repeated result processing cannot award the same recruit twice.
- Initialize one civilian resident, separately from human player membership. Do not invent the initial civilian's combat or labor capabilities.
- Resolve pending arrivals through authoritative group mission results. Solo/total-group mission death loses pending recruits. Surviving teammates can secure arrival even if the rescuer dies; do not attach recruitment validity to the rescuer's alive/dead state.
- Distinguish lost pending recruits from existing residents. Do not clear established population because someone dies on a mission.
- A short visible departure path followed by result-driven arrival is a proposed prototype; a simulated cross-map civilian journey is not required by the current design.
- Persist enough mission/result state to avoid duplicate or premature arrivals when saving/loading is introduced. A host crash rolls these changes back with the entire campaign; a non-host reconnect preserves the existing mission state rather than awarding or cancelling arrivals.

## Mission lifecycle, variation, and rollback

See [mission structure](MISSION_STRUCTURE.md). Keep quest completion, physical returns, pending/secured recruits, per-player life state, and group session status separate.

- The host owns the map instance, variation/loot choices, and deadline. Clients receive the same authoritative instance; they must not roll their own random supplies or reset the timer on reconnect.
- Non-host disconnect preserves the character, wounds, gear, location, and exposure to damage. Rebind the same identity on reconnect if alive; dead players remain locked out. Behavior while uncontrolled still needs a concrete design.
- Before deployment, durably capture a consistent campaign baseline. A host crash restores that baseline for every player and camp subsystem. Uncommitted loot, quest rewards, civilian arrivals, consumed supplies, injuries, building/cooking/work changes must not leak across rollback.
- Keep the baseline separate from the in-progress session and mark when normal resolution commits. Test crashes before/after reward and save boundaries. Snapshot scope is the entire campaign, not only active mission characters.
- Early returns may provisionally affect the running camp, but a later host crash still undoes them. Define finalization and staggered-exit rules explicitly before implementation.
- Future dedicated hosting should run the same rules without depending on a local player/camera/UI. Do not implement infrastructure, accounts, or server operations before their milestone.
- Civilian deaths from shortage are distinct from lost pending recruits and player mission deaths. The no-game-over rule needs a viable scavenging recovery path even when equipment/labor is depleted.

## Content and persistence

- Store reusable definitions for items, weapons, and missions separately from mutable instances when those systems are introduced.
- Give saves a format version from the first persistent prototype. Avoid serializing arbitrary scene trees as the campaign format.
- Save camp resources, mission results, and relevant player state explicitly. Ownership is communal; define physical access, reservation, and spending rules before supporting concurrent resource use.
- Add migration handling when an actual save format changes; do not build a speculative migration framework now.
- Keep saves, credentials, caches, and exports outside tracked source.

## Structure

Do not create empty subsystems for every future feature. Introduce directories as needed, with likely boundaries around player control, interactions, items, missions, camp state, and session/network code. Reusable scenes and small scripts are preferred to one global manager controlling all gameplay.

Keep the root `AGENTS.md` authoritative. Add a nested instruction file only when a directory has real, distinct conventions worth preserving.

## Verification

The movement/interaction prototype and a headless integration check exist. `GETTING_STARTED.md` records engine version, import/run/check commands, manual playtest steps, and limitations. No export configuration, final artwork, or multiplayer implementation exists yet.

Use focused tests for important rules such as inventory ownership, duplicate pickup prevention, mission completion, and save restoration. Use running game instances to verify networking and visual playtests for first-person movement, sprite readability, and UI. Record what was actually tested and any limitations.


## Local training implementation

The player controller now handles stance, a swept head probe for leaning, and bounded vault/mantle motion with landing-clearance checks. Traversal moves the physical body through short swept segments; it must not teleport through blockers. Course fixtures are authored named dimensions in `scripts/prototype/training_course.gd`.

Weapon state (cartridges, magazine contents, timed actions, dirt/jams) is separate from the CanvasLayer presentation/input adapter and ray-hit targets. The adapter is explicitly local, not future network authority. Hits use world-layer collision and ignore sprite clearance volumes. First-person art uses procedural UI motion; no full-body player model exists. A dedicated ADS sprite now anchors its measured front-post tip to the viewport center, matching the camera shot ray across window sizes and lean roll. ADS keeps world FOV fixed; presentation lowers/raises between the hip and sight views. The patrolling civilian is a presentation test, not a job/AI framework.

Regression checks cover round conservation/interruption, scene traversal, roof/lean collision limits, invalid landings, target rays, and walking-frame advancement. Existing pickup/direction/projection checks remain required. See `GETTING_STARTED.md` for commands and limits. A source TODO preserves the deferred close-up sprite problem.

### Muzzle-origin firing and flash

The camera ray selects the aim point only. A second collision ray starts at the sprite muzzle projected 0.85 m ahead of the view and converges on that aim point; tracers begin there. A camera-to-muzzle obstruction check prevents firing beyond near cover when the painted gun overlaps it. This is a local physical approximation until a true 3D weapon socket exists. Normal hit detection still excludes sprite clearance volumes.

A four-cell AtlasTexture animation renders behind the gun at its transformed muzzle anchor. The gun shader adds warm local highlights to existing hip/ADS artwork without changing alpha or alignment, while a short-lived shadowed OmniLight lights nearby geometry. No flash is emitted for rejected/jammed/empty attempts. Muzzle tests cover origin, near cover with an unobstructed camera aim line, hip/ADS attachment, gun/world light expiry, hits, and jams. Visual GPU inspection complements headless checks.
