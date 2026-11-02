# Development roadmap

This is a proposed order for a first-time developer and early multiplayer validation. The owner has playtested milestone 1 movement, the door, and all three supplies. At the owner's request, the current local training increments cover weapons/movement, camp stations/NPCs, planning/recruitment, and an opponent encounter before the multiplayer milestone. The art feasibility gate and all multiplayer/campaign milestones remain pending.

## 0 — Agree on the first experiment

Review the concept, select the engine/version, and settle the intended multiplayer format sufficiently to guide the prototype. Leave unrelated campaign decisions open.

Done when: the decision log records those choices and the next playable milestone has a clear boundary.

## 0A — Prove the art workflow

Before broad asset production, make a small reference-led art test in the confirmed gritty painted, low-resolution style. Establish one character, a limited directional/animation sample, a weapon view, a few props, and a rough tent-camp scene. See `ART_DIRECTION.md`.

Done when: the owner approves the visual direction, transparent sprites align and animate consistently, the character is readable against the environment, and camp assets remain readable from both first-person and a prototype planning camera. Record generation references/settings and processing steps. Exact resolution/direction counts must be selected through the test, not assumed final. This is a feasibility gate, not an art pack for the entire game.

### 0A environment increment — visual proof awaiting review

Birch detail follow-up: owner requested more realistic birches and detailed texture skins. A revised species candidate is integrated through shared resources: generated bark/leaf textures, smooth curved wood, tapered/drooping branches and folded cutout leaves. Close-up, seam and all-side GPU views were inspected; terrain/trench integration checks pass. Prompts/provenance and current GTX 1080 measurements are recorded in `ENVIRONMENT_ASSET_PIPELINE.md`. Owner appearance review and distance LOD remain pending.

Root-flare follow-up: after positive texture feedback, replaced the birch's fin-like separate roots with a continuous low, asymmetric collar and a darker soil-contact transition. Three close root views were inspected and the training-environment check passed. Owner root-shape review remains pending.

Owner requested an environment pipeline and ~100 × 100 m Latvian forest, with a visual-review gate before expansion. Phase 1 plan and Phase 2 candidate now exist in [ENVIRONMENT_ASSET_PIPELINE.md](ENVIRONMENT_ASSET_PIPELINE.md): original procedural spruce, moss/dirt, fern, boulder and crate resources in a separate playable 24 m clearing, reusing the player unchanged. Collision/traversal checks and actual GTX 1080 Compatibility frames were inspected; brief proof measurements are recorded there. F6 runs `scenes/environment/environment_visual_proof.tscn`; the training yard remains the main scene.

Remaining: owner review/visual refinement, a dedicated `forest_biome_test.tscn` if still desired alongside F5, tent/camp environment art, LOD, winter demonstration, wind/fire and extended performance/motion/planning-camera acceptance. The environment milestone and art feasibility gate remain incomplete.

Dense woodland follow-up: at the owner's explicit request for detail, subtle ground relief and a trench they can enter, the F5 scene now has an approximately 100 × 100 m terrain patch (annex footprint excluded), 229 generated trees across three species, fallen logs/stumps, moss clumps and dense small vegetation. Terrain and collision share one height recipe, with gentle rises/hollows and level fixture exclusions. A sloped entrance and connected branch make the excavated trench walkable. Seeded editor-time placement, spacing/undergrowth controls and spatial MultiMesh batches are implemented. Seven focused checks and GTX 1080 rendered views passed; see the pipeline's v2 validation record. No final art approval is implied.

Owner follow-up: environment candidates now also appear in the main F5 weapon/control/animation testbed. A separate prop scene populates unused yard space and the existing floor uses moss/dirt material; course, targets, interactions and player/weapon implementations are preserved. Six focused checks and a rendered combined-yard inspection passed. The isolated F6 proof remains for controlled inspection.

## 1 — A room you can inhabit

Status: implemented as a placeholder yard/storehouse scene; automated scene checks and a rendered-frame inspection passed. Owner movement/interaction playtesting passed (door and all three supplies). The engine scaffold supports the still-pending art feasibility work; it does not settle the final visual style.

Create the minimal engine project. Add first-person movement, mouse look, collision, a door, and a single pickup in a tiny test area. Use placeholders.

Done when: the owner can launch it, move reliably, open the door, collect the item, and follow documented run instructions. It works offline.

## 1A — Movement, animation, and weapon training area

