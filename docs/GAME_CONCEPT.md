# Forest Brothers — game concept

Status: initial concept draft. See [the decision log](DECISIONS.md) for which choices the owner has confirmed.

## The premise

You are part of a small Latvian resistance group living in a concealed forest hideout after World War II. You venture into the surrounding countryside to obtain supplies, help local people, and sustain the camp under occupation.

The central question is: **what are you willing to risk to keep your people alive?**

The owner initially considered a mercenary role, then proposed a Forest Brothers-inspired group. A fictional local partisan is the current proposed protagonist; that identity is not yet final.

## Player experience

- Feel physically present through first-person movement, readable surroundings, and convincing sound.
- Feel vulnerable: encounters are dangerous, resources limited, and preparation matters.
- Care about returning with food or medicine because people at camp need them.
- Make meaningful choices about what to carry, whom to help, and when to return.
- Build familiarity with a small place and its people over repeated outings.
- Eventually share that experience with friends; solo play remains important.

Tarkov is a reference for immersion, tension, and consequences. This game is not an extraction shooter: the proposed campaign revolves around the needs of a continuing resistance camp, local relationships, and lasting world state. Session and map transitions remain undecided.

## Core loop — proposed

1. At camp, learn about a need, prepare equipment, and choose a task.
2. Travel through a compact area of woodland and rural settlements.
3. Explore, gather resources, help locals, and decide whether to engage or avoid threats.
4. Return with what you recovered, living with the cost of the journey.
5. Apply supplies and mission outcomes to the camp; choose what to attempt next.

## Design pillars

### People give supplies meaning
Food, medicine, and ammunition support survival and specific human needs. Avoid making every object valuable only because it can be sold.

### Danger with understandable consequences
The owner wants punishing play. Threats and consequences should be legible enough that players can learn. Exact injury, death, recovery, and save rules are open questions.

### Latvia shapes the world
Landscape, architecture, language, objects, and lived experience should establish place. Research these details rather than relying on a generic Eastern European visual shorthand.

### Small environments with depth
Begin with a compact playable location and a few interacting systems. Scale by adding authored areas, tasks, and content once the core loop works.

### Cooperation belongs in the foundation
Build toward multiplayer without assuming a single global player. Proposed initial format: small-group cooperative play with a host-owned campaign. Player count and PvP scope are unconfirmed.

## Visual and audio direction

Intended direction: low-resolution first-person environments with sprite-based characters and objects. A practical proposed approach is simple 3D geometry with billboard sprites. Validate this in a prototype before committing to a large asset pipeline.

Favor coherent silhouettes, clear interactions, atmospheric sound, and restrained detail. Retro graphics must still let players identify threats, read objects, and navigate. Full-body directional sprites, weapon presentation, and exact resolution remain undecided.

Development target: an accessible workflow on the owner's GTX 1080-class machine. The owner reports substantial RAM but possible instability; actual performance must be measured rather than inferred from capacity alone.

## Setting and historical approach

The broad setting is grounded in Latvia's national partisan resistance to Soviet occupation after World War II. Latvian military heritage sources describe the movement as operating from 1944 to 1956 and document concealed bunkers and resistance groups.

Sources to begin research:
- [National partisans / Forest Brothers](https://militaryheritagetourism.info/en/military/topics/view/105)
- [Partisan / guerrilla bunker](https://militaryheritagetourism.info/en/military/topics/view/99?lang=en)
- [Museum of the Occupation of Latvia](https://okupacijasmuzejs.lv/en)

Proposed approach: fictional characters and locations within a researched historical setting. Exact year, region, realism level, and treatment of historical events need owner input. A concealed bunker with a few shelters is a suggested starting hideout; the owner's broader forest village idea remains available for discussion.

## First playable slice — proposed

A short mission: recover medicine from a nearby farmhouse and return to help an injured camp resident.

- One compact forest area connecting a camp and farmhouse.
- Basic first-person movement and interaction.
- One item pickup and a simple inventory before expanding resource types.
- One firearm and one enemy type once interaction works.
- A camp resident and visible mission result.
- Early two-player proof of shared interactions, followed by the complete loop in solo and co-op.

This slice is a learning and feasibility exercise, not a commitment to a final campaign mission.

## Outside the first slice

Large open worlds, competitive PvP, AI squad command, complex construction, vehicles, elaborate crafting, extensive weapon modification, procedural campaigns, matchmaking, host migration, and dedicated-server operations are deferred. These are scope boundaries for the prototype, not permanent exclusions.

## Questions to settle

1. Is multiplayer cooperative only, and what player count should we target?
2. Is the protagonist a fictional Latvian partisan, or a different role?
3. Which region and period should anchor the setting?
4. How severe should death and failure be? What can a player recover?
5. Should play be organized into missions, connected areas, or a continuous world?
6. How much camp management should be hands-on versus handled through decisions?
7. What are the desired balance of combat, stealth, exploration, and civilian assistance?
