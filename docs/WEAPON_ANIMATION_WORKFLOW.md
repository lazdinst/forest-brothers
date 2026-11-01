# Weapon animation setup

The working rifle is **SVT-40-inspired prototype art**, not an authenticated M1 Garand model. The original prompt requested an SVT-like detachable ten-round magazine; the generated rear sight is visually inconsistent. The [Australian War Memorial SVT-40 record](https://www.awm.gov.au/collection/C246039) documents a ten-round detachable magazine. The [US National Park Service Garand history](https://home.nps.gov/spar/learn/historyculture/m1-variations.htm) describes its eight-round clip. Do not infer a final weapon roster or Latvian provenance from this placeholder.

## Current implementation

- `weapons/svt_inspired_training.tres`: this rifle's content definition and action timelines.
- `scripts/weapons/weapon_definition.gd`: identity, capacity, starting rounds, fire interval, hip/ADS art, sizes, sight/muzzle anchors, magazine mask, and action clips.
- `scripts/weapons/weapon_action_clip.gd`: action duration, insertion/effect timing, and presentation keyframes.
- `scripts/weapons/weapon_pose.gd`: keyframe time, phase, weapon offset/roll, magazine offset/visibility, and optional replacement frame texture.
- `scripts/weapons/prototype_weapon_state.gd`: mutable magazine/round state and action rules, independent of the renderer.
- `scripts/weapons/prototype_weapon.gd`: shared first-person controller, sampling the selected definition's presentation without weapon-name branches.

Each weapon can own separate `reload`, `clear`, `inspect`, `clean`, and `pack` clips. The current R reload visibly withdraws and retains the old magazine, brings the spare into place, seats it, and returns to ready. J uses a separate procedural action-check/clearing tilt, I an inspection tilt; they are not finished hand/mechanism animations. T and B retain their timed packing/servicing behavior. First-person gun/hand poses remain the existing artwork; a runtime shader separates the painted magazine without modifying the PNG.

**Art limitation:** the built-in image tool rejected the new reload-sheet request. No new reload sheet was produced and no external API fallback was used. Static hands, limited painted detail underneath the removed magazine, and sprite transitions still need replacement art. Do not describe the procedural prototype as a completed hand-animated reload.

## Adding another weapon

1. Create a new definition resource and stable ID. Copy the current definition as a starting point, then make its nested action/pose resources unique before editing; sharing an immutable clip is fine only when intentional.
2. Assign its own hip and ADS textures, view sizes, normalized sight/muzzle anchors, and physical muzzle depth. Check alignment in Godot at multiple window sizes, both lean directions, and against nearby cover.
3. Set capacity, starting rounds, and fire interval. These are prototype content values, not final balance. Never store the changing ammo count in a shared definition.
4. Author distinct action clips and poses. Pose `time` is normalized 0..1 and must increase. `offset` uses pixels at a 720px viewport, `roll_degrees` rotates the foreground gun. The sampled phase appears in the training HUD. Start/end at a neutral pose for a clean transition.
5. For an articulated magazine reload, enable `animate_magazine`, author magazine offsets/alpha, and supply a 3–8 vertex convex clockwise-in-UV polygon surrounding only the magazine in the hip artwork. Inspect intermediate frames: cutting wood or hands out of the main sprite is a defect.
6. For drawn hand animations, assign frame textures to the poses (ordinary textures or Godot AtlasTextures). A pose holds its frame until the next keyframe; its offsets interpolate smoothly. Frame art should use a consistent canvas/pivot. Drawn poses suppress the procedural magazine split so magazines are not duplicated. Preserve generated originals, prompts, and reference provenance.
7. Set the clip's `commit_at` marker where the ammunition transfer or maintenance effect becomes real. The rules use the same timeline as the art. Rendering callbacks never award cartridges or swap magazines.

`commit_at` is normalized: the current reload seats its magazine at 0.78 of 1.4 seconds. Firing stays locked until the complete action ends. A large time step crossing several phases commits only once. Cancellation before commit preserves the original magazines; cancellation afterward retains the completed swap. `cancel_action()` is ready for future weapon switching; there is no new cancel-key binding in this increment.

The shared rules currently support **detachable-magazine weapons only**, with two magazine instances in the test harness. Garand en-bloc loading, stripper clips, internal magazines, individual chamber rounds, bolt operation, empty/tactical reload variants, and multiple malfunction types require their own rule behavior and tests. Do not implement a Garand simply by changing the name and capacity. Presentation clips are extensible without hardcoding a new action animation into the player controller; different loading mechanisms still require gameplay work.

## Validation

Run the existing checks plus:

```text
<godot> --headless --fixed-fps 60 --path . --script res://tests/reload_animation_smoke.gd
```

The new check verifies insertion timing, cancellation before/after insertion, retained partial magazines, no double swap on large time steps, blocked firing, visible magazine movement, and a second test-only definition with different capacity/timing using the same controller. The test fixture is not an approved second weapon. GPU-rendered withdrawal, retention, insertion, and ready frames were inspected; owner review of motion remains necessary.

No networking authority, inventory equipment switching, final historical model, or full-body animation is implemented by these resources.
