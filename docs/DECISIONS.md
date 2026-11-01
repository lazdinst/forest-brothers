# Decisions and open assumptions

This is the durable project memory. User-confirmed direction and agent recommendations must remain distinct.

## Confirmed direction — 2026-11-01

- Working English title: **Forest Brothers**. Latvian spelling: **Mežabrāļi**.
- Repository: `lazdinst/forest-brothers`. The owner requires private visibility; creation/access settings have not been independently verified in these documents.
- Intended platform/distribution: a PC game for Steam.
- First-person experience, immersive and punishing; Tarkov is an experiential reference.
- The game is not intended to be an extraction shooter.
- Setting direction: Latvia around 1946, inspired by the Forest Brothers. This is the working year; the region and exact historical framing remain open.
- Activities include supporting a forest group/hideout, obtaining supplies, helping Latvian locals, and conflict with occupying forces.
- Art direction: gritty illustrated sprites, with painted characters and a low-resolution finish. The owner expects agent-generated sprite production; pipeline feasibility and consistency must be tested early.
- Support solo play and a maximum of four players in co-op. Starting with solo is acceptable, provided early design supports future expansion. Competitive PvP is not approved.
- Players explicitly go on missions from camp. Death ends that player's current mission participation and returns them to camp; surviving teammates can continue. This is individual mission death, not a group-wide automatic failure.
- Incapacitated players can be revived by teammates within a limited bleed-out window.
- Medicine should include multiple resources with distinct purposes, light/heavy bleeding, broken limbs, and morphine, appropriate to the historical setting.
- Starting equipment-loss rule: carried equipment stays on the body after mission death and teammates can recover it; camp-stored supplies remain safe. All recovered items remain communal; body persistence and physical access rules remain unresolved.
- A dead player cannot rejoin the same mission and waits for a later outing to deploy again.
- Solo incapacitation and all remaining mission players becoming incapacitated resolve as mission death and return to camp; no AI/self-rescue system is approved.
- Revival preserves injuries and reduces capability for a duration; numerical penalties, timers, and recovery rules remain open.
- Camp supports hands-on equipment organization, building, trench digging, cooking, water collection, food storage, weapon repair, and ammunition gathering/organization. The owner cites Valheim as a reference for camp activities and structures.
- Players at camp can perform these activities while friends continue the active mission.
- Construction uses a mixture of freely placed pieces and predefined facility sites/upgrades. Exact assignments and placement mechanics remain open.
- Everything is communal, including equipment, ammunition, food, building materials, and recovered gear. Players must be able to see quantities easily; custody/location is distinct from ownership.
- Start with a rough camp of tents and progressively upgrade buildings over time, with city-builder-like camp development.
- A mission-planning table sits in a headquarters tent or bunker.
- Desired construction interface: a build-planning table opens a city-builder view to place plans. This complements the confirmed mixture of freely placed pieces and predefined facility upgrades.
- Initially the camp consists of the player and one civilian; an old man is the suggested civilian identity, not a finished character specification. This does not change the four-player co-op limit.
- More civilians are rescued during missions and given directions to camp. They run off toward camp rather than requiring a confirmed full-route escort system.
- Departed civilians are pending arrivals until the mission ends. Successful mission resolution brings them into camp; mission-death failure means they were lost or died en route and are not recruited. In co-op, surviving teammates can secure arrivals even if the rescuer dies. Loss is tied to solo/total-group mission death, not an individual death.
- Safe early return can secure supplies and civilians without completing the main quest; incomplete quests do not advance the quest line or award completion materials.
- Start with one handcrafted mission map and randomize supplies and selected portions. A Latvian town/city is an example, not a chosen real location. Outings have a maximum one-hour limit; expiry is mission death for remaining on-map players, losing carried gear and pending civilians.
- Civilians perform construction, cooking, and similar camp jobs; some can simply be resident NPCs. Players may assist construction as foremen. Main-mission completion awards construction materials; detailed task systems and other material sources are not fully defined.
- Supply shortages can kill civilians and prevent adequately supplied main-quest attempts. Optional scavenging outings provide recovery; there is no permanent campaign game-over.
- Combat perception: enemies require line of sight; recognition builds with exposure and depends on distance/movement/stance. Footsteps vary by pace/surface; noise prompts investigation toward an approximate location. Enemies search last-known areas, searches eventually decay, and alerts spread locally rather than instantly across the map. Enemy reaction/accuracy must have readable limits.
- Ammunition: loose cartridges and magazines are distinct; players manually refill magazines and keep partial magazines. Exact loading timings, magazine compatibility, chamber detail, and ammo-count UI remain open.
- Weapons can jam and jam more often without cleaning/servicing. Condition is visible and weapons have a maintenance/repair path. Numerical rates, clearing actions, wear effects, and service requirements remain open.
- Friendly fire is enabled; teammate hits can cause injuries/incapacitation under the game's normal casualty rules. Damage scaling and any optional safeguards remain undecided.
- A medical facility unlocked after a handful of main missions accelerates healing. Exact unlock count, durations, and recovery multipliers remain deferred.
- Disconnected non-host characters stay on the mission and remain vulnerable until killed; reconnect restores control of a surviving character and must not bypass mission death.
- First-pass host crash ends the mission and restores the entire campaign to pre-mission data, including building, cooking, and all concurrent camp changes. This is a rollback, not an ordinary mission death or a partial rewards commit.
- Dedicated-server support is a later goal. Completing the main quest line unlocks further missions; the current long-term goal is building the forest camp and resisting, with no fixed ending specified.
- Engine: user-selected Godot. The first prototype uses verified Godot 4.7.2 standard, GDScript, and Compatibility.
- Development context should be preserved in documentation and agent instructions for work across multiple agents.

