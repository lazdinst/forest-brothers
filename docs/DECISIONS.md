# Decisions and open assumptions

This is the durable project memory. User-confirmed direction and agent recommendations must remain distinct.

## Confirmed direction — 2026-11-01

- Working English title: **Forest Brothers**. Latvian spelling: **Mežabrāļi**.
- Repository: `lazdinst/forest-brothers`. The owner requires private visibility; creation/access settings have not been independently verified in these documents.
- Intended platform/distribution: a PC game for Steam.
- First-person experience, immersive and punishing; Tarkov is an experiential reference.
- The game is not intended to be an extraction shooter.
- Setting direction: post-WWII Latvia, inspired by the Forest Brothers.
- Activities include supporting a forest group/hideout, obtaining supplies, helping Latvian locals, and conflict with occupying forces.
- Low-resolution visuals and sprites are the owner's preferred direction.
- Support solo play and a maximum of four players in co-op. Starting with solo is acceptable, provided early design supports future expansion. Competitive PvP is not approved.
- Players explicitly go on missions from camp. Death ends that player's current mission participation and returns them to camp; surviving teammates can continue. This is individual mission death, not a group-wide automatic failure.
- Incapacitated players can be revived by teammates within a limited bleed-out window.
- Medicine should include multiple resources with distinct purposes, light/heavy bleeding, broken limbs, and morphine, appropriate to the historical setting.
- Starting equipment-loss rule: carried equipment stays on the body after mission death and teammates can recover it; camp-stored supplies remain safe. Ownership of recovered items remains unresolved.
- A dead player cannot rejoin the same mission and waits for a later outing to deploy again.
- Solo incapacitation and all remaining mission players becoming incapacitated resolve as mission death and return to camp; no AI/self-rescue system is approved.
- Revival preserves injuries and reduces capability for a duration; numerical penalties, timers, and recovery rules remain open.
- Camp supports hands-on equipment organization, building, trench digging, cooking, water collection, food storage, weapon repair, and ammunition gathering/organization. The owner cites Valheim as a reference for camp activities and structures.
- Players at camp can perform these activities while friends continue the active mission.
- Development context should be preserved in documentation and agent instructions for work across multiple agents.

## Proposed, not yet confirmed

- Godot standard edition, GDScript, Compatibility renderer.
- Fictional local partisan protagonist and fictional group within a researched setting.
- Specific mission launch, late-join, and reconnect rules; death locks the player out of the same mission. Competitive PvP remains unapproved and outside the prototype.
- Host-authoritative shared world and host-owned campaign save.
- Joining at camp before missions; no host migration initially.
- Simple 3D environments with billboard sprite characters.
- A concealed bunker and a few shelters as the first camp.
- A medicine-recovery mission as the first playable slice.

## Unresolved

- Exact historical period, region, protagonist, and relationship to real events.
- Whether any competitive mode is ever desired; co-op has a confirmed maximum of four players.
- Bleed-out duration, revival requirements, fatal injury exceptions, recovered-gear ownership, body persistence, camp recovery, and save rules. See `MISSIONS_AND_MEDICINE.md`.
- Mission/map boundaries, launch/return transitions, reconnect handling, and rewards for players who died. Mission death, same-mission lockout, and solo/all-player casualty outcomes are confirmed.
- Personal versus shared resources, building permissions, camp/mission time, construction mechanics, repair and food/water rules, and character progression. See `CAMP_AND_PROGRESSION.md`.
- Balance of combat, civilian assistance, stealth, and management.
- Engine version, art tools, asset pipeline, and budget.

## Mission and medical clarification — 2026-11-01

Status: user-confirmed requirements, refining the initial draft rather than changing the game's identity.

The owner explicitly wants mission outings, individual mission death with return to camp, surviving friends continuing, a timed teammate revival opportunity, multiple period-appropriate treatments, and a maximum of four co-op players. These supersede the initial open questions about co-op capacity and whether death must end the outing for everyone. Tarkov-style mission stakes are compatible with the owner's earlier direction that the game should not be an extraction shooter; exact loot-loss rules have not been chosen.

The detailed mechanics and historical item candidates in `MISSIONS_AND_MEDICINE.md` are proposals unless labeled confirmed. No gameplay is implemented yet.

## Camp and mission consequences — 2026-11-01

Status: user-confirmed starting rules and feature direction.

The owner accepted the initial equipment-loss proposal, rejected same-mission re-entry after death, chose mission death for solo/all-incapacitated cases, and confirmed injuries and reduced capability persist for a duration after revival. The owner also expanded camp from preparation into an interactive space with building, trenches, wells/water, food storage, cooking, equipment organization, weapon repair, and ammunition gathering, including while friends remain on mission.

This supersedes the earlier unresolved entries about those outcomes and the suggestion that camp might be only a preparation interface. Building is confirmed product scope, while complex construction remains outside the first mission slice. Exact construction tools, terrain deformation, recipes, timers, and permissions are not approved by this feature direction.

## Recording future decisions

For each consequential decision, add the date, status, choice, reason, relevant user direction, and any decision it supersedes. Update the concept, roadmap, or technical direction when needed. Do not mark an agent proposal as owner-approved without evidence.
