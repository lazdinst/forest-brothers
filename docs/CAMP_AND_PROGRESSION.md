# Camp life and progression

Status: confirmed feature direction with proposed mechanics and unresolved balance. No gameplay is implemented.

## Confirmed by the owner — 2026-11-01

Camp is a playable place where players can work while friends continue a mission, including after returning from mission death. The owner cites Valheim as a reference for hands-on camp activities and functional buildings.

Confirmed activities and infrastructure:
- Organize communal equipment and supplies; make stock quantities easy to inspect.
- Build camp structures and dig trenches using a mixture of freely placed pieces and predefined facility sites/upgrades.
- Collect water, including wells as a desired camp structure.
- Store food and cook meals, with dedicated storage/cooking facilities.
- Repair weapons and gather/organize ammunition.

The camp starts rough, with tents, and develops through gradual building upgrades toward a more established forest settlement/hideout. A headquarters tent or bunker houses the mission-planning table. A separate build-planning table opens a city-builder view for placing plans. Specific upgrade tiers, construction complexity, materials, recipes, and the eventual settlement scale remain undecided.

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

## Civilian labor — owner-suggested proposal

The owner suggested directing civilians to construct buildings, move materials, and harvest trees. If adopted, this could connect helping locals with camp development. Recruitment, rescue-to-worker conversion, assignments, pathfinding, supplies, skills, wages, schedules, and danger are not approved by that suggestion.

Prototype plans and resource accounting first. A simple timed construction job is a possible feasibility step before visible hauling and tree harvesting, not an approved replacement for the desired presentation. Compare hands-on player work, civilian jobs, and a mixture before deciding how construction actually completes.

## Starting scope — proposed

Prove one useful camp job alongside an active co-op mission, then introduce one functional building and a bounded trench interaction. Expand only after shared state, persistence, and concurrent use work.

For digging, compare authored trench segments or designated dig sites with deformable terrain before committing to technology. The player should feel they are digging; the implementation remains open.

No automatic production chains, farming, raids, NPC workforce simulation, hunger/thirst meters, spoilage, weather damage, or ammunition crafting have been approved. They may be discussed later; the existence of food, wells, trenches, or a workbench does not imply those systems.

## Shared resources, time, and permissions

These are unresolved design decisions, not permission to add a full management framework:
- All storage is communal. Who can withdraw, reserve, spend, dismantle, or cancel work, and what feedback prevents accidental conflicts?
- Can any participant place, modify, dismantle, or relocate a structure?
- How do concurrent tasks reserve and consume the same materials?
- Does work complete through active interaction, elapsed session time, or another rule?
- Can camp players sleep or advance time while friends remain on mission?
- Can resources move between camp and an active mission, and how is abuse prevented?
- What happens to unfinished work when the host disconnects or the game is saved?

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
6. Are food and water camp stocks, player survival requirements, or both?
7. Should work require active participation, timed completion, or both?
8. How should camp time interact with ongoing missions?