Status: implemented locally; automated traversal/ammunition/hit checks and GPU-rendered views inspected. Owner playtesting and animation cleanup remain pending. This increment is the owner's current priority; multiplayer remains the next foundational milestone before campaign expansion.

Includes crouching, collision-limited leaning, low-obstacle vaulting/climbing, a hurdle/tunnel/corner course, a patrolling civilian with candidate four-frame directional walk sheets, first-person hands/rifle motion, and three targets. The test rifle separates loose rounds and two magazines, timed manual refilling/reloading, maintenance-dependent jams, clearing, and cleaning. Weapon-specific definitions now provide art/anchors, capacity, fire timing, and separate action timelines; a procedural moving-magazine reload is present, while new hand poses remain unfinished after image generation rejection. See `GETTING_STARTED.md` for controls and limitations.

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

## 1B — Communal camp workshop laboratory

Owner-directed increment while the environment agent develops woodland assets. Implemented local training fixtures: one shared ledger, one-time quartermaster cache, well, civilian cooking and food provisioning, armourer service, physical ammunition transfers, distinct medical test-patient treatments, predefined shelter upgrade and marked trench work. Costs reserve atomically; jobs own a worker, cancel/refund once, and permit one foreman assist. Values are prototype choices. Twelve stations and real UI interaction are checked. Owner playtesting, work animations, campaign persistence, and concurrent network authority remain pending; this does not complete milestone 3A/3D.

## 1C — Civilian, planning and rescue laboratories

Implemented a starting civilian role panel, worker assignment/busy rules, overhead build-table camera, validated free rack plans and civilian construction alongside the fixed shelter upgrade. Reuses existing civilian art. A separate manual rescue exercise proves departure, pending-versus-arrived residents, early safe return without quest reward, objective rewards once, and pending-recruit loss on group death. Jobs continue during planning; it does not globally pause. These local exercises do not implement full missions, individual deaths, civilian schedules, hauling or save/rollback. Camera/input/placement and result accounting checks pass; milestones 3B/3C still require their full mission/co-op acceptance cases.

## 1D — Opponent encounter laboratory

Two local test opponents now receive actual rifle damage, show brief hit/blood feedback, collapse into nonblocking corpses and reset cleanly. A controlled bout exercises recognition/reaction delays, stance/distance sensitivity, cover LOS, approximate gunshot/pace noise, finite search, local alerts and ray-checked return fire. A separate training vitality counter ends a bout; it is not player wounds/incapacitation/mission death. One new front-only guard candidate; death is procedural and opponent weapons are flash proxies. Navigation, proper weapon/walk/death frames, surface-specific footsteps, friendly-fire casualties and multiplayer remain unfinished. Milestone 2B is partial, not complete.

Validation: all 13 current local checks pass, including the other agent's isolated environment proof and integrated yard checks. GPU frames of camp, panels, overhead plans, enemies and corpse state inspected on GTX 1080 Compatibility. See [CAMP_AND_COMBAT_TESTS.md](CAMP_AND_COMBAT_TESTS.md) for the entry point, each station's playtest and limits. No final art, stable-performance or co-op acceptance is inferred.

Next foundational priority after owner review remains milestone 2 host/join and two-instance authority, then 2A individual casualties/revival and a real mission loop. Preserve the environment agent's visual-review gate and ownership; do not duplicate its assets or mark the full biome complete from these laboratories.

## 1E — Rigged polygon character migration proof

Latest owner direction replaces the sprite-first character target with rigged 3D players/NPCs. A shared 32-bone GLB proof now supplies civilian/field variants and eight body clips. Camp residents/patient, player body and one enemy use it; an interactive original-yard display cycles poses. Legacy characters remain comparison references. Meshes are original low-poly blockouts with temporary vertex colors, not approved final art. The first-person gun/hands are still sprites.

Done for this local proof: GLB round-trip with skin weights/attachments/animation tracks, actual skeletal pose and transition checks, non-billboard world orientation, body visibility in first-person/planning, and integration with existing gameplay. All 15 combined checks passed; current forest/trench and character locations coexist without replacing the environment agent's assets. See POLYGON_CHARACTER_PIPELINE.md.

Remaining migration work: refine/UV/paint one character, improve weights and foot contact, define retargeting/bone mapping and layered locomotion/aim, calibrate camera/head and first-person weapon/hand rigs, then migrate the remaining references. Validate owner art/game feel and crowd performance before expanding the cast. Networking acceptance remains under milestone 2; these visuals do not prove it.

