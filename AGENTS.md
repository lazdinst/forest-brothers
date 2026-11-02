# Agent instructions — Forest Brothers

## Read first

Before proposing or implementing substantial work, read:
1. `docs/GAME_CONCEPT.md`
2. `docs/DECISIONS.md`
3. `docs/ROADMAP.md`
4. `docs/TECHNICAL_DIRECTION.md` when changing code or technical design.
5. `docs/MISSIONS_AND_MEDICINE.md` and `docs/CAMP_AND_PROGRESSION.md` when changing their systems.

The user's current instructions take precedence. This file applies throughout the repository; nested `AGENTS.md` files add guidance for their directories.

## Current owner priority

Character art development is frozen. Preserve MPFB sources, rig, clips and separate clothing/bodyparts. Keep sprites as the default and MPFB available for comparison; do not create outfits or improve appearance. Read `docs/CHARACTER_FREEZE_AND_COMBAT_SLICE.md` for validated issues and the proposed combat/movement/AI slice. The scope awaits owner review: do not start a major combat, health or navigation refactor. Do not modify the nature/environment or main-menu agents' work. This priority supersedes earlier character-production steps.

## Purpose

Build an immersive, punishing first-person survival game about a small resistance group in postwar Latvia. The player helps local people and supports a concealed forest camp. Tarkov informs tension, vulnerability, and material consequences. The game is not an extraction shooter.

Preserve these user requirements:
- Latvian identity and a Forest Brothers-inspired setting.
- First-person play with a gritty illustrated visual style. The latest owner direction migrates players and NPCs to rigged polygonal 3D meshes; the first procedural blockout was rejected by the owner and normal play uses the preserved sprites until a better replacement passes visual review. Require separate interchangeable garments on a shared rig. Read `docs/MODULAR_CHARACTER_BRIEF.md` before new character production. Read `docs/POLYGON_CHARACTER_PIPELINE.md`.
- Meaningful resource collection, helping locals, and sustaining the hideout.
- Single-player can come first; multiplayer is an intended future capability and must influence early design.
- Support solo play and cooperative missions with a maximum of four players.
- Death ends only that player's mission participation and returns them to camp; surviving teammates continue. Host character death must not end the session.
- Include a limited incapacitation/bleed-out window for teammate revival, distinct injury treatments, light/heavy bleeding, fractures, and period-appropriate medicines including morphine.
- On mission death, carried equipment stays on the body for teammates to recover; camp-stored supplies remain safe under this starting rule. Dead players cannot rejoin that mission.
- Solo incapacitation and total group incapacitation resolve as mission death. Revival preserves injuries and temporarily reduced capability; exact durations remain open.
- Camp is an interactive place: organize equipment, build structures, dig trenches, cook, collect water, store food, repair weapons, and gather/organize ammunition. Returned players can work there while friends continue a mission. See `docs/CAMP_AND_PROGRESSION.md`.
- Construction uses a mixture of freely placed pieces and predefined facility sites/upgrades. Exact piece catalogs, snapping, terrain changes, and upgrade costs are unresolved; do not replace the mixed approach with an exclusively freeform or exclusively fixed system.
- All equipment and supplies are communal, including recovered gear. Carried inventory represents location/custody, not private ownership. Make available quantities easy to inspect; communal ownership does not imply instant remote access.
- Start with a rough tent camp and progressively upgrade buildings. A headquarters tent/bunker contains the mission-planning table; a build-planning table opens a city-builder view for construction plans within the mixed building system.
- Art direction retains the gritty illustrated finish while character presentation migrates to rigged polygon meshes. New meshes are blockouts, not approved final art. Read `docs/ART_DIRECTION.md` and `docs/POLYGON_CHARACTER_PIPELINE.md`; preserve legacy sprite sources and verify skeletons/animation from first-person, all sides and the planning camera. Civilians perform construction/cooking and players can help as foremen; detailed hauling, tree harvesting, and workforce simulation remain unconfirmed.
- Initially the camp has the player and one civilian (an old man is the suggested identity). Rescue civilians on missions, direct them toward camp, and show them running off. They remain pending until mission resolution; successful rescue arrivals then join camp. Solo/total-group mission death loses pending recruits. Surviving teammates can secure arrivals even if the rescuer dies; individual death must not cancel the group's recruits.
- Working year: approximately 1946. Begin with one handcrafted mission map, randomized supplies and selected portions, and a maximum one-hour outing. Timeout is mission death for players still on-map, with carried gear/pending civilian loss.
- Early safe return can secure carried supplies and rescued civilians without completing the main quest. Main-quest completion unlocks further missions and awards construction materials. Optional scavenging outings provide recovery when resources are low; shortages can kill civilians, but there is no permanent campaign game-over.
- Non-host disconnect leaves the character present and vulnerable; reconnect restores control only if still alive. Host crash ends the outing and rolls back the entire campaign, including concurrent camp work, to before deployment. Dedicated-server support is a later goal.
- A medical facility unlocked after a handful of main missions accelerates healing; exact recovery durations and unlock counts are deferred. Read `docs/MISSION_STRUCTURE.md` for mission, failure, and rollback rules; use `docs/COMBAT_DESIGN.md` for confirmed combat behavior and remaining balance choices.
- Combat uses line-of-sight recognition affected by distance/movement/stance, sound-based investigation, last-known-position searching with eventual decay, local alerts, and readable enemy reaction/accuracy limits. Exact thresholds and timings are unchosen.
- Loose cartridges and magazines are separate items; players manually refill magazines and retain partially filled magazines. Reloading must not refill ammunition from an abstract unlimited pool.
- Weapons can jam, with higher jam risk when not cleaned/serviced. Friendly fire can injure/incapacitate teammates under the normal casualty rules. Maintenance costs, jam rates/clearing, damage balance, and ammo-count UI remain open.
- Keep the repository private.

