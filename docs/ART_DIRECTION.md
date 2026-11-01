# Art direction and production

Status: owner-selected style and production need; detailed specifications and asset examples are pending. No artwork has been generated yet.

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
