# Open and play the prototype

Engine: **Godot 4.7.2 standard**, GDScript, Compatibility renderer. No add-ons, paid assets, .NET SDK, or export templates are needed to run in the editor.

## Open and play

Import the repository's `project.godot` in Godot, then press **F5**. Stop an already-running version with **F8** before restarting.

The test yard now has three areas: the obstacle course on the left, a walking civilian at the far left, and a firing lane on the right. The original door, three pickups, communal stock display, and standing civilian remain. **Interaction moved from E to F** to make room for leaning.

## Controls

| Input | Action |
|---|---|
| WASD / Mouse | Move / look |
| Shift | Run forward |
| Space | Jump |
| Hold Ctrl | Crouch; stay crouched if the ceiling blocks standing |
| Q / E | Hold to lean left / right; head collision limits the lean |
| V | Vault a marked low barrier or climb the low platform when close and grounded |
| F | Open/close the aimed door or collect an aimed supply |
| Left mouse | Fire one shot |
| Hold right mouse | Aim down iron sights; slower movement |
| R | Swap the loaded and spare magazines, retaining their contents |
| Hold T | Transfer loose cartridges into the spare magazine, one at a time |
| J | Clear a jam |
| B | Clean the rifle (free test action) |
| G | Deliberately dirty the rifle for jam testing |
| I | Timed inspection placeholder; quantities currently stay visible in the HUD |
| P | Return to the starting position if stuck; does not refill ammunition |
| Escape / Click | Release mouse and stop movement input / capture again |
| F8 in editor | Stop the running project |

## Suggested playtest

1. Turn left. Jump the short hurdle, use V at the next barrier, then climb onto the platform. The tall barrier should refuse climbing. Move close enough for the chest-height probe to find a marked obstacle; V is not free climbing.
2. Crouch through the low passage. Release Ctrl inside; you should stand only after leaving its roof.
3. At the corner walls, hold Q/E. The view should move sideways and tilt, stopping before the camera enters the wall.
4. Find the patrolling older civilian at the far left. Walk around him to inspect front, mirrored side, and back walking frames. The original civilian remains idle.
5. At the right-hand firing lane, shoot the three targets. Hits flash orange and the HUD counts hits/shots. Start with a ten-round magazine, empty spare, and thirty loose rounds. Hold T to fill the spare, then R to swap. Try G, fire until a jam occurs, clear with J, and clean with B. Jam occurrence is random; G increases risk but does not force a jam.
6. Check the old door and three supplies with F; each communal count should increase once.

## Current limits and known TODO

These are local training fixtures, not campaign equipment. Quantities, timings, controls, weapon selection, and movement speeds are reversible prototype choices. Counts and ammunition reset on restart. The weapon rules live separately from the input/presentation controller; they have no multiplayer authority or communal-inventory integration yet.

The first-person character has generated hands/rifle artwork with procedural bob, recoil, lean, and action lowering. Reloading now uses a weapon-specific timeline with a separately moving painted magazine: withdraw, retain, insert, seat, and return to ready. Inspection and jam clearing have their own procedural pose clips. Hand artwork remains static; correct hand/mechanism poses are unfinished because the reload-sheet generation was rejected. Holding right mouse raises a dedicated rear-of-rifle view with the front-post tip aligned to the camera shot ray. The crosshair hides; world FOV stays at 60 degrees. Reloading, packing, cleaning, and vaulting interrupt aiming. The illustrated sights remain prototype artwork, not a verified technical reconstruction. Shots select an aim point through the sights, then trace from a short physical muzzle projected from the current gun sprite. Near-barrel cover blocks shots even when the camera can see past it. A four-frame muzzle-flash sprite follows the barrel, briefly relighting the existing gun/hands with warm highlights and illuminating nearby geometry. Tracers and synthesized sound are still placeholders; no ballistics, damage, enemies, friendly fire, or medicine exists yet. A shared polygon player-body animation proof now exists; the first-person weapon/hands remain sprites.

The civilian uses candidate four-frame walking atlases, not a finished animation set. Identity, stride, foot alignment, mirrored asymmetric details, and transitions need owner review and cleanup. Original generation outputs and prompts are preserved in `assets/TRAINING_ART_PROMPTS.md`.

**Deferred close-up sprite issue:** source TODO in `scripts/characters/directional_idle.gd`. The civilian stays upright and turns only horizontally toward viewer position. A temporary player-only clearance stops ordinary approach about 1.2 m from the center. Looking alone never changes sprite scale or camera FOV; aiming also preserves world FOV. Near-field proportions, elevated views, and final hitboxes still need a proper solution. Collision bit values: world/body 1, player 2, clearance 4; interaction and weapon rays ignore clearance.

