# Rifle-holding walk cycle v1

Owner-authorized walking-animation chunk, 2026-11-02. Eight independently generated 2×2 sheets, four painted frames per direction (32 total), made with the built-in image_gen tool. Exact selected prompts are in [PROMPTS.md](PROMPTS.md). All use the existing holding atlas as reference; no new outfit, 3D body, external dependency or CLI image API.

## Assets and selection

- `walk_0_v1.png` through `walk_315_v1.png`, in 45° increments. Each sheet is one direction; row-major frame order is contact, passing, opposite contact, opposite passing.
- Directions follow the existing atlas: 0 front, 45 front-right-on-screen, 90 right profile, 135 rear-right-on-screen, 180 back, 225 rear-left-on-screen, 270 left profile, 315 front-left-on-screen.
- These are actual separate paintings; no runtime mirrored rifle.
- Source sizes vary by sheet and are retained unchanged. `frame_layout.json` records measured opaque bounds and head centers. `scripts/characters/enemy_walk_art.gd` contains the corresponding immutable AtlasTexture regions and pivots, with four pixels of padding.
- Height is normalized to the existing 1.75 m figure, planted sole to ground, and head/cap center to actor origin. This prevents changing source margins, stride width and rifle overhang from shifting the body.
- Separate whole-atlas phase experiments did not reliably alternate the legs and were discarded. One benign walking-frame request was rejected by the image tool; a simplified retry succeeded. The selected production route is one complete four-frame sheet per direction; draft outputs are not referenced or installed.

## Runtime

- `enemy_standing_views.gd` advances walking by **actual horizontal displacement**, after collision movement. A complete four-frame loop spans a provisional 1.4 m. Faster travel advances faster; zero displacement resets to holding. Gravity/falling alone does not animate walking.
- Searching, returning, the existing patrol shuffle, and moving to cover use the low-ready cycle. Aiming/firing and reload have priority. Reload currently shows the pre-existing holding placeholder. Incapacitation/death clear walking before the existing body visual runs.
- Existing AI heading/perception, speeds, paths, hitboxes, shots and ammunition rules are preserved. The original patrol intentionally keeps lane-facing orientation while shuffling sideways; this increment does not provide dedicated strafe/backward/run animations or turn the actor's perception cone to match travel.
- The same cycle currently accelerates during movement to cover; it is not a newly authored running gait.
- This is a first four-frame painted candidate. Diagonal leg overlap, foot contact, upper-body bob and transitions between independently generated angles still need owner motion/appearance review.

## Validation

Six focused headless checks passed on Godot 4.7.2: `enemy_walk_sprite_smoke`, `enemy_firing_sprite_smoke`, `enemy_rifle_poses_smoke`, `enemy_visual_parity_smoke`, `enemy_readability_smoke`, `enemy_reload_smoke`.

The walking check covers 32 view/frame selections, alpha, region bounds, ground/height anchors, distance phase and wrap, aim/reload priority, real patrol displacement, stopping against an actual wall, inactive/downed cleanup and conserved ammunition. The first run caught an alpha sample of 1/255 at one source corner; the assertion now allows visually transparent alpha below 0.01 while also requiring a fully clear nearby background sample. No image pixels were changed to satisfy the check.

All four contact-sheet phases were rendered via actual enemy presentation on GTX 1080 Compatibility and inspected. `docs/reviews/enemy_standing_2026-11-02/walk_frame_0.png` through `walk_frame_3.png` are the captures; `walking_in_engine.gif` is their one-second looping review animation, assembled with native GIF encoding and Python standard-library container assembly. GIF decoding confirms four frames at 1400 × 787. No external package was installed. It is an isolated art preview; gameplay cadence varies with actual travel distance.

Reproduce the four native phase captures:
`<godot> --path . --rendering-method gl_compatibility --script res://tests/enemy_standing_views_preview.gd -- walking`

The engine reports its existing certificate-store warning and cannot save global editor settings during sandboxed import. No script failures remain. Owner animation acceptance, co-op authority and remaining reload/crawl/corpse sprites are not established by these checks.
