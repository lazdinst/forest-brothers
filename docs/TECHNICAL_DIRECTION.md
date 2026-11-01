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

Proposed initial constraints: friends join at camp before a mission; the host owns the save; leaving the host ends the session. Player limits, reconnect behavior, character ownership, and death/revival need decisions before implementation depends on them.

Godot references, to re-check against the selected version:
- [High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html)
- [MultiplayerSpawner](https://docs.godotengine.org/en/stable/classes/class_multiplayerspawner.html)
- [MultiplayerSynchronizer](https://docs.godotengine.org/en/stable/classes/class_multiplayersynchronizer.html)

Steam invitations, lobbies, and networking transport integration are later work. Local two-instance testing does not prove internet connectivity. Verify any Steam integration dependency and its license before selecting it.

## Content and persistence

- Store reusable definitions for items, weapons, and missions separately from mutable instances when those systems are introduced.
- Give saves a format version from the first persistent prototype. Avoid serializing arbitrary scene trees as the campaign format.
- Save camp resources, mission results, and relevant player state explicitly. Define ownership before supporting multiple campaign participants.
- Add migration handling when an actual save format changes; do not build a speculative migration framework now.
- Keep saves, credentials, caches, and exports outside tracked source.

## Structure

Do not create empty subsystems for every future feature. Introduce directories as needed, with likely boundaries around player control, interactions, items, missions, camp state, and session/network code. Reusable scenes and small scripts are preferred to one global manager controlling all gameplay.

Keep the root `AGENTS.md` authoritative. Add a nested instruction file only when a directory has real, distinct conventions worth preserving.

## Verification

No executable project or automated checks exist yet. When the prototype is created, record the exact engine version, import/run/export commands, and manual playtest steps.

Use focused tests for important rules such as inventory ownership, duplicate pickup prevention, mission completion, and save restoration. Use running game instances to verify networking and visual playtests for first-person movement, sprite readability, and UI. Record what was actually tested and any limitations.
