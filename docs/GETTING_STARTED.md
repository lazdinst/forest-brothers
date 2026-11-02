# Open and play the prototype

Engine: **Godot 4.7.2 standard**, GDScript, Compatibility renderer. No add-ons, paid assets, .NET SDK, or export templates are needed to run in the editor.

## Open and play

Import the repository's `project.godot` in Godot, then press **F5**. Stop an already-running version with **F8** before restarting.

The test yard now has three areas: the obstacle course on the left, a walking civilian at the far left, and a firing lane on the right. The original door, three pickups, communal stock display, and standing civilian remain. **Interaction moved from E to F** to make room for leaning.

The same **F5 testbed is now surrounded by dense woodland**: spruce, pine and birch, fallen logs, stumps, ferns, grass, moss clumps and leaf litter. The old box perimeter is open, with real gently uneven ground extending around the training clearing: low rises, hollows, sandy patches and damp soil. Test fixtures and firing lanes keep level footing. The camp/character annex is preserved.

**To enter the trench:** from the original spawn, turn around and go behind-left toward the trench entrance marker (approximately x −9, z 19). Walk down the slope. The main trench continues to z 33, with a left branch at z 27. It is physically below ground; walk back up the entrance slope to leave. Try crouching, leaning and ADS inside. This is an authored traversal fixture, not a player-digging or construction system. The forest is a finite prototype patch; use P if stuck or if you walk past its far edge. No separate scene launch is needed.

## Controls

| Input | Action |
|---|---|
| WASD / Mouse | Move / look |
| Shift | Sprint forward while standing; uses leg stamina |
| Space | Jump |
| Wheel / Caps Lock | Adjust walking pace / minimum-pace toggle |
| F3 (debug builds) | Show/hide developer diagnostics; hidden during normal play |
| Tap C / Hold C + wheel | Toggle full crouch / adjust seven stance heights |
| X | Toggle prone and restore previous stance when clear |
| Hold Ctrl | Temporary low crouch; blocked growth waits for clearance |
| K | Manually chamber a round |
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

See [tactical movement](TACTICAL_MOVEMENT.md) for tuning, stamina/load rules, inspection and focused checks.

## Suggested playtest

1. Turn left. Jump the short hurdle, use V at the next barrier, then climb onto the platform. The tall barrier should refuse climbing. Move close enough for the chest-height probe to find a marked obstacle; V is not free climbing.
2. Crouch through the low passage. Release Ctrl inside; you should stand only after leaving its roof. C and C + wheel also control persistent stance.
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
<godot> --headless --fixed-fps 60 --path . --script res://tests/training_environment_check.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/forest_terrain_check.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/reload_animation_smoke.gd
<godot> --path .
```

Checks exit nonzero on assertion failures. They exercise real scene collisions, traversal, aimed target hits, walking frame changes, and ammunition conservation. Headless checks do not establish game feel, animation quality, or multiplayer support. GPU-rendered course/range/walking frames were inspected on the GTX 1080; owner playtesting remains required for this increment. Keep generated `.godot/` caches ignored and commit script `.gd.uid` files.

Muzzle attachment/depth (0.85 m), 75 ms flash timing, and light intensity are prototype tuning. The weapon is still a 2D foreground sprite; full 3D barrel collision/retraction and network-visible gunfire are future work. Flash art provenance is in assets/MUZZLE_FLASH_PROMPT.md. Test hip/ADS firing near cover and verify light fades after each successful shot; empty/jammed attempts must not flash.

Weapon content, action timelines, and future animation authoring are documented in [Weapon Animation Workflow](WEAPON_ANIMATION_WORKFLOW.md). The training rifle is now labeled SVT-inspired; its generated art is not a verified historical model. Other loading mechanisms such as the Garand require distinct rules, not just different sprite clips.

## Camp / NPC / enemy annex

Restart F8 → F5. Walk behind the firing lanes and follow the **Camp / Workshops** signs east (approximately z 18) through the open entrance. The shooting range, movement course and camp/workshop/enemy area now share a continuous walkable map; return along the same path. No travel menu or teleport table is needed. Starting stores are stocked; the quartermaster cache is an optional extra. Choose **Do it yourself** at stations, or assign the civilian as cook/builder to delegate work, then try the well, kitchen, food store, armourer, ammo store, medical patient, shelter/trench sites, planning camera and HQ rescue exercise. The northern control table enables/reset opponents. Recipes, effects, labels and remaining limits are detailed in [Camp and Combat Tests](CAMP_AND_COMBAT_TESTS.md).

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

## Character art correction

The owner rejected the first polygon blockout. Normal camp residents, medical patient and both opponents again use preserved sprites; the optional polygon player body is off. Restart F8 then F5 to see the correction. The display near x -6, z 11 is labeled REJECTED ART / rig test only. The polygon smoke check now verifies normal defaults first, then explicitly enables rig fixtures. See MODULAR_CHARACTER_BRIEF.md for the next human/clothing proof; the previous integration description above is historical, not the normal-play default.

## Pine and deadwood inspection

Restart F8 → F5 and enter the training scene from the main menu. Existing forest pines now use detailed bark/needles and dead lower limbs. Walk into the woodland behind the range/near the trench for fallen pines, hollow rotten mossy logs, broken snags and loose dead/broken branches. First fallen pine is near x 18, z 15; a rotten mossy log is near x 19, z 33. V uses the existing vault controller on accessible low trunk sections. Loose branches do not block walking or shots.

Rebuild commands and exact texture prompts are in [Environment Asset Pipeline](ENVIRONMENT_ASSET_PIPELINE.md). Additional check: `<godot> --headless --fixed-fps 60 --path . --script res://tests/pine_debris_check.gd`. Art is still a detail candidate; LOD/performance and owner visual review remain pending.

