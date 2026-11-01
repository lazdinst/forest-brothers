# Development roadmap

This is a proposed order for a first-time developer and early multiplayer validation. The owner has playtested milestone 1 movement, the door, and all three supplies. At the owner's request, the current increment is a local animation/movement/weapon training area before the multiplayer milestone. The art feasibility gate and all multiplayer/campaign milestones remain pending.

## 0 — Agree on the first experiment

Review the concept, select the engine/version, and settle the intended multiplayer format sufficiently to guide the prototype. Leave unrelated campaign decisions open.

Done when: the decision log records those choices and the next playable milestone has a clear boundary.

## 0A — Prove the art workflow

Before broad asset production, make a small reference-led art test in the confirmed gritty painted, low-resolution style. Establish one character, a limited directional/animation sample, a weapon view, a few props, and a rough tent-camp scene. See `ART_DIRECTION.md`.

Done when: the owner approves the visual direction, transparent sprites align and animate consistently, the character is readable against the environment, and camp assets remain readable from both first-person and a prototype planning camera. Record generation references/settings and processing steps. Exact resolution/direction counts must be selected through the test, not assumed final. This is a feasibility gate, not an art pack for the entire game.

## 1 — A room you can inhabit

Status: implemented as a placeholder yard/storehouse scene; automated scene checks and a rendered-frame inspection passed. Owner movement/interaction playtesting passed (door and all three supplies). The engine scaffold supports the still-pending art feasibility work; it does not settle the final visual style.

Create the minimal engine project. Add first-person movement, mouse look, collision, a door, and a single pickup in a tiny test area. Use placeholders.

Done when: the owner can launch it, move reliably, open the door, collect the item, and follow documented run instructions. It works offline.

## 1A — Movement, animation, and weapon training area

Status: implemented locally; automated traversal/ammunition/hit checks and GPU-rendered views inspected. Owner playtesting and animation cleanup remain pending. This increment is the owner's current priority; multiplayer remains the next foundational milestone before campaign expansion.

Includes crouching, collision-limited leaning, low-obstacle vaulting/climbing, a hurdle/tunnel/corner course, a patrolling civilian with candidate four-frame directional walk sheets, first-person hands/rifle motion, and three targets. The test rifle separates loose rounds and two magazines, timed manual refilling/reloading, maintenance-dependent jams, clearing, and cleaning. See `GETTING_STARTED.md` for controls and limitations.

Done when: the owner can navigate the course, judge the walking and first-person feedback, hit targets, refill/swap magazines without creating ammunition, and understand jams. Candidate art is not final approval. Near-field character perspective is explicitly deferred with a source TODO; this increment does not prove full-body player animation, combat damage, medicine, or co-op.

## 2 — Two players, one shared world

Add a basic host/join test before building a large inventory or campaign. Exercise two player characters, shared door state, and host-validated pickups.

Done when: two running instances observe the same world; simultaneous pickup attempts award only one item; disconnecting does not leave invalid shared state. Record how movement behaves with simulated latency and how the test was performed.

## 2A — Individual casualties and teammate rescue

Before adding a broad medical inventory, create a minimal playable state flow for injury, incapacitation, teammate treatment during a finite window, mission death, and return to camp. The full medical range is the product direction; this milestone proves the underlying behavior with placeholders.

Done when: a teammate can revive a downed player before expiry; expiry sends only that player to camp; survivors continue; host-character death also leaves survivors playing. Both camp-side and mission-side players stay connected. Interrupted/concurrent treatments and expiry at treatment completion have a defined, consistent result without duplicate item use. Solo/all-incapacitated cases resolve as mission death. Verify that dead players cannot rejoin the same mission, their carried equipment remains recoverable on the body, and camp-stored supplies remain safe. Revival must preserve injuries and temporary capability penalties; agree on placeholder balance values before implementation.

## 2B — One readable combat encounter

Prototype one weapon, separate loose rounds and magazines, manual refilling, retained partial magazines, maintenance-dependent jams, and friendly-fire injuries. Add one enemy with line-of-sight recognition, pace/surface sound investigation, last-known-position searching with eventual decay, and a local alert to a second observer when ready. Use deliberate placeholder balance values, not invented final tuning.

Done when: cartridge totals remain consistent through loading/reloading/firing and interrupted or concurrent actions; partial contents survive transfers; neglected-weapon jam risk is demonstrably higher under a controlled test; a friendly hit can cause the agreed injury/incapacitation; hiding can end a search without enemies tracking unseen movement. Show readable weapon state and verify multiplayer agreement. Exact weapon-specific loading/clearing animations and final detection/jam rates remain later tuning work.

