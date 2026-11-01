# Camp life and progression

Status: confirmed feature direction with proposed mechanics and unresolved balance. Local workshop/NPC/planning/rescue exercises now exist; see [Camp and Combat Tests](CAMP_AND_COMBAT_TESTS.md). Campaign progression, shared network authority and saving remain unimplemented.

## Confirmed by the owner — 2026-11-01

Camp is a playable place where players can work while friends continue a mission, including after returning from mission death. The owner cites Valheim as a reference for hands-on camp activities and functional buildings.

Confirmed activities and infrastructure:
- Organize communal equipment and supplies; make stock quantities easy to inspect.
- Build camp structures and dig trenches using a mixture of freely placed pieces and predefined facility sites/upgrades.
- Collect water, including wells as a desired camp structure.
- Store food and cook meals, with dedicated storage/cooking facilities.
- Repair weapons and gather/organize ammunition.

The camp starts rough, with tents, and develops through gradual building upgrades toward a more established forest settlement/hideout. A headquarters tent or bunker houses the mission-planning table. A separate build-planning table opens a city-builder view for placing plans. Specific upgrade tiers, construction complexity, materials, recipes, and the eventual settlement scale remain undecided.

## Starting residents and rescue recruitment

Confirmed start: the player and one civilian in the rough tent camp. An old man is the owner's suggested identity; name, background, abilities, and narrative role remain undesigned. Additional human co-op participants are separate from this initial civilian roster; the maximum remains four players.

Confirmed recruitment flow:
1. Find and rescue civilians during a mission.
2. Give them directions to the camp.
3. They run off toward camp during the mission.
4. Keep them as pending arrivals until the mission resolves. Do not add them to the visible camp population or give them camp jobs yet.
5. On successful resolution, they appear at camp and join its resident roster.
6. Mission-death failure loses those pending civilians: they were lost or died en route, and do not join camp.

Confirmed co-op rule: surviving teammates can secure the civilians' arrival even if the rescuer dies. Pending recruitment belongs to the group, not an individual player. Solo/total-group mission death loses the pending arrivals. Do not remove existing camp residents or cancel pending recruits on an individual player death.

The civilian departing toward camp does not require a fully simulated journey across maps. A short departure animation/path followed by mission-result resolution is a proposed initial implementation. Ongoing escorts, route combat, random travel losses, rediscovery, and deaths after a successful rescue resolution are not approved.

Population feedback should distinguish current camp residents from civilians pending on the active mission. Mission debrief should report arrivals/losses clearly. Early safe return can secure rescued civilians without completing the main objective. Exact UI, capacity constraints, rescue conditions, and timing when teammates return separately remain to be designed. See [mission structure](MISSION_STRUCTURE.md).

Recruitment and civilian construction/cooking roles are confirmed. Some residents may simply be NPCs rather than workers. Detailed assignments, hauling/harvesting, and the initial civilian's specific tasks remain open.

## How camp and missions connect

Mission outings obtain resources and help locals. Camp turns supplies into preparation, sustenance, repaired equipment, and lasting improvements. Players can contribute through camp work while others face the mission's risks.

Confirmed mission consequences:
- Carried equipment stays on a dead player's body for surviving teammates to recover; camp-stored supplies remain safe under the starting rule.
- Death locks the player out of that same mission. Equipping another weapon, changing location, or reconnecting must not bypass it.
- Surviving teammates continue, including when the host's character dies.
- Solo or total-group incapacitation resolves as mission death.
- Revival preserves injuries and reduced capability for a duration. Recovery timing and effects on camp labor remain undecided.

Camp work should provide useful choices without turning death into the best way to return supplies, instantly repair everything, or replenish an ongoing mission. These are design constraints; exact resource transfer rules still need approval.

## Functional structures — proposed interpretations

The owner requested town-like facilities. The following table proposes their functions without approving costs, recipes, production rates, or progression tiers.