Personal camp work: open a station with F and choose **Do it yourself**. Stay nearby with the panel open through the timer; closing or walking away cancels/refunds materials. Cooking, shelter upgrades and planned racks work without civilians. **Assign civilian** remains available for optional unattended cooking/building. Current work timing/UI is a prototype pending hands-on animation and playtesting.


## Environment asset lineup

Open `scenes/environment/environment_asset_test.tscn` in Godot and press **F6** (Run Current Scene). F5 still launches the normal project/menu. The separate inspection lane shows all 17 current standalone nature assets at their authored scale, each with a numbered label and description. Earlier spruce, log, stump and ground-cover meshes are retained alongside detailed pine/birch and new deadwood for comparison; no forest replacements were made in this gallery increment.

Use WASD/mouse to walk and inspect, Shift to run, **Page Up / Page Down** to jump to the previous/next specimen, P to return to the entrance, Escape to release the mouse and click to capture again. The gallery reuses player movement with a local unarmed view. It does not change training weapon controls.

Direct launch: `<godot> --path . res://scenes/environment/environment_asset_test.tscn`. Check: `<godot> --headless --fixed-fps 60 --path . --script res://tests/environment_asset_test_check.gd`.

## Character freeze and comparison

Both training enemies default to the painted sprite. At Enemy test controls use **Compare first enemy: Sprite (resets bout)** to reset with MPFB; use the corresponding MPFB button to return. This comparison resets the bout but preserves carried ammo and stock. Read CHARACTER_FREEZE_AND_COMBAT_SLICE.md for all five validated states, frozen issues and pending combat scope. Additional checks: `res://tests/mpfb_enemy_smoke.gd` and `res://tests/enemy_visual_parity_smoke.gd`, using the existing headless fixed-fps command format. Art sources are preserved in art_source/mpfb_enemy and excluded from Godot imports.

## Physical ammunition and equipment

Fresh training now carries two full ten-round magazines and one 32-round loose stack (52 total). Magazine A is inserted but the chamber starts empty: press K before firing. Magazine B and the stack use two of four pockets. R swaps magazines without chambering automatically; I performs a timed magazine inspection, revealing only an estimated category. T loads the carried spare; full magazines cannot accept more cartridges.

Open Tab and click a magazine, stack or rifle for paper actions: inspect, fill/unload, insert/remove, chamber/unload chamber, split/merge or drop. Drag items between free one-square pocket/pack slots, cartridges onto a magazine, matching stacks together, or a magazine onto the rifle. Dropped equipment is recovered with F and keeps its identity and contents. Camp stores are not shown in this screen. See AMMUNITION_INVENTORY.md for precise rules, original art provenance, snapshot API and focused check commands.


Minimal movement HUD: normal training now hides persistent headings, controls,
resource counts and weapon diagnostics. Contextual F interaction prompts stay
visible. Use F3 in debug builds for detailed state; release builds require
explicit developer-overlay enablement. See TACTICAL_MOVEMENT.md for the new
HUD layout and visual-review commands.
