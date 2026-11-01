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

The first-person character has generated hands/rifle artwork with procedural bob, recoil, lean, and action lowering. Reloading, inspection, and cleaning use timed lowering rather than correct hand/magazine animation. Holding right mouse raises a dedicated rear-of-rifle view with the front-post tip aligned to the camera shot ray. The crosshair hides; world FOV stays at 60 degrees. Reloading, packing, cleaning, and vaulting interrupt aiming. The illustrated sights remain prototype artwork, not a verified technical reconstruction. Shots are immediate camera rays with placeholder tracers, flash, and synthesized sound; no ballistics, damage, enemies, friendly fire, or medicine exists yet. Full-body player animation is not implemented.

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
<godot> --path .
```

Checks exit nonzero on assertion failures. They exercise real scene collisions, traversal, aimed target hits, walking frame changes, and ammunition conservation. Headless checks do not establish game feel, animation quality, or multiplayer support. GPU-rendered course/range/walking frames were inspected on the GTX 1080; owner playtesting remains required for this increment. Keep generated `.godot/` caches ignored and commit script `.gd.uid` files.
