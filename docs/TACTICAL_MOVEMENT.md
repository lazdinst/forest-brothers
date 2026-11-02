# Tactical movement, stance and stamina

Owner request: implemented as a local training increment. Numerical tuning is
provisional. The supplied request ends mid-row at `| Fat`; no unseen remainder
was assumed. Owner feel review remains pending.

## Inspection of the existing implementation

| Existing system | Change / integration |
|---|---|
| `scenes/player/first_person_player.tscn`: CharacterBody3D, duplicated capsule, Camera3D/InteractionRay, Weapon CanvasLayer | Same scene/controller; capsule stays anchored at feet. |
| Instant walk/run velocity, hold-Ctrl binary crouch, jump | Smooth acceleration/braking, persistent pace, seven heights, prone, exertion costs. Ctrl remains a compatibility hold. |
| Swept head-sphere lean, marked vault/mantle with swept segments and landing clearance | Preserved; vault requires stamina and holds its clearance-tested capsule. |
| No prone, inertia, stamina or weight penalties | Per-character `tactical_movement.gd` rules and editable `movement_tuning.gd` resource. |
| C manually chambers rifle; no gameplay wheel binding | Chamber moved to K. Unhandled wheel selects pace or C-held height. |
| Mouse capture; startup inventory/pause disables local world; camp controls consume UI input | Gameplay wheel handler remains unhandled input; stale held C state is cleared when controls resume without C pressed. |
| Weapon ADS sprites align to centered camera ray, procedural recoil/bob, physical projected muzzle with two cover rays | Preserved. ADS drains arms only with an equipped, ready weapon. Arm fatigue adds small camera sway, so the sight and shot ray agree rather than inventing visual spread. |
| Physical ammunition inventory with carried, inserted and dropped item locations | Mass derives from carried items, including loaded rounds/chamber; excludes dropped gear and camp stock. Rifle mass is weapon-definition data. |
| Separate debug bout vitality, no player injury system | Unchanged. Stamina does not implement wounds, campaign casualties or medical recovery. |
| Enemy LOS/recognition, approximate noise investigation, annex-only timed footsteps | Actual grounded distance emits per-player movement noise anywhere on map. Existing enemies subscribe; noise scales with speed/height/load. Recognition and LOS chest point use actual body height. |
| Existing debug HUD, inventory and training course/forest/trench | Additive bottom-left chalk silhouette, seven height marks, pace ticks, leg/arm reserves, weight and exhaustion state. Source image preserved unchanged. |

## Controls and physical rules

- Wheel: change persistent walking pace, initially ten increments from 0.33 to 3.3 m/s.
- Caps Lock: minimum pace / previous nonminimum pace. Shift overrides pace without changing it.
- Hold Shift: forward sprint, initially 5.2 m/s, only at full actual standing height, without ADS and above the stamina lockout. Sprint does not automatically force standing.
- Tap C: lowest crouch / full stand on release. C plus wheel: seven target heights; scrolling suppresses the tap. Repeat key events cannot retrigger it.
- Hold Ctrl: temporary lowest crouch for existing course controls; release restores the selected target when clear.
- X: prone, then restore the prior selected stance. Exit waits for full restored-height clearance. Prone uses a reduced upright 0.6 m capsule as a local crawl approximation; a horizontal full-body collider and prone body animation remain future work.
- K: chamber a round. Existing weapon controls, Q/E lean, Space jump and V traversal remain.

Height levels range from 1.1 to 1.8 m. Growth probes each intermediate capsule
against actual world collision and searches the highest safe height; a blocked
requested height can resume after leaving cover. The eye stays 0.2 m below the
actual top, moving with the capsule. Feet do not move during resizing. Low
stances and prone cannot sprint, jump or vault. Backward and strafe multipliers
are 0.75/0.9; input is normalized before directional restrictions. Speed changes
accelerate/decelerate rather than replacing velocity instantly.

All movement balance lives in the player's `movement_tuning` resource. Stance
arrays have seven ascending height/speed entries; heights must accommodate the
capsule diameter. Leg defaults: 100 points, sprint 12/s, walking recovery 8/s,
stationary 14/s, delay 1.2 s, exhaustion at zero, reactivation at 25. Jump/vault
cost 18/22 before load. Airborne/traversal time delays recovery. Each reserve
exposes a normalized getter for presentation. ADS uses an independent 100-point
arm reserve: provisional 5/s at a 4 kg rifle, recovery 12/s after 0.6 s. Empty
arms increase aim sway; they do not force ADS off or alter ammunition rules.

Provisional mass: rifle 4 kg (definition), empty magazine 0.25 kg, cartridge
0.025 kg. Additional equipment can be specified in tuning until other carried
item systems exist. Penalties start at 12 kg, reach 55% speed / 1.8 times leg
drain at 35 kg, and clamp there; no hard inventory-weight limit was invented.
These are training values, not researched equipment specifications. No running
sound sample, surface acoustics, health/fatigue progression, persistence or
network movement replication is introduced. Selected pace persists for this
character's runtime, not across a restart.

## Validation and owner playtest