## 3 — One meaningful outing

Build a compact slice of the handcrafted map (for example a town-edge building), a simple objective, one threat, and an observable camp outcome. Add randomized supplies and one bounded variation of a selected area, without generating a whole town. Prototype gunplay and resource handling only as far as needed for this mission. Add distinct light/heavy bleed, fracture, and pain treatment categories incrementally; keep period research and gameplay effects separate.

Done when: the mission can be completed or failed in solo and co-op, supplies have a visible purpose, individual death leaves surviving teammates able to finish, and a playtester can understand the objective without coaching. Verify an early safe return with loot/rescues but no main-quest completion, a completion reward/unlock, and a shortened test deadline that exercises the one-hour-cap timeout/death rule. Exercise all four player slots before expanding content.

## 3A — Useful work at camp

Prove one minimal camp activity while another player remains on mission: for example, collect water and cook a simple meal, or use a storage station and repair a weapon. Add a small placeable functional structure and a bounded trench interaction in a later increment of this milestone; do not begin with a full terrain system.

Done when: a returned player can complete the chosen camp task without interrupting survivors; costs/results are shared consistently; injuries have the agreed effect; mission lockout still holds. A separate construction increment must demonstrate both one freely placed piece and one predefined facility site/upgrade, validated placement, persistent structure state, and the chosen trench representation before broad building content is added. This milestone covers a proof of camp work, not the entire promised camp feature set.

## 3B — Planning tables and one building upgrade

Prototype the headquarters mission table and a build-planning table that changes only the interacting player's camera. Place one plan, display communal stock/cost/shortage clearly, and complete one upgrade from the rough tent-camp starting state. Use approved placeholder construction completion rules before attempting a civilian workforce.

Done when: both interfaces work with players simultaneously at camp and on mission; stock is not double-spent; plans are visibly distinct from completed structures; upgrading preserves stored contents; both free placement and facility upgrade rules remain supported. Prototype one civilian builder with player assistance; detailed hauling/harvesting and a broad workforce simulation remain outside this milestone.

## 3C — One civilian rescue that grows camp

Begin with one civilian resident. Add one rescuable civilian who receives directions, visibly departs toward camp, and remains a pending arrival until mission resolution.

Done when: a successful result adds exactly one resident, solo/total-group mission-death failure adds none, the camp roster does not change before resolution, and repeated rescue/result events do not duplicate the civilian. Verify that surviving teammates can secure the recruit after the rescuer dies, including host-character death, without adding them prematurely. Show pending versus arrived civilians and the debrief result. Do not expand this milestone into a civilian labor simulation.

## 3D — Civilian work and a recoverable shortage

Add one civilian construction job, one cooking job, visible communal needs/stocks, a main-mission material reward, and an optional scavenging outing on the same map. Define placeholder consumption, warning, and assistance values before implementation; these are balance choices, not fixed design requirements.

Done when: civilian work consumes resources once; player help has the agreed effect; shortages visibly threaten and can kill residents under the chosen rule; main progression can be delayed by poor supplies while optional scavenging still allows recovery. Test the zero-worker/low-equipment case to avoid an accidental permanent game-over. Medical-facility unlock and faster recovery follow a short placeholder quest chain; exact final quest count and durations remain deferred.

## 4 — A campaign that remembers

Implement the agreed save ownership and failure rules. Persist the relevant camp state, inventory, and mission result, including built structures, station/storage state, recoverable gear rules, and per-player mission death lockouts where an active mission can be resumed.

Done when: completing a mission, quitting, and loading restores the expected state; a non-host can disconnect and reconnect to the same living/vulnerable character; a host crash restores the entire pre-mission campaign including concurrent camp work. Test interrupted commits to prevent duplicated/lost rewards. Invalid or incompatible saves fail clearly without silently destroying progress.

## 5 — Prove the intended experience

Improve sound, sprite presentation, feedback, pacing, and usability. Measure performance and test one through four players over a real network, including the four-player cap and individual camp returns during an active mission. Select and validate internet connection/Steam integration options when needed.

Done when: the owner can assess whether the slice delivers tension, immersion, and a reason to care about camp; known networking and performance limits are documented.

## 6 — Expand from evidence

Choose additional locations, tasks, resources, residents, and systems based on playtest findings. Expand the confirmed camp building, trench, food, water, and maintenance systems from the small camp proof. Plan a separate later milestone for dedicated-server hosting (a confirmed future goal). Revisit scope before adding AI squadmates, vehicles, or a large world; these remain unapproved/deferred.

A Steam release plan follows a convincing slice: store materials, licensing review, packaging, onboarding, and release testing. No release date is committed.
