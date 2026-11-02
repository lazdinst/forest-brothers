# Art direction and production

**Walking sprite follow-up:** the owner requested walking animation. Eight low-ready four-frame directional sheets are now integrated as candidates with distance-driven playback, ground/body anchoring and combat pose priority. [Source sheets, exact prompts and validation](../assets/characters/training_guard/walking_v1/PROVENANCE.md); the native phase captures and review GIF await owner motion/appearance approval. No frozen mesh source was changed.

**Firing sprite follow-up:** owner requested slightly illuminated firing art with a small muzzle flash. Eight candidate firing views now briefly replace aiming on real shots. Reflected light is painted into the character, not cast onto the world. [Source, prompt and checks](../assets/characters/training_guard/firing_v1/PROVENANCE.md); owner motion/appearance review remains pending.

**Rifle pose follow-up:** the owner authorized holding-at-rest and aiming sprite poses after standing views. Both eight-direction candidate atlases are integrated; [source art, prompts and validation](../assets/characters/training_guard/rifle_poses_v1/PROVENANCE.md) are preserved. These are static poses awaiting owner visual review, with full action animations still pending.

**2026-11-02 enemy-only exception:** the owner authorized eight directional standing sprite views first and rejected further 3D body work. A candidate atlas is connected to actual enemy facing; [source, prompts and validation](../assets/characters/training_guard/standing_v1/PROVENANCE.md) are preserved. Original sprites and frozen 3D sources remain intact. Action frames and grounded body sprites are follow-up chunks, not part of this standing proof. Owner visual approval remains pending.

**Current owner priority: character art is frozen.** Preserve MPFB sources/rig/clips/clothes; do not create outfits or polish appearance. Sprites are the default; retain MPFB for comparison. See [CHARACTER_FREEZE_AND_COMBAT_SLICE.md](CHARACTER_FREEZE_AND_COMBAT_SLICE.md) for validated defects and the pending combat-first proposal. This supersedes further production steps below.

Status: the owner rejected the first procedural polygon models as visually worse than the sprites and unsuitable for varied clothing. Normal play uses the preserved sprites while better rigged models remain the target. Require a believable base human and separate interchangeable garments; read [MODULAR_CHARACTER_BRIEF.md](MODULAR_CHARACTER_BRIEF.md). The first GLB rig is a blockout test, not approved final character art. Read [POLYGON_CHARACTER_PIPELINE.md](POLYGON_CHARACTER_PIPELINE.md) for current work. Earlier sprite experiments below remain preserved history/reference. The owner approved the first painted front-view starting civilian appearance on 2026-11-01. A four-direction idle experiment with a body collider is now in the movement test: approved front plus new side/back candidates and a mirrored opposite profile. Side/back approval, animation, final direction count, and final sprite resolution remain pending. See [the asset and generation prompts](../assets/characters/starting_civilian/README.md). This is a visual candidate, not a completed sprite animation pipeline.

## Confirmed direction

Gritty illustrated presentation remains the style goal in the postwar Latvian first-person setting. Characters now move toward polygon meshes, skeletons and animation clips; painted textures and final detail remain future art work. The earlier sprite-only character direction is superseded by the owner request, with source art retained for reference.

The camp starts with rough tents and progressively upgraded buildings. The visual system must support first-person play and a city-builder planning view. A sprite-only solution for every building is not selected; simple 3D structures with generated textures remain a candidate.

## Initial feasibility test — proposed

Create one coherent small scene before producing a large library:
- One fictional character reference with approved clothing, equipment, proportions, and colors.
- A limited set of matching directional/animation frames, expanded only after consistency is demonstrated.
- One first-person weapon/hands view to test framing and perspective.
- A tent, planning table, storage prop, and a small material/texture set.
- One rough and one upgraded version of a functional facility.

Check characters against woodland and camp backgrounds, and check facilities from first-person and the planning camera. Test scale and readability in motion as soon as an engine scene exists.

## Legacy sprite production workflow