## 1F — Better human base and modular clothing (next art proof)

The owner rejected 1E's visual result. Its rig checks remain useful technical evidence, but do not complete character art. Normal-play sprites are restored; rejected models remain opt-in and labeled in the display.

Next: one convincing old civilian, a shared production rig and two outfits made from separate garments. Define body coverage, garment compatibility and a tested animation bone map. Show close/front/side/rear, crouch/aim/reload/death and planning views beside the sprite. Verify swapping clothes without duplicating the whole body, inspect deformation/clipping, measure representative dressed characters, and obtain visual feedback before replacing default sprites or producing a roster. See MODULAR_CHARACTER_BRIEF.md. This proof is pending; modular garment assets/runtime and final art are not implemented.

### Continuous training map follow-up

Owner requested one walkable training map. The original shooting/movement yard now connects to the camp/enemy area through a signed ground route and an open entrance, replacing travel tables. Automated two-way walking, station interaction and planning checks pass. Owner navigation/appearance review remains pending.

### Training forest pine/deadwood art iteration

Owner-directed pine upgrade is implemented in the current training scene: generated lower/upper bark and needle skins, fuller crown geometry, dead lower limbs, two fallen pines, three rotten mossy logs, two broken snags and twelve decorative branch props. Focused scene/traversal checks and GPU inspection passed, including vaulting and hollow-log collision. Current close-detail assets are more expensive; distance LOD and foliage/shadow optimization should precede further density expansion. Visual acceptance and prolonged motion review remain pending. See ENVIRONMENT_ASSET_PIPELINE.md; this is not full biome milestone completion.

Training resource follow-up: fresh sessions now start with generous communal supplies for all eight resource categories. Shared icons, names and live counts appear in HUD/camp panels and inventory; the quartermaster cache remains an optional extra. Startup/pickup, workshop, camp and inventory checks pass. Campaign quantities remain undecided.

Direct player work follow-up: cooking and construction no longer require civilians. Station panels offer personal work and optional civilian assignment. Personal tasks validate proximity, cancel/refund on interruption, and share existing costs/completion checks. Rule and real cooking-button integration checks pass, including zero-civilian cooking/building, parallel civilian work and one-time spends/refunds. Work animations, owner feel review and network authority remain pending.


### Labeled nature asset review area

Implemented `scenes/environment/environment_asset_test.tscn`: a separate F6 lane with 17 numbered/labeled current nature assets, older/detail status, full-scale spacing, unarmed movement and previous/next station jumps. Catalog coverage, nonoverlapping specimens, clear aisle, floor support and actual navigation passed checks; rendered tree/deadwood/ground-cover views were inspected on GTX 1080 Compatibility. This enables owner review of the remaining simpler meshes; it does not upgrade or retire them or complete the biome milestone.

## Current priority — combat before more character art

Owner froze character art development. Milestone 1F's further outfits/model refinement is paused. Visual validation is complete, original/rigged/dressed MPFB sources and animation recipe are preserved, and sprites are again the default with an optional MPFB enemy comparison. Next proposed work is the bounded supply-recovery combat drill described in CHARACTER_FREEZE_AND_COMBAT_SLICE.md. Review scope before any major combat refactor. Existing nature/environment and main-menu agent work is outside this change. Two-instance combat authority remains an early follow-up gate before content expansion.


## 1G — Tactical movement training increment

Owner-directed expansion of the current player: ten walking paces, seven
collision-safe heights, prone, inertia, leg/arm stamina, carried mass penalties,
pace-dependent hearing and supplied chalk silhouette HUD. Implemented locally;
see [TACTICAL_MOVEMENT.md](TACTICAL_MOVEMENT.md) for inspection, controls,
validation and provisional values. Owner feel acceptance remains pending.
Character-art freeze and milestone 2's two-instance authority gate remain.

## Physical ammunition inventory increment

Owner-requested local extension of weapon training: stable stack/magazine/weapon IDs, 32-round stacks, explicit chambering, real pockets/pack locations, timed fill/unload/inspection, drag/drop, world recovery and categorical magazine knowledge now share the existing weapon rule owner. The ten-round kit has two full magazines and 32 loose rounds. Equipment JSON/file round-trip checks do not complete campaign persistence or host-crash rollback. This does not complete milestone 2/2B networking acceptance. Detailed behavior and validation are in AMMUNITION_INVENTORY.md; owner animation/game-feel review remains.
