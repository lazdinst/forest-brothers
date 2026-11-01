# Open and play the first prototype

Engine: **Godot 4.7.2 standard**, GDScript, Compatibility renderer. No add-ons, paid assets, .NET SDK, or export templates are needed to run it in the editor.

## Open the project

1. Launch Godot. In the Project Manager, choose **Import**.
2. Select `project.godot` in the repository root and open the project.
3. Press **F6** to run the currently open test scene, or **F5** to run the project.

You should see a small blockout yard and storehouse with a supplies door, plus the approved older civilian sprite to the right of the starting position. Walk around him to test front, side, and back idle views. The other side currently mirrors the profile, including its asymmetric patches. He has body collision but no walking animation, dialogue, or job behavior yet. Walk up to it, aim at it, and press E. Collect the three colored supply blocks on the table; the communal counts should increase once each.

## Controls

| Input | Action |
|---|---|
| W A S D | Move |
| Mouse | Look |
| Shift | Run |
| Space | Jump |
| E | Open/close the aimed door or collect an aimed supply |
| Escape | Release the mouse and stop movement input |
| Click | Capture the mouse again |
| F8 in the editor | Stop the running project |

Movement values, input bindings, camera height/FOV, and interaction distance are prototype choices, not final balance. Edit movement exports on the Player scene and bindings in Project Settings > Input Map.

## What exists

- A reusable local first-person character, collision, gravity, mouse look, and a short interaction ray.
- An animated door with collision and three one-shot pickups.
- A scene-owned communal stock ledger and readable counts.
- A headless integration check exercising movement, collisions, door traversal, and duplicate-pickup prevention.

The geometry and colors are placeholders for testing. No final art, sound, multiplayer, inventory/carrying system, missions, construction, medicine, or saving is implemented. Collecting these three items deposits directly into the test ledger; it is not the final mission-to-camp logistics rule. Counts reset when the project restarts.

## Files to explore

- `scenes/prototype/camp_test.tscn`: the editable test environment and HUD.
- `scenes/player/first_person_player.tscn`: player collider, camera, and interaction ray.
- `scripts/player/first_person_player.gd`: local movement/input and interaction targeting.
- `scripts/interactions/`: door and pickup behavior.
- `scripts/state/camp_stock.gd`: session-owned sample supply counts.

## Command-line checks

Run these from the repository, substituting your actual Godot executable path for `<godot>`:

```text
<godot> --headless --path . --import
<godot> --headless --path . --script res://tests/prototype_smoke.gd
<godot> --headless --path . --script res://tests/civilian_views_smoke.gd
<godot> --path .
```

The integration check runs the real scene, then exits with a nonzero code if a check fails. Headless checks do not verify graphics or game feel; use the editor for visual/play testing. Generated `.godot/` caches stay ignored. Commit `.gd.uid` files generated alongside scripts so Godot can preserve resource identities.