1. Research setting references; label fictional adaptations and unresolved historical details.
2. Establish an owner-approved style/reference sheet: palette, lighting, proportions, silhouette, texture detail, and perspective.
3. Choose a small asset specification: canvas size, in-game scale, pivot, directions, frames, and transparency. Values remain unset until tested.
4. Generate candidates against approved references; preserve references and generation instructions. Do not assume independent generations will match.
5. Check and prepare transparency, alignment, frame order, edge quality, and consistent proportions. Expect iteration and cleanup rather than promising perfect generated animation sheets.
6. Preview frames as an animation and inside the game; inspect changes in identity, scale, equipment, lighting, and foot alignment.
7. Keep accepted assets separate from rejected candidates; record provenance and relevant usage rights for source references and third-party material.

The production guide is not authorization to purchase assets or use unlicensed reference material. Use the image-generation skill/tool when actual generation or image editing begins, following its current instructions. Do not generate a whole cast before the first reference asset is approved.

## Specifications to settle through testing

- Render resolution, sprite dimensions, filtering, and palette.
- Facing-direction count and how characters turn between directions.
- Animation frames and movement/combat/treatment states.
- Weapon/hand sprite approach and how it responds to aiming and recoil.
- Buildings/trees: billboard sprites, 3D geometry with painted textures, or a mixture.
- Planning-camera angle/rotation and how structures remain readable there.
- Upgrade-stage visual language, plan previews, and construction progress.

Keep game text, resource counts, and interface labels as editable UI rather than embedding them into generated images. Communal quantities and construction requirements must remain easy to read.


## Current animation training candidates

The local yard includes a separate walking demo using four-frame 2×2 front, profile, and back atlases generated against the approved older civilian. Profile artwork mirrors for the opposite side. The original idle civilian and source artwork remain. Atlas cells are selected in Godot without destructive image processing. Check stride, baseline, identity, and transitions before accepting these as production animation; a physics check that frames change cannot establish visual quality.

A generated transparent first-person wood/steel rifle and hands image now tests framing, bob, recoil, lean, and timed action lowering. It is not a complete reload/aim animation set or approved final weapon choice. Original PNGs and exact prompts are preserved in `assets/TRAINING_ART_PROMPTS.md`. Candidate art was inspected in GPU-rendered course, range, and walking views; motion quality still requires owner playtesting. Camp/planning-view art remains pending.

Muzzle-flash candidate: generated four-frame 2×2 transparent atlas, preserved unchanged and selected in Godot. Separate hip/ADS muzzle anchors attach it to each gun view. A warm-light shader produces lit gun/hand appearances from the existing sprites so the silhouette and iron-sight alignment stay fixed. A brief world light complements the painted effect. Original/prompts are recorded in assets/MUZZLE_FLASH_PROMPT.md; hip, ADS, and post-flash GPU frames were inspected. Exact VFX brightness/size still needs owner playtesting.

Reload presentation now splits the existing magazine into a separate runtime layer using a calibrated UV mask; original PNGs remain unchanged. Rifle and magazine pose timelines are per-weapon resources, and poses can later hold drawn frame/atlas textures. The requested new reload atlas was rejected by the built-in image tool, so static hands and generic action tilts remain known limitations. No new reload artwork or polished hand animation is approved. See WEAPON_ANIMATION_WORKFLOW.md.

Training opponent candidate: one neutral fictional adult front sprite generated by the built-in tool; original alpha/PNG and prompt preserved under assets/characters/training_guard. No uniform authenticity or final cast approval is claimed. Existing civilian art supplies role, rescue and patient stand-ins. Enemy death uses procedural transforms; blood uses native particles and temporary ground marks. Camp stations are replaceable functional blockouts; the separate environment agent's assets are reused rather than regenerated. Proper opponent directions/walk/weapon/death frames and camp work animations remain pending.

Polygon proof: original procedural skinned humanoids, civilian/field color variants, 32 shared bones and eight body-animation clips exported to GLB. Camp residents/patient, player body and one enemy use the rig; original yard sprites and another enemy remain references. No new raster generation or external models were used. Vertex colors are temporary blockout shading, not a painted UV texture set. Character refinement, deformation/IK and first-person weapon/hand meshes remain unfinished.
