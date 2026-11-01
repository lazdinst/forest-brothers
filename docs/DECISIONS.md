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
- Stealth, sound, enemy searching, ammunition scarcity, and weapon condition all matter. Their concrete mechanics remain to be chosen.
- A medical facility unlocked after a handful of main missions accelerates healing. Exact unlock count, durations, and recovery multipliers remain deferred.
- Disconnected non-host characters stay on the mission and remain vulnerable until killed; reconnect restores control of a surviving character and must not bypass mission death.
- First-pass host crash ends the mission and restores the entire campaign to pre-mission data, including building, cooking, and all concurrent camp changes. This is a rollback, not an ordinary mission death or a partial rewards commit.
- Dedicated-server support is a later goal. Completing the main quest line unlocks further missions; the current long-term goal is building the forest camp and resisting, with no fixed ending specified.
- Development context should be preserved in documentation and agent instructions for work across multiple agents.

## Proposed, not yet confirmed

- Godot standard edition, GDScript, Compatibility renderer.
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
- Concrete combat perception/searching/ammunition/wear rules; civilian needs and labor details; when partial returns commit shared rescue arrivals. See `COMBAT_DESIGN.md`.
- Engine version, art tools, asset pipeline, and budget.

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

## Recording future decisions

For each consequential decision, add the date, status, choice, reason, relevant user direction, and any decision it supersedes. Update the concept, roadmap, or technical direction when needed. Do not mark an agent proposal as owner-approved without evidence.