## Proposed, not yet confirmed


- Fictional local partisan protagonist and fictional group within a researched setting.
- Specific mission launch/late-join UI and safe exit points; reconnect returns to the existing living character, while death locks the player out of that mission. Competitive PvP remains unapproved and outside the prototype.
- Host-authoritative shared world and host-owned campaign save.
- Joining at camp before missions; no host migration initially.
- Simple 3D environments with billboard sprite characters.
- Detailed civilian job assignment, hauling, and tree harvesting remain to be designed. Construction/cooking roles and player assistance are confirmed; some civilians may be non-working resident NPCs.
- A medicine-recovery mission as the first playable slice.

## Unresolved

- Exact region, protagonist, and relationship to real events; working year is approximately 1946.
- Whether any competitive mode is ever desired; co-op has a confirmed maximum of four players.
- Bleed-out duration, revival requirements, fatal injury exceptions, physical gear recovery, body persistence, camp recovery, and save rules. See `MISSIONS_AND_MEDICINE.md`.
- Safe exit design, staggered-return/civilian arrival timing, main-quest completion/turn-in checks, and real-time versus simulation-time details within the one-hour cap. See `MISSION_STRUCTURE.md`.
- Shared stock visibility and physical access, spending/build permissions, camp/mission time, construction mechanics, repair and food/water rules, and character progression. Ownership is communal. See `CAMP_AND_PROGRESSION.md`.
- Combat perception thresholds, search/alert durations, ammunition/loading UI, jam/maintenance balance, and friendly-fire damage tuning; civilian needs and labor details; when partial returns commit shared rescue arrivals. See `COMBAT_DESIGN.md`.
- Art tools, asset pipeline, and budget. The first runnable project is pinned to Godot 4.7.2 standard.

## Mission and medical clarification — 2026-11-01

Status: user-confirmed requirements, refining the initial draft rather than changing the game's identity.