| Facility | Player activity | Proposed role |
|---|---|---|
| Well / water collection point | Collect and store water | Supply cooking and camp needs; treatment/quality rules undecided |
| Food store | Deposit, sort, and retrieve food | Maintain shared provisions; spoilage is not approved |
| Cooking station | Prepare meals from ingredients and water where appropriate | Convert supplies into useful meals; nutrition effects undecided |
| Equipment storage | Organize communal gear | Show clear stock counts and locations; physical access and spending rules remain undecided |
| Weapon workbench | Repair weapons using approved supplies | Give weapon condition a practical recovery path; wear/malfunction details undecided |
| Ammunition storage | Gather, sort, and distribute ammunition | Prepare mission loads; this does not approve ammunition manufacturing |
| Shelters / camp buildings | Build functional spaces | Use the confirmed mixed construction model; exact pieces and facility layouts remain undecided |
| Trenches / earthworks | Perform digging/construction actions | Develop camp layout; raids, defensive combat benefits, and arbitrary terrain deformation are not approved |

Specific objects, materials, architecture, and tools must fit the selected Latvian setting and year. Valheim is a gameplay reference, not a historical reference or permission to reuse its assets/designs wholesale.

## Mixed construction — confirmed direction

The owner chose a mixture of freely placed pieces and predefined sites/upgrades. Both belong in the intended construction system.

Starting interpretation from the discussion: allow player-arranged shelter pieces and trench sections, while facilities such as wells and workshops use suitable predefined sites or structured upgrades. The mixed model is confirmed; the complete assignment of objects to each category remains open.

Placement bounds, snapping, foundations, terrain interaction, material costs, dismantling refunds, permissions, and upgrade requirements still need design. Freely placed pieces do not imply unrestricted terrain deformation or construction anywhere in the world.

## Communal stocks and visibility

All equipment and resources belong to the group. This includes weapons, ammunition, food, medicine, construction supplies, and gear recovered from a teammate's body. Inventory slots and carrying limits still track who physically holds an item; they do not establish private ownership.

Confirmed usability requirement: it must be easy to see how much of each resource the group has. Proposed stock display:
- Stored at camp and currently available.
- Reserved for building or other committed work, separately from available stock.
- Carried by mission participants, separately from camp stock.
- Gear left on mission bodies or otherwise unrecovered, excluded from usable camp stock.
- Planned construction cost and shortfall, shown before committing a plan.

These categories are a proposed interface, not settled accounting rules. Show units clearly, especially ammunition caliber/count, water quantity, and medical uses. Do not double-count containers, loaded ammunition, or reserved materials. Whether mission-side quantities are exact/live, last-known, or visible at all needs an explicit information rule.

Communal ownership does not permit teleporting an item from a distant player/body into camp storage. Storage access, logistics, building/spending permissions, and scarce-item conflicts still require rules.

## Planning tables and gradual upgrades

The mission table is a first-person interaction at headquarters, in a tent or bunker. Selecting missions there is confirmed direction; briefing, map annotations, equipment preparation, and group-ready confirmation are candidate functions to design.

The build-planning table opens a city-builder view to place plans within the mixed construction model. A plan is distinct from a completed building. Proposed feedback includes footprint, orientation, valid placement, upgrade compatibility, required materials, and shortages. Camera angle/bounds, placement grid, simultaneous planners, cancellation/refunds, and whether the mission continues while someone is planning remain detailed interface decisions. Planning must not globally pause teammates still on mission without an approved rule.

Confirmed progression: start with rough tents and improve buildings gradually. Example progression to discuss: a basic facility becomes weatherproof, then gains storage or work capacity. Exact tiers, bonuses, costs, historical appearance, and construction times are proposals. Upgrading must define what happens to stored items and an in-progress station task.

## Civilian labor — confirmed roles, unresolved detailed simulation

The owner confirmed that civilians construct buildings, cook, and perform similar camp jobs. Players can assist as foremen; exactly how assistance changes work is unresolved. Some civilians can simply be resident NPCs. Main-mission completion awards construction materials. Detailed assignments, worker suitability, hauling, tree harvesting, pathfinding, skills, wages, and schedules still need design; neither instant labor nor an elaborate workforce simulation is implied.