Four-player maximum co-op and individual mission death are confirmed. Do not treat proposed medical item effects, numerical balance, or later engine changes as approved requirements. Check the decision log and `docs/MISSIONS_AND_MEDICINE.md` for their status.

## Scope and design

- Work toward the current roadmap milestone; avoid implementing speculative later systems.
- Prefer one small, complete gameplay loop over broad unfinished features.
- Keep open questions explicit. Make reversible local choices when needed and document consequential assumptions.
- Explain tradeoffs before making changes that commit the project to a new engine, networking model, persistence model, or product direction.
- Keep tension fair and understandable. Do not equate punishment with arbitrary losses or excessive chores.
- Do not turn the game into competitive PvP, an extraction economy, or a live-service product without user direction.

## Technical habits

- Separate player input, authoritative game rules, and presentation. Shared world changes must have a clear owner.
- Read `docs/CAMP_AND_COMBAT_TESTS.md` before expanding the camp/opponent training annex. Reuse the environment pipeline assets, keep communal spending in rules, and do not confuse debug bout vitality/manual rescue results with campaign casualties or multiplayer authority.
- Do not assume there is exactly one player or use a global player reference as the foundation of shared systems.
- When changing weapon rules, art, or animations, read `docs/WEAPON_ANIMATION_WORKFLOW.md`. Keep per-weapon assets/timelines in definitions and ammunition effects in rules; do not award ammo from animation callbacks or assume all weapons use detachable magazines.
- Use stable IDs for persistent entities and content where needed. Keep definitions separate from mutable runtime state.
- Prefer straightforward reusable components over a speculative universal framework.
- Validate co-op with two running instances early, before expanding content. Networking support is not proven by clean-looking interfaces alone.
- Do not select dependencies, engine versions, or third-party assets without checking their current suitability and license.
- Never commit secrets, generated engine caches, export credentials, local saves, or unlicensed assets.
- The local prototype uses Godot 4.7.2 standard and Compatibility. Read `docs/GETTING_STARTED.md` for actual import/run/integration-check commands. Preserve `.gd.uid` files and ignore generated `.godot/` caches. Do not claim headless checks establish graphics, game feel, or multiplayer support.

## Working with other agents

- Inspect the current files and Git status before editing. Preserve other contributors' changes.
- When assigning work, state the goal, files owned, constraints, and a concrete completion check. Delegate only when the user or applicable instructions authorize delegation.
- Keep assignments narrow and avoid simultaneous edits to the same files. Agree on interfaces before dividing tightly coupled work.
- Record durable design decisions in `docs/DECISIONS.md`, not only in chat or an agent handoff.
- Include a short handoff in the completion report: changes, validation, assumptions, and remaining work. Do not claim unrun tests passed.
- Avoid creating redundant agent instruction files or copying the entire concept into every directory.

## Historical and creative care

- Distinguish researched history from fictional people, locations, and events.
- Describe the opposing institutions precisely: Soviet occupation/security forces and relevant collaborators, rather than treating an ethnicity as an enemy category.
- Do not invent historical claims or Latvian translations. Cite research and mark uncertainty.
- Do not reuse real partisan biographies as fictional plot material without discussing the approach with the owner.
- Preserve the spelling `Mežabrāļi`; `Forest Brothers` is the working English title.

## Repository operations

- Keep visibility private; do not deploy, publish, change access, add collaborators, or buy services unless instructed.
- Avoid destructive Git operations. Do not overwrite others' work or rewrite shared history without instruction.
- Keep concept and roadmap documents current when approved behavior changes.