The owner explicitly wants mission outings, individual mission death with return to camp, surviving friends continuing, a timed teammate revival opportunity, multiple period-appropriate treatments, and a maximum of four co-op players. These supersede the initial open questions about co-op capacity and whether death must end the outing for everyone. Tarkov-style mission stakes are compatible with the owner's earlier direction that the game should not be an extraction shooter; exact loot-loss rules have not been chosen.

The detailed mechanics and historical item candidates in `MISSIONS_AND_MEDICINE.md` are proposals unless labeled confirmed. No gameplay is implemented yet.

## Camp and mission consequences — 2026-11-01

Status: user-confirmed starting rules and feature direction.

The owner accepted the initial equipment-loss proposal, rejected same-mission re-entry after death, chose mission death for solo/all-incapacitated cases, and confirmed injuries and reduced capability persist for a duration after revival. The owner also expanded camp from preparation into an interactive space with building, trenches, wells/water, food storage, cooking, equipment organization, weapon repair, and ammunition gathering, including while friends remain on mission.

This supersedes the earlier unresolved entries about those outcomes and the suggestion that camp might be only a preparation interface. Building is confirmed product scope, while complex construction remains outside the first mission slice. Exact construction tools, terrain deformation, recipes, timers, and permissions are not approved by this feature direction.

## Mixed construction — 2026-11-01

Status: user-confirmed direction.

The owner selected a mixture when offered freely placed construction, predefined sites/upgrades, or both. This resolves that high-level construction choice. Freely arranged shelters/trenches and predefined wells/workshops are the starting interpretation; object-by-object rules, snapping, terrain technology, costs, and permissions remain undecided.

## Communal camp, planning, upgrades, and art — 2026-11-01

Status: user-confirmed direction, with civilian workforce marked as a proposal.

The owner chose gritty illustrated sprites, communal ownership with easily visible stock quantities, a headquarters mission table, a rough tent-camp start, and progressive building upgrades. The requested build-planning table opens a city-builder view for placing construction plans. Civilian construction, hauling, and tree harvesting were introduced as a possibility, so agents must preserve that proposal without silently approving a full workforce/resource-chain simulation.

These decisions supersede the private-versus-shared inventory question and the earlier starting-bunker proposal. Communal ownership does not undo body-based equipment loss, authorize remote transfers, or settle spending permissions. No images or gameplay have been produced yet.

## Starting population and civilian arrivals — 2026-11-01

Status: user-confirmed recruitment flow, including the co-op casualty rule.

The owner specified a start with the player and one civilian, suggested as an old man. Civilians rescued during missions receive directions and run off toward camp. They join camp at successful mission resolution, not immediately after the rescue interaction. Mission-death failure loses those arrivals, explained as the civilians getting lost or dying on their journey. The owner clarified that surviving teammates can secure arrival even if the rescuer dies. Pending civilian loss is a solo/total-group mission-death outcome; one player dying does not cancel the rescue.

This resolves how the camp population grows, but does not by itself approve the proposed construction/hauling workforce simulation or make the starting civilian an AI combat companion.

## Mission rules, civilian work, survival, and crash recovery — 2026-11-01

Status: user-confirmed direction, superseding earlier open questions and proposals in these areas.

The owner confirmed early return with supplies/civilians without main-quest completion; one handcrafted map with randomized supplies/portions; a one-hour maximum with timeout death; civilian construction/cooking with player help; main-mission construction rewards and quest unlocks; lethal civilian shortages without permanent campaign failure; later medical-facility healing benefits; persistent vulnerable disconnected characters; and later dedicated-server support. The owner chose approximately 1946 as the working setting.

Follow-up answers confirmed that timeout loses carried gear and pending civilians, and host crashes roll back the entire campaign, including camp work, to before the mission. Do not treat a network interruption as character death or retain rewards from a rolled-back outing. Detailed combat mechanics and numerical balance are still open.

## Combat approval and magazine/maintenance rules — 2026-11-01

