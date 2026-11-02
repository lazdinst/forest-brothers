# Forest Brothers — game concept

Status: initial concept draft. See [the decision log](DECISIONS.md) for which choices the owner has confirmed.

## The premise

You begin in a rough Latvian forest camp around 1946 with one civilian, suggested as an old man. You venture into the surrounding countryside to obtain supplies, help local people, and develop a resistance hideout under occupation. Rescued civilians receive directions and run off toward camp; they become residents when the mission resolves successfully. Solo/total-group mission death loses those pending arrivals; surviving co-op teammates can secure them even if the rescuer dies.

The central question is: **what are you willing to risk to keep your people alive?**

The owner initially considered a mercenary role, then proposed a Forest Brothers-inspired group. A fictional local partisan is the current proposed protagonist; that identity is not yet final.

## Player experience

- Feel physically present through first-person movement, readable surroundings, and convincing sound.
- Feel vulnerable: encounters are dangerous, resources limited, and preparation matters.
- Care about returning with food or medicine because people at camp need them.
- Make meaningful choices about what to carry, whom to help, and when to return.
- Build familiarity with a small place and its people over repeated outings; develop a hands-on camp with structures, trenches, water, food storage, cooking, and weapon maintenance.
- Share that experience in co-op with a maximum of four players; solo play remains important.

Tarkov is a reference for immersion, tension, and consequences. This game is not an extraction shooter: the proposed campaign revolves around the needs of a continuing resistance camp, local relationships, and lasting world state. Mission outings from camp and individual return to camp after death are confirmed; detailed map transitions remain undecided. Surviving teammates continue their mission.

## Core loop — proposed

1. At the headquarters mission table, learn about a need, prepare communal equipment, and choose a mission alone or with a group of up to four players.
2. Deploy to the first handcrafted map, with randomized supplies and selected portions. A Latvian town/city is an example location. Outings last at most one hour; timeout kills players still on-map.
3. Explore, gather resources, help locals, and decide whether to engage or avoid threats.
4. Return with what you recovered, living with the cost of the journey. You may leave early with supplies and civilians while the main quest remains incomplete; quest progress, supplies, and rescue outcomes are separate. If incapacitated, teammates have a limited opportunity to revive you; if you die, you return to camp while they continue.
5. Use supplies to sustain and develop camp: organize equipment, build, dig trenches, collect water, cook, store food, repair weapons, and gather ammunition. Players who died can work at camp while survivors continue. They cannot rejoin that same mission.

## Design pillars

### People give supplies meaning
Food, medicine, and ammunition support survival and specific human needs. Avoid making every object valuable only because it can be sold.

### Danger with understandable consequences
The owner wants punishing play. Threats and consequences should be legible enough that players can learn. Individual mission death returns the player to camp, not a group-wide restart. Incapacitation allows a limited teammate revival window. Distinct medical resources address light/heavy bleeding, fractures, and pain with period-appropriate presentation. The starting rule leaves carried equipment on the body for teammate recovery and protects camp-stored supplies. Solo or total-group incapacitation resolves as mission death. Revival preserves injuries and reduced capability for a duration; exact balance and recovery remain open. See [missions and medicine](MISSIONS_AND_MEDICINE.md).

### Latvia shapes the world
Landscape, architecture, language, objects, and lived experience should establish place. Research these details rather than relying on a generic Eastern European visual shorthand.

### Small environments with depth
Begin with one handcrafted mission map and a compact playable slice. Randomize supplies and selected portions; exact modular variation remains open. Scale with further authored locations after the loop works. See [mission structure](MISSION_STRUCTURE.md).

### Cooperation belongs in the foundation
Support solo play and co-op with a maximum of four players. A player returning to camp after death must not interrupt teammates still on a mission. A host-owned campaign is the proposed initial format; competitive PvP is not approved.

### Camp is a place to play
Hands-on camp life is confirmed product scope, with Valheim as the owner's reference for building and productive activities. Wells/water infrastructure, food storage, cooking facilities, equipment organization, trenches, and weapon repair support preparation and give returned players useful work. Start with rough tents and gradually upgrade buildings. All supplies are communal and quantities must be easy to inspect. The headquarters mission table organizes outings; the build-planning table opens a city-builder view to place plans. Construction combines freely placed pieces with predefined facility sites/upgrades. Camp population grows through mission rescues, with new residents arriving at mission resolution. Players can cook and construct directly; civilians can also perform these jobs, and players may help as foremen, and some residents may simply be NPCs. Main-mission completion rewards building materials and unlocks further missions. Shortages can kill residents and force optional scavenging, but there is no permanent game-over. Detailed hauling and tree harvesting remain unconfirmed. Specific structures and progression rules are detailed in [camp and progression](CAMP_AND_PROGRESSION.md). Larger construction systems follow a minimal proof, rather than blocking the first playable mission.

### Deliberate combat and preparation