`tactical_movement_smoke.gd` tests ten paces, Caps mapping/restore, C event
priority/repeats, independent pools/recovery lockouts, load, partial-height
collision, blocked sprint, prone restoration, acceleration/diagonal/backward
limits, stationary pace, actual sprint/release, grounded noise, quieter slow
steps, ADS height/sway and exhausted jump. Existing course tests verify exact vault spending, exhausted traversal rejection,
geometry paths, lean, tunnel, aimed shots and animation. Longer
movement windows account for acceleration and slower crouch/strafe. The walking
sprite check observes through its authored pause rather than assuming a patrol
phase.

Run from the repository with the documented Godot executable:

```text
<godot> --headless --log-file .godot/tactical_movement.log --fixed-fps 60 --path . --script res://tests/tactical_movement_smoke.gd
<godot> --log-file .godot/movement_visual.log --fixed-fps 60 --path . --script res://tests/tactical_movement_visual.gd
```

The visual script requires Compatibility rendering and writes ignored PNGs to
`.godot/movement_review`. Standing, partial, crouched, prone and fatigued ADS
views were rendered on GTX 1080; HUD placement and chalk source were inspected.

Manual: change pace while stationary; Caps twice; sprint and release; tap C,
then hold C and scroll; enter the low tunnel and request standing; try Shift
under its roof; X in open space and under a low roof; ADS/lean across heights;
shoot over/along cover; compare quiet/loud movement in an armed opponent bout;
drop/recover equipment and compare displayed kg. Open inventory and scroll its
contents; return to gameplay and confirm pace/height were not changed. Assess
camera comfort, inertia and exhaustion pacing. Headless checks and rendered
stills do not establish game feel or cooperative support.

Validation result: fourteen checks passed (`tactical_movement_smoke`,
`training_smoke`, `ads_smoke`, `muzzle_smoke`, `reload_animation_smoke`,
`enemy_encounter_smoke`, `forest_terrain_check`, `camp_annex_smoke`,
`prototype_smoke`, `inventory_ui_smoke`, `ammunition_inventory_smoke`,
`camp_workshops_smoke`, `menu_startup_smoke`, `weapon_state_smoke`). Inventory
coverage includes wheel input while the world is suspended. Import succeeded;
the restricted run reported root-certificate-store and editor-settings-write
warnings unrelated to these local gameplay assertions. Git whitespace check
passed. No two-instance/network test was run.

## Minimal HUD revision — 2026-11-01

Owner requested a presentation-only replacement following the supplied compact
mockup. This supersedes the original labeled movement instrument above. Normal
play shows only the approved outline silhouette, seven ticks on its left, ten
selected-pace ticks below, and two thin gray-green stamina lines. Actual physical
height still drives the existing category mapping; sprint does not change pace
ticks. Prone retains a tiny explicit temporary `PRONE` word because no prone
artwork has been approved. No crouch illustration substitutes for prone.

The Control footprint is 130 × 102 physical pixels at 1920 × 1080, with a
24-pixel edge inset. The standing silhouette is approximately 75 pixels high.
The 720p layout uses an 85% minimum display scale to keep the chalk outline and
thin lines readable; larger resolutions scale from 1080p. Control anchors and
viewport scaling handle placement, and every child ignores mouse input. The
source image is unchanged; shader sampling preserves its outline at small size.
UI properties/redraws update only when displayed state changes; stamina display
smooths toward the existing normalized reserves without spending or recovering
any gameplay stamina.

Persistent headings, controls, movement/weapon status, resource counts and
annex diagnostics are hidden by default. Contextual interaction prompts,
station panels and planning interactions remain available. **F3** toggles a
presentation-only developer overlay in debug builds. Release builds reject
that shortcut unless the overlay's `enable_in_production` property is explicitly
enabled. Detailed load, pace, stamina, weapon/resource and annex/AI diagnostics
remain available there; weight has no normal-gameplay display. Developer
instructions sit above the minimal HUD instead of covering it. Main-menu code,
movement/weapon/AI/inventory rules and all world assets are unchanged.

Validation: `tactical_hud_smoke.gd` checks the three layouts, actual-height art
mapping, selected pace during sprint, stamina smoothing/empty bars, prone,
contextual prompts and the gated debug toggle. Movement, ADS, inventory,
startup/menu and camp-annex regression checks also pass. Compatibility captures
cover standing/max pace, partial/medium pace, crouch/minimum pace, low legs, ADS
with empty arms, normal play, developer overlay and prone at 1280 × 720,
1920 × 1080 and 2560 × 1440. Reproduce with `tactical_movement_visual.gd`;
ignored PNGs and a native-pixel HUD crop sheet are saved under
`.godot/minimal_hud_review`. Screenshot fixtures hold existing state for visual
comparison; they do not change production gameplay rules. All 24 captures were inspected against the compact reference, including a
native-pixel crop sheet and full gameplay/developer views. The initial capture
sheet format issue was corrected; final captures completed successfully. Root
certificate/shader-cache warnings from the restricted environment did not affect
the rendered output. Owner appearance acceptance remains pending.
