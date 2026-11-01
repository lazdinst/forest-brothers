# Technical direction

Status: proposed foundation, not an implemented architecture. The repository currently contains documentation only.

## Engine and platform

Proposed: Godot standard edition, GDScript, and the Compatibility renderer for an initial Windows PC prototype. Steam is the intended distribution destination. Choose and record a stable engine version before creating the project; do not silently depend on the latest release or unstable documentation.

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

Proposed initial constraints: friends join at camp before a mission; the host owns the save; leaving the host ends the session. The co-op maximum is four players. Reconnect behavior, character ownership, and detailed revival rules still need decisions before implementation depends on them. Host character death is a gameplay event and must never be treated as the host leaving.

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
- A player's death resolves only their participation and locks them out of that mission ID. Solo/all-incapacitated cases resolve as mission death. Keep reconnect identity and mission outcomes authoritative; group rewards and crash recovery remain unresolved.
- Validate host-character death with survivors continuing, not only a non-host dying. Test the intended four-player capacity; early two-player tests are insufficient to claim full co-op support.

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
- Civilian labor is a proposal. Do not implement autonomous harvesting, worker pathfinding, or a broad job simulation before its role and prototype scope are approved.
- Test the same buildings from first-person and the planning camera. A sprite that looks correct from the player camera may fail in a city-builder view; rendering choices remain open.

## Civilian recruitment and pending arrivals

- Keep confirmed camp residents separate from civilians pending arrival on a mission. A civilian departing the mission is not yet a resident or available worker.
- Track civilian and mission identities so repeated rescue interactions, multiple players, reconnects, or repeated result processing cannot award the same recruit twice.
- Initialize one civilian resident, separately from human player membership. Do not invent the initial civilian's combat or labor capabilities.
- Resolve pending arrivals through authoritative group mission results. Solo/total-group mission death loses pending recruits. Surviving teammates can secure arrival even if the rescuer dies; do not attach recruitment validity to the rescuer's alive/dead state.
- Distinguish lost pending recruits from existing residents. Do not clear established population because someone dies on a mission.
- A short visible departure path followed by result-driven arrival is a proposed prototype; a simulated cross-map civilian journey is not required by the current design.
- Persist enough mission/result state to avoid duplicate or premature arrivals when saving/loading is introduced. Crash/reconnect resolution remains an open policy, not an automatic loss or success.

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

No executable project or automated checks exist yet. When the prototype is created, record the exact engine version, import/run/export commands, and manual playtest steps.

Use focused tests for important rules such as inventory ownership, duplicate pickup prevention, mission completion, and save restoration. Use running game instances to verify networking and visual playtests for first-person movement, sprite readability, and UI. Record what was actually tested and any limitations.
