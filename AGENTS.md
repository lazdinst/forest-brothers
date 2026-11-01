# Agent instructions — Forest Brothers

## Read first

Before proposing or implementing substantial work, read:
1. `docs/GAME_CONCEPT.md`
2. `docs/DECISIONS.md`
3. `docs/ROADMAP.md`
4. `docs/TECHNICAL_DIRECTION.md` when changing code or technical design.
5. `docs/MISSIONS_AND_MEDICINE.md` and `docs/CAMP_AND_PROGRESSION.md` when changing their systems.

The user's current instructions take precedence. This file applies throughout the repository; nested `AGENTS.md` files add guidance for their directories.

## Purpose

Build an immersive, punishing first-person survival game about a small resistance group in postwar Latvia. The player helps local people and supports a concealed forest camp. Tarkov informs tension, vulnerability, and material consequences. The game is not an extraction shooter.

Preserve these user requirements:
- Latvian identity and a Forest Brothers-inspired setting.
- First-person play with low-resolution/retro visuals and sprite-based characters as the intended visual direction.
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
- Art direction is gritty illustrated sprites: painted characters with a low-resolution finish. Agent-generated sprites need a reference-led, visually checked pipeline; read `docs/ART_DIRECTION.md`. Civilian building/hauling/tree-harvesting is a proposal, not an implemented or fully approved workforce simulation.
- Initially the camp has the player and one civilian (an old man is the suggested identity). Rescue civilians on missions, direct them toward camp, and show them running off. They remain pending until mission resolution; successful rescue arrivals then join camp. Solo/total-group mission death loses pending recruits. Surviving teammates can secure arrivals even if the rescuer dies; individual death must not cancel the group's recruits.
- Keep the repository private.

Four-player maximum co-op and individual mission death are confirmed. Do not treat proposed medical item effects, numerical balance, or a proposed engine as approved requirements. Check the decision log and `docs/MISSIONS_AND_MEDICINE.md` for their status.

## Scope and design

- Work toward the current roadmap milestone; avoid implementing speculative later systems.
- Prefer one small, complete gameplay loop over broad unfinished features.
- Keep open questions explicit. Make reversible local choices when needed and document consequential assumptions.
- Explain tradeoffs before making changes that commit the project to a new engine, networking model, persistence model, or product direction.
- Keep tension fair and understandable. Do not equate punishment with arbitrary losses or excessive chores.
- Do not turn the game into competitive PvP, an extraction economy, or a live-service product without user direction.

## Technical habits

- Separate player input, authoritative game rules, and presentation. Shared world changes must have a clear owner.
- Do not assume there is exactly one player or use a global player reference as the foundation of shared systems.
- Use stable IDs for persistent entities and content where needed. Keep definitions separate from mutable runtime state.
- Prefer straightforward reusable components over a speculative universal framework.
- Validate co-op with two running instances early, before expanding content. Networking support is not proven by clean-looking interfaces alone.
- Do not select dependencies, engine versions, or third-party assets without checking their current suitability and license.
- Never commit secrets, generated engine caches, export credentials, local saves, or unlicensed assets.
- There is no automated test or build command yet. Do not invent passing checks. Add instructions when a runnable project exists.

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