Owner-directed tactical movement adds adjustable walking pace, seven stance heights and separate prone, inertia, independent leg/arm stamina, load penalties and movement noise. These are implemented as local training rules with provisional numerical tuning; see [tactical movement](TACTICAL_MOVEMENT.md).
Enemies recognize visible players over exposure, investigate approximate sound locations, search last-known areas, and spread alerts locally. Searches can eventually decay, allowing successful concealment. Ammunition is physical: loose cartridges refill magazines manually, and partial magazines retain their contents. Weapons can jam more often when neglected; cleaning/service and repair matter. Friendly fire can injure and incapacitate teammates. These behaviors are confirmed; numerical balance and detailed interfaces remain open. See [combat design](COMBAT_DESIGN.md).

## Visual and audio direction

Latest owner direction: migrate players and NPCs to rigged polygonal 3D meshes while retaining a gritty illustrated finish. The earlier sprite-first approach is superseded for new character work; original sprites remain reference/comparison assets during rollout. The first procedural GLB blockout was rejected on appearance and clothing scalability. Normal training play uses the preserved sprites while a believable modular human with separate garments is developed. Read [the modular character brief](MODULAR_CHARACTER_BRIEF.md); the rig test is not an approved visual foundation. See [art direction](ART_DIRECTION.md) and [polygon character pipeline](POLYGON_CHARACTER_PIPELINE.md).

Favor coherent silhouettes, clear interactions, atmospheric sound, and restrained detail. Retro graphics must still let players identify threats, read objects, and navigate. Final mesh complexity, painted textures, skeletal animation quality, first-person weapon/hand presentation, and exact render resolution remain to be settled through playtests.

Development target: an accessible workflow on the owner's GTX 1080-class machine. The owner reports substantial RAM but possible instability; actual performance must be measured rather than inferred from capacity alone.

## Setting and historical approach

The broad setting is grounded in Latvia's national partisan resistance to Soviet occupation after World War II. Latvian military heritage sources describe the movement as operating from 1944 to 1956 and document concealed bunkers and resistance groups.

Sources to begin research:
- [National partisans / Forest Brothers](https://militaryheritagetourism.info/en/military/topics/view/105)
- [Partisan / guerrilla bunker](https://militaryheritagetourism.info/en/military/topics/view/99?lang=en)
- [Museum of the Occupation of Latvia](https://okupacijasmuzejs.lv/en)

Proposed approach: fictional characters and locations within a researched historical setting. The working year is approximately 1946; exact region, realism level, and treatment of historical events still need owner input. The confirmed starting camp is rough tents, with gradual upgrades to functional buildings. Headquarters may be a tent or bunker as the camp develops. How large or visible the forest settlement becomes remains open.

## First playable slice — proposed

A short mission: recover medicine from a nearby farmhouse and return to help an injured camp resident.

- One compact forest area connecting a camp and farmhouse.
- Basic first-person movement and interaction.
- One item pickup and a simple inventory before expanding resource types.
- One firearm and one enemy type once interaction works.
- A camp resident and visible mission result.
- A minimal injury/revive test: incapacitation, timed teammate treatment, individual mission death, and return to camp while another player continues. Expand to the full medical range incrementally.
- Early two-player proof of shared interactions, followed by the complete loop in solo and co-op; validate the four-player maximum before expanding content.

This slice is a learning and feasibility exercise, not a commitment to a final campaign mission.

## Outside the first slice

Large open worlds, competitive PvP, AI squad command, complex construction, vehicles, elaborate crafting, extensive weapon modification, procedural campaigns, matchmaking, host migration, and dedicated-server operations are deferred. These are scope boundaries for the prototype, not permanent exclusions.

## Questions to settle

1. Is any competitive multiplayer ever desired? Co-op is confirmed at a maximum of four; PvP remains outside the prototype.
2. Is the protagonist a fictional Latvian partisan, or a different role?
3. Which Latvian region and settlement should anchor the working setting around 1946?
4. How long do injuries and capability penalties persist, what recovery happens at camp, and how is communal equipment physically recovered from a teammate's body?
5. How are mission outings and concurrent camp activity represented across maps? Dead players cannot rejoin the same mission; reconnect rules must preserve that lockout.
6. How do building placement, trenches, camp permissions, shared resources, and time progression work? Hands-on camp work is confirmed.
7. What detection/search timing, loading/clearing interactions, jam/maintenance rates, and friendly-fire damage tuning best support the approved combat behavior? See [combat design](COMBAT_DESIGN.md).

## Ammunition inventory clarification

The owner has specified physical magazine/weapon instances, 32-round loose stacks, separate chamber state, and inspection-based magazine estimates instead of exact magazine counts in the UI. This extends the existing manual-loading/retained-magazine direction without changing communal ownership or mission consequences. The personal screen shows only carried items; camp stores remain a separate interaction. See AMMUNITION_INVENTORY.md for the implemented local training scope and remaining campaign/network work.
