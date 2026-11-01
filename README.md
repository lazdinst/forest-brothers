# Forest Brothers

**Mežabrāļi** — a working concept for an immersive first-person survival game set in postwar Latvia, centered on supporting a small forest resistance camp.

Venture into nearby settlements and woodland, recover supplies, help local people, and bring what you can back to those depending on you. Play alone or in co-op with up to four players. Teammates can treat and revive you during a limited incapacitation window; mission death sends you back to camp while survivors continue. Combat is dangerous; food, medicine, and relationships matter alongside ammunition.

The project now has a **local movement, animation, and firing-range prototype** in Godot 4.7.2 standard (Compatibility renderer). Import `project.godot` and press **F5**. Walk with WASD, look with the mouse, interact with F, and explore the obstacle course and firing lane. Ctrl crouches, Q/E lean, V vaults/climbs, and the mouse fires/aims. See [Getting Started](docs/GETTING_STARTED.md) for controls, checks, and current limitations.

The local training yard also connects to a **camp/workshop/NPC and opponent annex**. Turn behind-left at spawn and use F at its table. [Camp and Combat Tests](docs/CAMP_AND_COMBAT_TESTS.md) covers every station, planning, rescue exercises and enemy controls. These remain local tests rather than a saved/co-op campaign.

The character migration now has a [rigged polygon/GLB proof](docs/POLYGON_CHARACTER_PIPELINE.md). In the original test area, use F at the character display near x −6, z 11 to cycle poses. The owner rejected the blockout appearance; normal-play characters use the preserved sprites and the display is labeled as a rejected art/rig fixture. [The modular character brief](docs/MODULAR_CHARACTER_BRIEF.md) defines the better human base, interchangeable clothing and visual review required before migration resumes.

## Project context

- [Game concept](docs/GAME_CONCEPT.md): vision, player experience, scope, and open questions.
- [Mission structure](docs/MISSION_STRUCTURE.md): quest progress, early return, randomization, timeouts, reconnection, and crash rollback.
- [Missions and medicine](docs/MISSIONS_AND_MEDICINE.md): four-player co-op, individual death, revival, and period-grounded injury treatment.
- [Weapon animation workflow](docs/WEAPON_ANIMATION_WORKFLOW.md): per-weapon action clips, reload timing, art requirements, and current limitations.
- [Combat design](docs/COMBAT_DESIGN.md): approved perception/searching, manual magazine loading, maintenance-dependent jams, and friendly fire.
- [Camp and progression](docs/CAMP_AND_PROGRESSION.md): hands-on building, food, water, storage, maintenance, and concurrent camp activity.
- [Art direction](docs/ART_DIRECTION.md): gritty painted sprites, agent-assisted production, and an early visual feasibility test.
- [Technical direction](docs/TECHNICAL_DIRECTION.md): proposed Godot foundation and early co-op planning.
- [Roadmap](docs/ROADMAP.md): small, verifiable milestones.
- [Decision log](docs/DECISIONS.md): confirmed direction versus working assumptions.
- [Agent instructions](AGENTS.md): collaboration and implementation expectations.

Start with the concept and root agent instructions before making changes. Use Godot **4.7.2 standard**, GDScript, and the Compatibility renderer for this prototype. The scene uses placeholder geometry; final art, multiplayer, missions, construction, and saving are not implemented yet.

Repository visibility must remain private. Do not publish source, builds, or assets without the owner's instruction.
