# Illuminated firing sprite v1

Owner-authorized firing-sprite chunk, 2026-11-02. Generated with the built-in image_gen tool against the existing aiming atlas. No CLI API, external art, 3D body changes, new outfit or weapon rules.

## Asset and behavior

- `firing_8way_v1.png`: 1536 × 1024 RGBA, eight firing exposures in the same order as holding/aiming: front, front-right-on-screen, right, rear-right-on-screen; back, rear-left-on-screen, left, front-left-on-screen.
- Preserves the fictional guard and SVT-inspired training rifle. It is a visual candidate, not authenticated historical equipment or owner final-art acceptance.
- Small warm muzzle flash at each visible barrel, with painted reflected light on hands, cheek, sleeve and rifle. Straight-back has only subtle shoulder warmth because the muzzle is occluded.
- Source image is preserved unchanged. `scripts/characters/enemy_rifle_pose_art.gd` owns the widened source regions. Cap/sole bounds and body anchors match aiming so adding the flash does not rescale or recenter the figure.
- An actual enemy shot starts/restarts a **75 ms cosmetic exposure** in `enemy_standing_views.gd`. This is provisional presentation timing, not a combat fire interval or approved balance. Normal aiming resumes afterward.
- Reload, downing and death immediately clear exposure; no glowing corpse. Camera movement selects the appropriate firing direction while exposure is active.
- The firing texture contains its own flash and reflected light. Sprite shots no longer create the old duplicate sphere flash. Frozen polygon comparison keeps its existing sphere effect; no source/model/rig changes.
- Ammunition, damage, spread, recognition, ray origin and fire interval are unchanged. Rendering never awards/consumes ammunition.
- The illumination is painted on the firing sprite; it does not dynamically light nearby walls/terrain.
- This is aim → short firing exposure → aim, not a multi-frame skeletal recoil animation. Reload, locomotion, crawl and proper corpse art remain separate chunks.

## Exact built-in prompt

Use case: lighting-weather / identity-preserve.
Edit target: the supplied eight-direction AIMING guard game sprite atlas. Create the matching FIRING exposure frame, preserving the exact eight figures' pixel positions, foot baselines, head heights, face identity, uniform, right-handed rifle grip, gun design and angle order. Four columns, two rows, same canvas 1536x1024. Preserve transparent alpha around figures; brown/black RGB in transparent pixels must remain transparent.
Change only these aspects: add a SMALL restrained pale-yellow/amber muzzle flash at each VISIBLE rifle muzzle and a slight warm reflected light on nearby hands, cheek, rifle receiver/wood and sleeve folds. A brief single gunshot instant, not continuous fire. Minimal recoil compressed into shoulder, no shifted feet, no raised stance, no new expression.
Muzzle flash should be only 8–16 pixels long at this atlas scale, narrow irregular flame with pale center and soft amber outer tip. No huge fireball, no beams, no explosions, no smoke cloud, no shell casings, no sparks. Warm local highlights should read on face and fingers but keep olive garment colors and muted gritty hand-painted shading. Do not brighten the entire figure or backdrop.
View order remains: top front, front-right three-quarter, right profile, rear-right three-quarter; bottom back, rear-left three-quarter, left profile, front-left three-quarter. FRONT flash is a compact star seen end-on. Side flashes project only slightly beyond barrel. On straight BACK, muzzle is hidden by the body: do not paint a flash through his head/back; only subtle warm light near the outer shoulder is permissible. Keep every visible barrel and flash fully inside the canvas, especially the top-right rifle at the right edge. No overlap between neighboring figures. NO text, labels, grid, ground, cast shadows or opaque background. Do not redesign, mirror or rearrange any character.

## Validation

Additional regression checks `enemy_visual_parity_smoke` and `enemy_standing_views_smoke` also passed: sprite/MPFB recognition, movement, firing, health/death and supplies still match, and existing view selection/anchoring remain intact. Six checks passed in total.

Godot 4.7.2 Compatibility import completed. Focused headless checks: `enemy_firing_sprite_smoke`, `enemy_rifle_poses_smoke`, `enemy_readability_smoke`, `enemy_reload_smoke`. All passed. They cover all eight firing angles, alpha, flash pixels, consistent scale/muzzle alignment, actual shot signal and exact round expenditure, exposure lifetime/retrigger, no duplicate sphere and reload/down/death cleanup. The existing readability assertion now checks the painted firing pose instead of requiring the superseded sphere mesh.

Actual presentation was rendered on GTX 1080 Compatibility and inspected: `docs/reviews/enemy_standing_2026-11-02/firing_in_engine.png`. Small flashes and local warm highlights are visible; no opaque backdrop, missing figure or clipped weapon was observed. Straight-back has no flash through the body. The in-game 75 ms effect still needs owner feel review.

The engine reports its existing system certificate-store warning; import also cannot save global editor settings in the sandbox. No script failures or failed assertions were observed.

Reproduce contact sheet:
`<godot> --path . --rendering-method gl_compatibility --script res://tests/enemy_standing_views_preview.gd -- firing`