Status: user-confirmed behavior; numerical balance and detailed interactions remain open.

The owner accepted the preceding combat suggestions, including visual recognition, approximate sound investigation, last-known-position searches with eventual decay, local alerts, finite ammunition/partial magazines, visible condition/repair, and readable enemy limits. The owner additionally specified separate bullets and magazines with manual magazine refilling, jams that become more likely without cleaning/service, and friendly fire. This supersedes the earlier combat proposal status. No weapon roster, ammunition variant system, loading/clearing procedure, jam probability, or difficulty numbers have been approved.

## First runnable Godot prototype — 2026-11-01

Status: engine confirmed by the user; initial implementation verified locally.

The owner chose Godot and downloaded the standard Windows build. Its executable reports `4.7.2.stable.official.ed1daf0bf`. The repository now contains `project.godot`, a reusable first-person player, an editable placeholder yard/storehouse scene, a door, three supply pickups, and a scene-owned communal stock ledger. This supersedes prior statements that no playable project exists; historical design entries describe the state when recorded.

Verification: Godot import completed; the headless scene integration check passed floor landing, movement, door interaction/traversal, one-shot pickups, and wall collision. A Compatibility-rendered frame on the GTX 1080 was visually inspected. Owner playtesting, final art, multiplayer, missions, saving, and broader gameplay remain pending. The sample pickups deposit directly into a reset-on-run ledger solely to test interactions; final carrying/mission-return rules are unchanged.

## Starting civilian appearance — 2026-11-01

Status: owner-approved visual reference.

The owner approved `assets/characters/starting_civilian/starting_civilian_front_v1.png`: the fictional older civilian in a worn cap, brown patched jacket, grey sweater, dark trousers, and boots. Preserve his identity/outfit when producing directional or animated variants. Name and biography remain open.

A static front-only Y-axis billboard and body collider are placed in the movement scene for first-person scale review. This does not approve a final sprite resolution or establish animation/directional consistency. The original generated PNG is preserved unchanged.

## Civilian directional idle experiment — 2026-11-01

Status: implemented feasibility experiment, not approval of a final art specification.

Generated one side view and one back view using the owner-approved front as the identity/style reference. The test scene now selects front, side, back, or mirrored side from the active viewport camera's angle relative to the actor's local +Z facing. This is presentation-only, with no global player dependency and no character turning or labor AI.

Four directions and profile mirroring are temporary test choices. Mirroring also reverses asymmetric patches; the new views need owner review and may need additional consistency cleanup. Animation, final sprite resolution, final direction count, and multiplayer verification remain pending. Source PNGs are preserved unchanged; prompts are recorded beside them.

## Close-range sprite projection correction — 2026-11-01

Status: implementation fix following owner playtest feedback; FOV remains a tunable prototype setting.

Reproduced severe head-to-feet taper when viewing the fixed-Y billboard close up with the camera pitched down. The character now uses a camera-plane-aligned visual pivot anchored at its feet, while the physical collider and direction-selection frame stay upright. Orientation updates each frame even when the selected artwork stays the same. No source artwork was changed.

The default camera FOV is reduced from 80 to 60 vertical degrees to soften wide-angle stretching. This does not switch the world camera to orthographic or lock a final FOV. A projection regression checks close/medium/far tilted views from several directions, equal projected scale across the sprite, a fixed foot anchor, and an upright body. Elevated planning-camera presentation still needs its own visual test because this remains flat artwork.

## Remove pitch-dependent sprite zoom — 2026-11-01

Status: corrective implementation after the preceding projection change failed owner playtesting.

The full-pitch camera-plane visual introduced apparent zooming when looking up/down. It is removed. The visual now stays upright and turns in yaw based on camera position only; changing camera orientation in place leaves the sprite transform and scale unchanged. FOV remains fixed at 60 vertical degrees.

