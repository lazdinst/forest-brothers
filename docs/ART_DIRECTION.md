# Art direction and production

Status: owner-selected style and production need. The owner approved the first painted front-view starting civilian appearance on 2026-11-01. A four-direction idle experiment with a body collider is now in the movement test: approved front plus new side/back candidates and a mirrored opposite profile. Side/back approval, animation, final direction count, and final sprite resolution remain pending. See [the asset and generation prompts](../assets/characters/starting_civilian/README.md). This is a visual candidate, not a completed sprite animation pipeline.

## Confirmed direction

Gritty illustrated sprites: painted characters with a low-resolution finish, in an immersive first-person game set in postwar Latvia. The owner expects agent-generated sprites because art is their weakest production area.

The camp starts with rough tents and progressively upgraded buildings. The visual system must support first-person play and a city-builder planning view. A sprite-only solution for every building is not selected; simple 3D structures with generated textures remain a candidate.

## Initial feasibility test — proposed

Create one coherent small scene before producing a large library:
- One fictional character reference with approved clothing, equipment, proportions, and colors.
- A limited set of matching directional/animation frames, expanded only after consistency is demonstrated.
- One first-person weapon/hands view to test framing and perspective.
- A tent, planning table, storage prop, and a small material/texture set.
- One rough and one upgraded version of a functional facility.

Check characters against woodland and camp backgrounds, and check facilities from first-person and the planning camera. Test scale and readability in motion as soon as an engine scene exists.

## Repeatable agent workflow

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