No missions, saving, construction, jobs, combat AI, or multiplayer are implemented. The yard geometry, test sound, and new artwork remain placeholders. Three supply blocks deposit directly into a session ledger, not the future mission-return inventory.

## Main files

- `scenes/prototype/camp_test.tscn`: yard and HUD.
- `scripts/prototype/training_course.gd`: named course fixtures and target positions.
- `scripts/player/first_person_player.gd`: input, stance, collision-limited lean, swept traversal.
- `scripts/characters/directional_idle.gd`: facing, candidate walk frames, demo patrol, close-up TODO.
- `scripts/weapons/prototype_weapon_state.gd`: physical magazine/round and maintenance rules.
- `scripts/weapons/prototype_weapon.gd`: local input adapter, ray hits, art and sound presentation.

## Command-line checks

From the repository, replace `<godot>` with the installed executable:

```text
<godot> --headless --path . --import
<godot> --headless --path . --script res://tests/prototype_smoke.gd
<godot> --headless --path . --script res://tests/civilian_views_smoke.gd
<godot> --headless --path . --script res://tests/civilian_projection_smoke.gd
<godot> --headless --path . --script res://tests/weapon_state_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/training_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/ads_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/muzzle_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/reload_animation_smoke.gd
<godot> --path .
```

Checks exit nonzero on assertion failures. They exercise real scene collisions, traversal, aimed target hits, walking frame changes, and ammunition conservation. Headless checks do not establish game feel, animation quality, or multiplayer support. GPU-rendered course/range/walking frames were inspected on the GTX 1080; owner playtesting remains required for this increment. Keep generated `.godot/` caches ignored and commit script `.gd.uid` files.

Muzzle attachment/depth (0.85 m), 75 ms flash timing, and light intensity are prototype tuning. The weapon is still a 2D foreground sprite; full 3D barrel collision/retraction and network-visible gunfire are future work. Flash art provenance is in assets/MUZZLE_FLASH_PROMPT.md. Test hip/ADS firing near cover and verify light fades after each successful shot; empty/jammed attempts must not flash.

Weapon content, action timelines, and future animation authoring are documented in [Weapon Animation Workflow](WEAPON_ANIMATION_WORKFLOW.md). The training rifle is now labeled SVT-inspired; its generated art is not a verified historical model. Other loading mechanisms such as the Garand require distinct rules, not just different sprite clips.

## Camp / NPC / enemy annex

Restart F8 → F5. Turn behind-left at the original spawn and press **F** at the new annex table (approximately x −2, z 6). It connects the same player, weapon and communal ledger to the camp/workshop/enemy training area. The southwest return table brings you back. Claim the quartermaster cache once, assign the civilian as cook/builder, then try the well, kitchen, food store, armourer, ammo store, medical patient, shelter/trench sites, planning camera and HQ rescue exercise. The northern control table enables/reset opponents. Recipes, effects, labels and remaining limits are detailed in [Camp and Combat Tests](CAMP_AND_COMBAT_TESTS.md).

Additional checks:

```text
<godot> --headless --fixed-fps 60 --path . --script res://tests/camp_workshops_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/camp_annex_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/enemy_encounter_smoke.gd
```

These are local fixtures, not campaign completion. The earlier 'not implemented' limits refer to full campaign/network systems; bounded camp/medical/opponent tests now exist. No saving, co-op, real outings, player wounds, death/revive, cash trading or complete character animation is proven. The environment agent's art remains unchanged and its existing proof/integration checks also pass against this work.

## Polygon character proof

Latest art direction starts moving players/NPCs to rigged 3D GLB meshes. Restart F8 → F5; near **x −6, z 11** in the original training area, walk around the new character display and press F to cycle its eight poses. Camp residents, the medical cot, the first annex enemy and the player body now use the blockout rig. Look down for polygon legs, or use planning view for the complete player body. Original sprites remain as comparisons; first-person gun/hands are still sprites.

Source, rebuilding, import conventions, boundaries and next art work are in [Polygon Character Pipeline](POLYGON_CHARACTER_PIPELINE.md). Additional check:

```text
<godot> --headless --fixed-fps 60 --path . --script res://tests/polygon_character_smoke.gd
```

The models are original procedural geometry with simple skin weights and vertex colors, not final character detail or painted textures. The deferred near-field sprite workaround remains relevant only to the retained legacy comparisons.