Rather than trying to cancel perspective with a moving visual, a player-only clearance cylinder stops ordinary walking about 1.2 m from the civilian center. The 0.28 m body collider remains separate and interaction rays ignore clearance. This is a tunable prototype stand-off, not a final combat hitbox or NPC navigation rule. Ordinary perspective foreshortening remains; extreme close-up access is limited.

The previous equal-projected-width test missed the reported behavior. Its replacement exercises walking to the civilian, pitching up/down in place, constant sprite transform/FOV, an upright visual/body, and bounded taper at the reachable distance. This entry supersedes the previous camera-plane alignment implementation.

## Recording future decisions

For each consequential decision, add the date, status, choice, reason, relevant user direction, and any decision it supersedes. Update the concept, roadmap, or technical direction when needed. Do not mark an agent proposal as owner-approved without evidence.


## Local training increment — 2026-11-01

Owner-directed scope: defer the accepted close-up sprite workaround with a code TODO, then prioritize viewed-character animation, first-person feedback, more movement controls, obstacle tests, and weapon tests. This is a local learning/playtest increment before resuming early multiplayer validation.

Implemented prototype choices: Ctrl crouch, Q/E lean, F interaction, V low vault/mantle; candidate front/side/back four-frame civilian walk cycles with a demo patrol; generated first-person rifle/hands plus procedural movement/recoil/action lowering. The local range uses two ten-round magazines, thirty spare cartridges, manual cartridge transfers, retained partial magazines, timed reload/clear/clean, dirt-dependent random jams, and ray-hit targets. These numbers and controls are not approved final tuning. The SVT-40-inspired art is not an approved historical loadout; provenance/research and generation prompts are in `assets/TRAINING_ART_PROMPTS.md`.

Deferred: sprite near-field presentation/clearance, calibrated iron sights, actual hand/magazine reload animations, full-body player animation, full inventory authority, damage/medicine, AI, networking, and saving. The new generated art is a candidate for owner review. Tests establish local mechanics, not production animation or co-op readiness.

## Aim down iron sights — 2026-11-01

Owner requested looking down the rifle's actual iron sights. Supersedes the local zoom-only aim placeholder: RMB transitions to a matching generated centered ADS view, front-post tip anchored to the camera shot ray, crosshair hidden, world FOV fixed at 60. Action lowering interrupts aiming; holding RMB resumes afterward. Alignment and target-hit checks cover two window sizes and lean roll. Artwork is still a prototype; prompt and provenance are in assets/IRON_SIGHTS_PROMPT.md. Full hand/reload animation remains deferred.

## Barrel flash and gun illumination — 2026-11-01

Owner requested a visible explosion/flash at the barrel, barrel-origin firing, and illumination on the rifle itself. Implemented a generated four-frame muzzle-flash atlas for hip and ADS, warm shader relighting on the original gun/hand sprites, and a brief nearby-world light. The sights choose the aim point; the actual collision ray/tracer begins at the projected muzzle and respects near cover. Source sprites remain unchanged; a shader keeps illuminated variants aligned. Flash timing, apparent size, light intensity, and virtual barrel depth remain prototype choices. No ballistics or multiplayer gun presentation is proven.

## Per-weapon animation content — 2026-11-01

Owner requested a reload animation and a scalable approach for many weapons with distinct reload, checking, and jam actions. The intended test rifle remains SVT-inspired (ten-round detachable magazine), not an approved M1 Garand; generated art is inconsistent. Added per-weapon definition/action/pose resources, configurable action timings and effect markers, and a procedural magazine withdrawal/retention/insertion reload with distinct inspection/clearing pose clips. Hand art remains static: the image tool rejected the requested reload atlas, so no new sheet was produced. Current timings and silhouette masks are prototype choices. The different-capacity test fixture is validation only, not an added weapon roster entry. Internal magazines/en-bloc clips and full hand/mechanism animations remain unfinished; see WEAPON_ANIMATION_WORKFLOW.md.