Prototype one civilian construction job and one cooking job after plans/resource accounting work. Add one player-assistance action to test the foreman role. A simple timed job is a possible feasibility step before visible hauling/tree harvesting, not a final presentation decision. Job durations, assignment UI, assistance benefits, and the supply-delivery system remain open.

## Starting scope — proposed

Prove one useful camp job alongside an active co-op mission, then introduce one functional building and a bounded trench interaction. Expand only after shared state, persistence, and concurrent use work.

For digging, compare authored trench segments or designated dig sites with deformable terrain before committing to technology. The player should feel they are digging; the implementation remains open.

Detailed automatic production chains, farming, raids, complex workforce simulation, player hunger/thirst meters, spoilage, weather damage, and ammunition crafting are not approved. Basic civilian work and lethal camp shortages are confirmed. They may be discussed later; the existence of food, wells, trenches, or a workbench does not imply those systems.

## Survival pressure and progression

Civilian shortages can cause deaths. Insufficient supplies can prevent adequately preparing for main-quest missions, pushing players into optional scavenging outings to recover. There is no permanent campaign game-over: decline makes survival harder, while scavenging must remain a viable route back. Exact food/water/shelter needs, warning/grace periods, consumption rates, and whether supplies are a formal deployment gate remain open.

Personal player hunger/thirst meters are not confirmed by the civilian survival rule. Scarcity must not accidentally soft-lock the campaign when all civilians or equipment are lost; a minimum viable scavenging/deployment rule still needs design, rather than silently granting free kits or unlimited resources.

Main-mission completion awards construction materials and unlocks further missions. Exact reward quantities, whether repeat completions grant materials, and other resource sources remain open. A medical facility becomes available after a handful of main missions and improves healing speed; exact timing and bonuses are deferred.

The current long-term goal is developing the forest settlement and resisting. No final victory, permanent defeat, or required campaign ending has been chosen.

Host-crash policy: all concurrent camp work, resource consumption, construction, cooking, civilian state, and mission changes roll back to the pre-deployment campaign state. This is distinct from normal mission failure, which preserves ordinary campaign consequences under the agreed rules.

## Shared resources, time, and permissions

These are unresolved design decisions, not permission to add a full management framework:
- All storage is communal. Who can withdraw, reserve, spend, dismantle, or cancel work, and what feedback prevents accidental conflicts?
- Can any participant place, modify, dismantle, or relocate a structure?
- How do concurrent tasks reserve and consume the same materials?
- Does work complete through active interaction, elapsed session time, or another rule?
- Can camp players sleep or advance time while friends remain on mission?
- Can resources move between camp and an active mission, and how is abuse prevented?
- A host crash restores pre-mission camp state, including unfinished/completed work during the outing. How should between-mission saving and intentional shutdown work?

Do not carry forward the earlier suggestion that every camp change waits until mission resolution as a confirmed rule. Hands-on camp work during missions is now required; consumption, completion, and time rules must support that.

## Injury and recovery considerations

Revival preserves injuries and temporary reduced capability. Decide whether penalties affect movement, carrying, aiming, and particular camp jobs. Keep enough useful work available that an injured or returned player can still contribute.

Do not assume mission death fully heals the player, camp entry clears all injuries, or timers continue while offline. Those rules require decisions. No real-world injury duration is implied by a gameplay timer.

## Questions for the owner

1. Which objects use freely placed pieces, which use predefined sites/upgrades, and what placement limits apply? The mixture is confirmed.
2. What are the upgrade stages from the confirmed rough tent camp, and how large should the settlement become?
3. Is gathering local materials around camp possible while a mission is active, and what risks exist there?
4. How are communal stock counts presented, which locations can supply a task, and who can reserve/spend supplies?
5. Which tasks remain available while injured, and what speeds recovery?
6. What civilian needs consume food/water, how quickly do shortages cause deaths, and are personal player survival meters wanted too?
7. Should work require active participation, timed completion, or both?
8. How should camp time interact with ongoing missions?
9. What feedback tells a player who died that surviving teammates secured the group's civilian arrivals?
10. How are civilians committed when teammates leave at different times, given that early safe return can secure them without main-quest completion?
