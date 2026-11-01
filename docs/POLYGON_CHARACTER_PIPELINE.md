# Rigged polygon character migration

The owner requested moving players and NPCs from flat sprites toward polygonal 3D characters. Godot and Compatibility rendering remain the engine/toolchain. The gritty illustrated direction remains a visual goal; the new meshes are **geometry/rig blockouts**, not finished characters, painted-texture assets or a verified historical wardrobe.

## What is playable now

Restart **F8 → F5**. Near the southwest part of the original test area, around **x −6, z 11**, there is a polygon character display. Walk around it and use **F** to cycle idle, walk, run, crouch, aim, reload, interaction and death clips. Its mesh stays oriented in the world as the camera moves around it.

Camp residents and the medical cot in the annex now use 3D meshes. The first enemy is polygonal and uses its skeletal death clip; the second remains a sprite comparison. The player has a polygon body driven by movement, stance and action state. Look down to see legs; the head, torso and arms cast shadows but are hidden from the local first-person view to prevent camera clipping. The overhead planning view reveals the full player model, then restores local visibility afterward.

The original yard civilian/walking sprite and source art remain as references. This is a staged migration, not a claim that every character/weapon asset is converted. The first-person gun and hands are still the existing sprite presentation; 3D weapon meshes, calibrated hand contact, weapon-specific skeletal reloads, camera-to-head alignment and first-person IK are separate work. The new `aim` and `reload` clips demonstrate body pose control, not correct operation of a completed 3D firearm.

## Asset format and source

Use **glTF 2.0 binary (`.glb`)** for imported rigged characters. It carries meshes, skin weights, materials, bones and animation clips in a portable asset. Godot's native scene format wraps those imports with gameplay scripts; do not put damage, inventory awards or mission rules into an imported model. [Godot glTF import/export](https://docs.godotengine.org/en/stable/classes/class_gltfdocument.html), [Skeleton3D](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html).

Files in the repository:

- `assets/characters/polygon_humanoid/civilian_v1.glb`: brown-clothed civilian blockout.
- `assets/characters/polygon_humanoid/guard_v1.glb`: olive field-clothed blockout, also reused for the player. No duplicate player mesh file is needed.
- `assets/characters/polygon_humanoid/source/humanoid_builder.gd`: original editable mesh, palette, bone and animation recipe.
- `assets/characters/polygon_humanoid/source/bake_humanoids.gd`: exports the source to the two GLBs.
- `assets/characters/polygon_humanoid/source/humanoid_post_import.gd`: preserves vertex-palette appearance in Godot editor imports.
- `scripts/characters/polygon_character.gd`: common presentation adapter, animation selection/sampling, hit tint and local body visibility.
- `scripts/characters/polygon_showcase.gd`: interactive animation display.

These assets are original procedural geometry. No downloaded model, external generation service, paid asset, new software installation or raster-image generation was used. Existing sprite sources remain untouched. Vertex colors provide temporary flat/faceted shading; there is no painted UV texture set yet.

## Rig contract

- Units: meters. Y is up; the authored character faces **+Z**. The player visual rotates 180 degrees to follow the controller's −Z forward direction.
- 32 bones: Root, Hips, Spine, Chest, Neck, Head; Shoulder/UpperArm/LowerArm/Hand and Thigh/Shin/Foot/Toe for L/R; five finger bones on each hand.
- Mesh vertices have skin weights, with body volume and facial/clothing geometry. This is not a stack of billboard planes. Current weights are deliberately simple; detailed deformation/weight painting remains an art task.
- Three skinned groups: legs, torso, head/arms. The latter two support local first-person shadow-only rendering. This local prototype uses per-instance visibility; multiplayer will require ownership/camera-aware visibility.
- Named hand attachments are included as future weapon/prop sockets. They do not yet implement hand IK or a complete 3D weapon rig.
- Animation clips are presentation only. Player actions sample the existing weapon-rule progress; no animation callback manufactures ammunition, clears a jam or changes job results.
- Imported static/reset tracks are retained. This prevents a prior crouch/death pose from leaking into idle when changing animation.

## Rebuild and test

From the repository, replace `<godot>` with the installed Godot 4.7.2 console executable:

```text
<godot> --headless --path . --script res://assets/characters/polygon_humanoid/source/bake_humanoids.gd
<godot> --headless --path . --import
<godot> --headless --fixed-fps 60 --path . --script res://tests/polygon_character_smoke.gd
```

Commit source, GLBs, their `.import` settings and `.gd.uid` files; keep `.godot` caches ignored. Regeneration deliberately replaces these versioned generated GLBs; preserve a sibling version before making an art experiment you want to compare.

The rig check verifies imported bone/clip presence, actual foot displacement, crouch height and standing reset, skeletal death, player visibility/locomotion, non-billboard NPC orientation, combat animation selection and overhead visibility restoration. Existing workshop, rescue, damage, movement and weapon checks remain required. GPU-rendered showcase, civilian, opponent, player-leg and crouched-ADS views are inspected; this is not a crowd-performance benchmark or multiplayer validation.

## Next art/animation work

Improve one character before producing a roster: proportions, face/age, clothing folds and silhouette; UV unwrap and painted albedo/roughness textures; cleaner skin weights, foot contact and locomotion blending. Define a humanoid bone-map/retarget convention before importing outside animation packs. Then add a 3D weapon/hand rig with aim alignment, magazine/chamber parts, separate tactical/empty reload behavior and malfunction actions tied to the existing authoritative timelines. Imported assets require license/provenance review.

Retire the remaining sprites and their artificial close-up clearance only as each replacement is verified. Preserve civilian IDs/jobs/recruitment, enemy damage/perception, camera controls, communal resources and mission rules while swapping presentation. Do not rebuild environment assets: the separate forest agent owns that pipeline and has reserved the rig-showcase/annex locations in its layout.
