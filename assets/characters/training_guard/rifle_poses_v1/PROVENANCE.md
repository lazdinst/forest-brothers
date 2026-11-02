# Rifle holding and aiming sprites v1

Follow-up: the owner subsequently authorized [illuminated firing exposures](../firing_v1/PROVENANCE.md), now used on actual shots. The holding/aiming chunk and its validation below are preserved as their production record.

Owner-authorized follow-up on 2026-11-02: add holding-at-rest and aiming poses. Two eight-direction transparent RGBA atlases generated with the built-in image_gen tool. No 3D body, new outfit, external asset or CLI API was used. Original unarmed atlas is preserved.

## Content and integration

- `holding_8way_v1.png`: relaxed two-handed low-ready hold, eight directions.
- `aiming_8way_v1.png`: shouldered aiming pose, eight directions; no painted shot or flash.
- Both atlases are 1536 × 1024, four columns × two rows. Angle order matches standing v1: front, front-right-on-screen, right profile, rear-right-on-screen; back, rear-left-on-screen, left profile, front-left-on-screen.
- Reference for holding: `../standing_v1/standing_8way_v1.png`. Aiming references the new holding set.
- Rifle is fictional SVT-inspired wood/steel training art, not an authenticated historical reconstruction. Generated angle-to-angle weapon perspective and pose continuity remain candidates for owner review.
- `scripts/characters/enemy_rifle_pose_art.gd` holds source regions, body centers and aiming muzzle markers. Region rectangles deliberately include weapon overhang; equal source-grid cuts would clip barrels. Atlas images are preserved without resampling.
- The existing directional presentation selects aiming while engaged and not reloading/running for cover; otherwise holding. Reload temporarily uses holding, not a finished reload animation.
- Heights and sole baselines are normalized independently per frame. Body centers are anchored separately from the rifle's asymmetric silhouette, avoiding weapon-induced sideways drift.
- The old box rifle mesh is hidden for sprite enemies; its logical transform remains for existing rules and the frozen mesh comparisons. No ammunition/damage/perception/AI tuning changes.
- Sprite muzzle flashes attach to measured painted tips. Straight-back aiming hides the flash because the rifle is occluded by the body. Shot ray origin remains the existing rules-side shoulder; this cosmetic marker does not change hit resolution.
- These are two static poses, not recoil, firing, raising/lowering interpolation, walking or reloading animations. Existing downed/death presentation remains pending its own chunk.

## Holding prompt (built-in image generation)

Use case: identity-preserve. Input image is the exact guard identity, costume, palette, style and eight-angle layout to preserve. Create a transparent RGBA game sprite atlas, four columns by two rows, exactly eight full-body figures. Same lean adult man, olive cap, four-pocket olive tunic, brown leather belt, olive trousers, dark boots, gritty hand-painted style. Same full-body relaxed standing foot positions and head-to-sole height in every cell. Each cell has generous transparent space around the entire figure AND rifle. Do not crop any muzzle, cap, hand or boot. Neutral diffuse illumination. Actual alpha zero backdrop and between limbs. No scenery, shadows, grid, labels or text.
Angle order, left to right: top row FRONT 0, front three-quarter facing screen RIGHT 45, exact RIGHT profile 90, rear three-quarter facing screen RIGHT 135; bottom row straight BACK 180, rear three-quarter facing screen LEFT 225, exact LEFT profile 270, front three-quarter facing screen LEFT 315. Body and head face together. Eight actual views of the same pose, not mirrored artwork.
Rifle design invariant: ONE identical period-style long wood-and-blued-steel military rifle in every cell, dark brown wooden stock, slim long dark barrel, short detachable box magazine below receiver, no scope, no modern accessories, no sling. Fictional SVT-inspired training weapon, not an authenticated reconstruction. Right-handed grip in all eight views, RIGHT hand at pistol grip/trigger guard, LEFT hand supporting wooden fore-end. It remains in the character's hands even when occluded from the rear. Do not switch shoulders or reverse gun direction between angles.
Requested pose: HOLDING AT REST / LOW READY. Both hands hold the rifle across the lower chest and waist, butt below the RIGHT shoulder, muzzle forward and tilted down about 30 degrees. NOT aiming, cheek away from stock, eyes looking ahead, elbows relaxed. From the front the gun points foreshortened forward and downward; from the profiles its muzzle points the same horizontal direction as his nose and downwards. Body upright, same standing stance as reference. Preserve character appearance; change only arms and add held rifle.

