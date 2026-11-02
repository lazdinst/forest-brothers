# Standing guard directions v1

Owner-authorized standing-only sprite increment, 2026-11-02. Candidate appearance awaits owner review.

## Files and source

- `standing_8way_v1.png`: 1536 × 1024 RGBA source atlas; four columns, two rows.
- Reference: `../idle_front_v1.png`, preserved unchanged.
- Generated with the built-in image_gen tool, followed by a built-in background-extraction edit. No external model, third-party art, CLI image API or MPFB changes.
- Fictional character; clothing is a visual continuity reference, not an authenticated uniform reconstruction.
- Top row: front, front-right-on-screen three-quarter, right-facing profile, rear-right-on-screen three-quarter.
- Bottom row: back, rear-left-on-screen three-quarter, left-facing profile, front-left-on-screen three-quarter.
- Separate paintings for both sides; no runtime mirroring.
- The atlas has unequal silhouette margins. `scripts/characters/enemy_standing_views.gd` selects measured AtlasTexture regions with four pixels of padding, normalizes cap-to-sole height to the existing 1.75 m figure, and anchors feet. The original atlas is not resampled.
- View selection uses camera position relative to actual actor facing, with 3° boundary hysteresis. Camera pitch does not tilt or scale the standing sprite.
- Existing facing-dependent tint, rifle proxy, combat rules and collapse/crawl behavior remain. This does not provide weapon poses, walking frames or improved corpses.

## Generation prompt

Use case: identity-preserve.
Asset type: transparent game sprite atlas, eight standing directional views, FOUR COLUMNS by TWO ROWS, exactly eight separate full-body figures, each in its own equally sized cell.
Input image: the existing game's guard is the identity, outfit, palette and painted style reference. Preserve this exact fictional adult man's face, lean body proportions, olive cloth field cap, olive four-pocket wool tunic, brown leather belt, olive trousers and worn dark boots. Do not redesign him.
Primary request: turn this SAME man around his vertical axis to produce an orthographic eight-direction standing sprite sheet. He stands still, feet planted in the same relaxed stance, arms naturally down, EMPTY HANDS. Head and torso point in the same direction. No action, no weapon.
Layout, left to right:
TOP ROW: 1 front facing viewer (0 degrees), 2 front three-quarter with nose toward image RIGHT (45), 3 exact right-facing profile (90), 4 rear three-quarter still facing image RIGHT (135).
BOTTOM ROW: 5 straight back, no face visible (180), 6 rear three-quarter facing image LEFT (225), 7 exact left-facing profile (270), 8 front three-quarter with nose toward image LEFT (315).
Each figure has equal head-to-sole pixel height, identical vertical alignment and generous transparent padding. Center each silhouette in its cell; cap and both soles fully visible. Camera fixed at body-middle height, orthographic, no perspective convergence, NO overhead/isometric views. Consistent diffuse neutral illumination, no directional cast shadows.
Style: match the reference's gritty detailed hand-painted illustration, muted brown olive palette, restrained shading. Actual transparent alpha around and between figures. No ground plane, no backdrop, no drop shadow, no grid, no borders, no text or angle labels. Anatomically consistent figures; do not mirror front images as a substitute for actual rear views. Deliver a single wide 4 by 2 atlas.

## Background-extraction prompt

Use case: background-extraction. Edit target: the supplied eight-direction standing guard sprite atlas. Remove ONLY the entire brown/black backdrop and all ground/cast shadows, replacing them with genuinely transparent alpha (alpha zero). Preserve all eight guards, their exact poses, faces, painted colors, clothes, size, positions and four-column two-row arrangement unchanged. Clean cutout edges around caps, fingers and boots. Transparent empty space between limbs and between every figure. NO solid color, NO brown glow, NO checkerboard pattern drawn into image. Output RGBA PNG with actual transparency. Do not redesign or rearrange.

## Validation

Godot 4.7.2 Compatibility import completed. `enemy_standing_views_smoke`, `enemy_readability_smoke` and `enemy_body_smoke` passed. The first covers all eight camera sectors, actor rotation, independent side textures, real alpha, consistent figure height/sole baseline and hysteresis. Existing checks cover rifle/muzzle presentation and downed/crawl/death rules.

GPU review: `tests/enemy_standing_views_preview.gd` rendered the actual enemy presentation on GTX 1080 Compatibility to `docs/reviews/enemy_standing_2026-11-02/standing_in_engine.png`. All eight views were inspected; backgrounds cut out cleanly, figures are fully visible and the foot baselines align. The preview hides the rifle proxy solely to show the standing artwork.

The engine reported sandbox log/editor-settings access errors during import/headless runs and a system certificate-store warning; no script errors or failed assertions were reported. GPU capture succeeded. No multiplayer or final art acceptance is claimed.