## Aiming prompt (built-in image generation)

Use case: identity-preserve. Input image is the exact guard identity, costume, palette, style and eight-angle layout to preserve. Create a transparent RGBA game sprite atlas, four columns by two rows, exactly eight full-body figures. Same lean adult man, olive cap, four-pocket olive tunic, brown leather belt, olive trousers, dark boots, gritty hand-painted style. Same full-body relaxed standing foot positions and head-to-sole height in every cell. Each cell has generous transparent space around the entire figure AND rifle. Do not crop any muzzle, cap, hand or boot. Neutral diffuse illumination. Actual alpha zero backdrop and between limbs. No scenery, shadows, grid, labels or text.
Angle order, left to right: top row FRONT 0, front three-quarter facing screen RIGHT 45, exact RIGHT profile 90, rear three-quarter facing screen RIGHT 135; bottom row straight BACK 180, rear three-quarter facing screen LEFT 225, exact LEFT profile 270, front three-quarter facing screen LEFT 315. Body and head face together. Eight actual views of the same pose, not mirrored artwork.
Rifle design invariant: ONE identical period-style long wood-and-blued-steel military rifle in every cell, dark brown wooden stock, slim long dark barrel, short detachable box magazine below receiver, no scope, no modern accessories, no sling. Fictional SVT-inspired training weapon, not an authenticated reconstruction. Right-handed grip in all eight views, RIGHT hand at pistol grip/trigger guard, LEFT hand supporting wooden fore-end. It remains in the character's hands even when occluded from the rear. Do not switch shoulders or reverse gun direction between angles.
Requested pose: AIMING DOWN RIFLE SIGHTS, ready to fire but NO shot, NO flash. Buttstock firmly against the character's RIGHT shoulder, right cheek touching the stock, eye aligned to iron sights, LEFT hand supports fore-end, RIGHT hand on grip. Rifle barrel horizontal and parallel to where the torso and head point, muzzle forward. Both elbows bent, support elbow under rifle. From straight front, muzzle points toward viewer and is strongly foreshortened; from straight back, rifle points away and is mostly occluded by shoulder; from side profiles the long barrel is clearly visible horizontally in direction of nose. SAME rifle as reference, never switch shoulders. Preserve standing feet, outfit, body identity, cap and proportions. Make generous room in cells for entire horizontal barrels; keep every figure fully separate, no overlap. Change only arm pose and rifle elevation from the holding reference.

## Validation

Godot 4.7.2 Compatibility imported both atlases. Four focused headless checks passed: `enemy_rifle_poses_smoke`, `enemy_standing_views_smoke`, `enemy_readability_smoke`, `enemy_reload_smoke`. These cover all 16 pose/direction selections, real alpha, region extents, body/foot anchoring, muzzle markers, reload/cover pose priority, no duplicate proxy and ammunition conservation through existing reload rules.

Both pose sheets were rendered through the actual enemy presentation on GTX 1080 Compatibility and inspected. Review captures are `docs/reviews/enemy_standing_2026-11-02/holding_in_engine.png` and `aiming_in_engine.png`. No cropped barrels or opaque backdrops were observed. Side/rear facing retains the previous dimming.

The engine reports a system certificate-store warning; import also reports inability to save global editor settings under the sandbox. No script errors or failed assertions were reported. Owner art and combat feel review remain pending; no multiplayer acceptance is claimed.

Reproduce either contact sheet with:
`<godot> --path . --rendering-method gl_compatibility --script res://tests/enemy_standing_views_preview.gd -- holding`
or replace `holding` with `aiming`. No argument reproduces the original unarmed sheet.
