# Combat arena plan

Status: **owner-directed, partly implemented, 2026-11-01.** Section 2 records decisions the owner made in conversation. Section 3a lists what is now built on branch `combat/body-zones`. Everything else is still a proposal or an open question. This document answers the review request in [CHARACTER_FREEZE_AND_COMBAT_SLICE.md](CHARACTER_FREEZE_AND_COMBAT_SLICE.md); the owner then directed the work in chunks.

## 1. Goal

Build a combat training area that feels like fighting scavs, bosses and boss guards in Tarkov: you hear enemies before you see them, both sides are fragile, enemies behave like people rather than targets, and a kill leaves something behind. It is a drill, not a campaign mission, so nothing here changes mission-death, gear-loss or rollback rules. Solo play comes first, but nothing may assume exactly one player ([AGENTS.md](../AGENTS.md)).

## 2. Decisions confirmed by the owner (conversation, 2026-11-01)

- Bodies have separate hit zones for **head, torso, arms and legs**.
- **Head at zero health: death.** Immediate, with no bleed-out window and no revival. Applies to players and enemies.
- **Torso at zero health: incapacitated.**
- A **downed player** lies on the ground and can do nothing. Any further hit kills them.
- A **downed enemy crawls.** A further hit finishes them.
- **Finishing a downed enemy is done by shooting it again.** No knife or pistol finisher for now.
- Direction for enemy visuals: better **sprite-based** enemies. The production route is still open (section 11).

How these fit existing confirmed rules ([DECISIONS.md](DECISIONS.md)): incapacitation with a teammate revival window, solo or all-players incapacitation resolving as mission death, individual mission death, and friendly fire are unchanged. The head-zero rule settles one of the "fatal injury exceptions" that `DECISIONS.md` lists as unresolved.

## 3. What existed before this work

Audit of `main` at commit `983132d`, kept for reference.

- Enemies are passive until the bout is armed at the Enemy test controls in the camp annex ([CAMP_AND_COMBAT_TESTS.md](CAMP_AND_COMBAT_TESTS.md)).
- Armed enemies did not move when they saw you, fired every 1.1 s after a 0.65 s reaction delay with no deliberate inaccuracy, and never took cover, reloaded, flanked, advanced or retreated.
- Perception already existed: line of sight, recognition that builds with exposure, `hear_noise`, `receive_alert` and search decay.
- Damage had no body part; enemy health was a single number (100).
- The player had no health, only a debug "vitality" counter in `training_annex.gd`.
- Enemy art is one front-facing sprite that always turns to face the camera. The MPFB 3D comparison model has documented, frozen defects.
- Collision layers (bit values): world and enemy body 1, player 2, civilian clearance 4.
- Prone is a short upright capsule for the player.

## 3a. Implemented on `combat/body-zones` (2026-11-01)

Each chunk has a headless check under `tests/`. Headless checks do not establish feel; owner playtesting of chunks 6–8 is outstanding. All numbers below are **placeholders**, not approved balance.

| Chunk | What it does | Check |
|---|---|---|
| 1 | `scripts/combat/body_health.gd`: rules-only zone health. Head zero kills, torso zero downs, any hit on a downed body kills, limbs disable once, bleed-out kills. Overflow into a disabled limb is ignored for now. | `body_health_smoke` |
| 2 | `hit_zone.gd` / `hit_zones.gd`: invisible zone volumes on layer 8 that follow the actor's true facing, with standing and downed layouts. Rifle shots that strike a capsule resolve the zone along the shot; a gap is a miss. | `hit_zones_smoke` |
| 3 | Enemies use zone health. Downed enemies lie flat (collision too), call out through the local alert, crawl away from the shooter, never fire, and die to any hit or a 30 s bleed-out. | `enemy_body_smoke` |
| 4 | Player uses zone health with zones that scale with stance. Solo torso zero is death; with the dev **Simulate nearby teammate** toggle it downs instead (helpless, camera on the ground, 60 s bleed-out). Enemy rays damage what they hit (friendly fire). The vitality counter is replaced by a drill debrief. | `player_body_smoke` |
| 5 | Directional red hit arc and synthesized per-zone hit sounds; enemy impacts are positional. | `hit_feedback_smoke` |
| 6 | Enemy aim cone: 3° on first exposure, tightening to 35% over 4 s, +1.5° against a moving target. Positional enemy gunfire and near-miss cracks within 2 m. | `enemy_aim_smoke` |
| 7 | Placeholder rifle proxy on the true facing: lowered while calm, raised while engaging. Shots leave from a facing-relative shoulder; flash at the muzzle. Sprite dims when the body faces away. | `enemy_readability_smoke` |
| 8 | Finite magazines (10 rounds, 3 spares, 3 s reload). Reload lowers the rifle and plays a positional clatter. Partial magazines are retained; empty enemies stop firing; rounds are conserved. | `enemy_reload_smoke` |
| 9 | Blockout arena `scenes/combat/combat_arena.tscn` (grey boxes: screening wall, farmhouse shell with doorway, crate cover) with a navigation map baked at load. Two enemies, active by default. Searching enemies follow navigation paths and face their route; scenes without a navigation map (the camp annex) keep straight-line movement. Launch directly: `<godot> --path . res://scenes/combat/combat_arena.tscn`. No menu or route entry yet (open question 9). | `combat_arena_smoke` |
| 10 | Searching: noise, local alerts and losing sight start a walk to the last known position (1.4 m/s, along navigation where available). On arrival, or when blocked or after 30 s, the enemy sweeps its view for 6 s, then gives up, walks back to its post at 1.0 m/s and resumes its watch direction. Hidden players are not tracked. | `enemy_search_smoke` |
| 11 | Cover: when hit, or when reloading while engaged, an enemy runs (2.6 m/s, no firing) to the nearest reachable spot within 12 m of path where walls hide its chest and head from the threat with a 0.5 m margin. It holds 2.5 s facing the threat (until the reload finishes), then leaves toward where it last saw the threat. Cover that proves exposed is abandoned once the rifle is ready. Crates do not count yet because enemies do not crouch. Scenes without navigation (camp annex) keep the old behaviour. | `enemy_cover_smoke` |
| 12 | Arena HUD (stance/stamina instrument, crosshair, prompts) and a finite 120-round ammo crate handing out 10 loose cartridges per use. | `combat_arena_smoke` |
| 13 | Loot: in the arena, a dead (not downed) enemy drops each magazine it still carried, with exact round counts, as existing ground-equipment pickups (F to recover). Rounds are conserved; the rifle stays with the body; arena reset clears leftover loot. Off in the camp annex. | `enemy_loot_smoke` |
| 14 | Flanking: an enemy alerted by an engaging ally heads (2 m/s) for a reachable spot 7–13 m from the target, roughly square to the ally's line of fire, with a clear view of the target; on arrival it faces the target and scans. Plain noise alerts and scenes without navigation walk straight in as before. | `enemy_flank_smoke` |

Placeholder values: zone maximums head 35, torso 80, arms 60, legs 65; rifle and enemy damage 40; enemy bleed-out 30 s; player bleed-out 60 s. Arms and legs are each one zone (left/right still open).

Not yet built: revival, limb effects, lean-following player zones, crouching and peeking, archetypes, rifle and non-ammunition loot, real sprites.

## 4. What makes the fight feel like Tarkov (proposed)

In rough order of feel gained per effort. Art comes after behavior, sound and consequences.

1. **Hear before you see.** Footsteps, directional gunshots, bullet cracks and whizzes, voice barks and reload sounds. Any third-party sound must pass the license check in `AGENTS.md`; current sounds are synthesized in code.
2. **You are fragile too.** Player body damage, directional hit indicators, flinch and audio feedback.
3. **Enemies act like people.** Patrol, investigate, take cover, peek and fire, reload, call for help, advance or flank when they know where you are, retreat when hurt. This needs a navigation map.
4. **Readable enemies.** Visible facing, muzzle flash at the barrel, distinct silhouettes per type, clear tells.
5. **Bodies matter.** Kills drop gear that can be recovered. The inventory already supports ground items with stable identity, and equipment is communal.

## 5. Opponents (proposed placeholders, research required)

Tarkov-style roles fitted to 1946. They are fictional placeholders. Describe opposing institutions precisely (Soviet occupation and security forces and relevant collaborators, never an ethnicity) and cite research before naming any real organization or event ([AGENTS.md](../AGENTS.md)).

| Tarkov role | Placeholder | Behavior |
|---|---|---|
| Scav | Marauders or stragglers | Jumpy, loud, inaccurate, small groups, flee when hurt |
| Guard | Security-force patrol | Disciplined, uses cover, flanks, calls out |
| Boss and guards | A fictional officer with an escort | Boss holds a defended position and is tougher; guards patrol outside and respond to noise |

"Tougher" means higher zone health and better aim limits, not armor. Armor and penetration are not approved.

## 6. The arena (proposed)

- A **new scene** (suggested `scenes/combat/combat_arena.tscn`), not an extension of the current lane. This keeps the environment agent's forest and the main menu untouched. It may instance existing environment assets read-only.
- A small farmstead or roadside checkpoint with several approaches, interiors, cover and flank routes, split into three zones: a scav camp (easy), a patrol route (medium) and a boss compound (hard).
- The navigation map belongs to this scene only.
- A control table for spawning and resetting enemies, an AI debug view that shows what each enemy perceives, an invulnerability toggle, and a blood toggle.
- A co-op simulation toggle so the downed state can be tested in single-player (a first version exists in the camp annex, chunk 4).

## 7. Body damage model

| Zone | At zero health | Status |
|---|---|---|
| Head | Death | Confirmed, implemented |
| Torso | Incapacitated | Confirmed, implemented |
| Arms | Disabled: worse aim and sway; whether it blocks holding the sights is open | Proposed; disable is tracked, no effect yet |
| Legs | Disabled: limping, no sprint | Proposed; disable is tracked, no effect yet |

Separate left and right limbs, a stomach zone, and overflow into a disabled limb remain unresolved. Zone values should later load from a data resource so tuning needs no code change. If characters later become rigged 3D, the same zones can attach to bones with no rule changes. Pixel-exact sprite masks remain a reserve option.

Not included: armor, penetration, bullet drop, bleeding and fracture effects. Hits will later feed the bleeding rules in [MISSIONS_AND_MEDICINE.md](MISSIONS_AND_MEDICINE.md).

## 8. Downed and death rules

| | Player | Enemy |
|---|---|---|
| Head at zero | Death, no revival. Carried gear stays on the body (confirmed rule). In the drill the attempt ends with a debrief | Death |
| Torso at zero | Incapacitated: lies on the ground, no actions, camera drops and controls lock. Bleed-out timer; teammates can revive in co-op | Downed: crawls |
| Hit while downed, any zone | Death | Death (finished) |
| Bleed-out expires | Mission death | Death |

Proposed details still open: enemies finish a downed player only when no active threat remains; crawl toward real cover; whether a downed enemy may fire (default no); revival requirements; enemy loot through the ground-item system.

## 9. Phases (proposed)

| Phase | You would experience | Done when |
|---|---|---|
| 0. Decide | Plan reviewed; open questions answered | `DECISIONS.md` records the choices |
| 1. A real fight | You can be hurt, downed and killed; zone damage both sides; directional hit feedback and gunfire; imperfect enemy aim; enemies face visibly | Largely built (chunks 1–8); owner playtest pending |
| 2. Smart enemies | Cover, peeking, reloading, flanking, searching around walls, local alerts, retreating, crawling when downed | Enemies reach a last-known position around cover; lose a hidden player; reload creates a usable opening |
| 3. Archetypes | Scav groups, patrols, a boss compound with guards | Each type recognizable by behavior alone |
| 4. Loot and objective | Bodies drop recoverable gear; supply-recovery goal; debrief | Loot counts once; goal winnable by avoidance; reset leaves no duplicates |
| 5. Real sprites | Directional animated enemy art | Enemies read clearly at distance; owner approval |

Follow with the existing two-instance combat authority checkpoint before expanding enemy types, medicine or maps ([ROADMAP.md](ROADMAP.md)). Do not mark roadmap milestones complete from these phases.

## 10. Relationship to the earlier proposed slice

The A–C slice in `CHARACTER_FREEZE_AND_COMBAT_SLICE.md` is subsumed. Phase 1 corresponds to A, using zones instead of scalar player health. Phase 2 corresponds to B. Phase 4 corresponds to C.

## 11. Sprites (proposed)

**Walking follow-up:** owner-authorized low-ready locomotion has 32 painted frames across eight directions. Collision-resolved horizontal distance drives phase; blocked/inactive actors stop, and aim/fire/reload take priority. Six headless checks passed, including real patrol/wall blocking and visual-rule parity. All four native GTX 1080 phase sheets were inspected and a looping review GIF is available. [Walking provenance and limits](../assets/characters/training_guard/walking_v1/PROVENANCE.md). Owner motion review remains pending; this does not authorize separate running/strafe, reload or grounded-body art chunks.

**Firing follow-up:** owner-authorized eight-direction illuminated firing exposure is integrated. Actual shots trigger a short painted muzzle flash and local warm highlights, then return to aiming. Straight-back muzzle remains occluded; sprite shots no longer add a duplicate sphere. Reload/down/death clear exposure. Four focused headless checks pass and a GTX 1080 Compatibility sheet was inspected; owner feel/appearance review remains pending. [Firing provenance](../assets/characters/training_guard/firing_v1/PROVENANCE.md). No firing balance or dynamic world-lighting changes.

**Rifle-pose follow-up:** the owner then authorized holding and aiming artwork. Two eight-direction static sets are now connected to enemy state, with painted muzzle-flash markers and no duplicate box rifle on sprite actors. Four headless checks pass; both actual in-engine pose contact sheets were inspected on GTX 1080 Compatibility. [Prompts, limitations and validation](../assets/characters/training_guard/rifle_poses_v1/PROVENANCE.md). Reload currently lowers to holding; it has no new reload frames. Recoil, transition/walk/crawl/death frames remain follow-up work requiring owner direction. Visual acceptance is pending.

**Owner update, 2026-11-02:** use sprites; no further 3D body work. The owner authorized standing views first. Eight separately painted standing directions are now integrated for sprite enemies, using their true facing and a small switching margin. Atlas, prompts and validation: [standing v1](../assets/characters/training_guard/standing_v1/PROVENANCE.md). Three focused headless checks passed and a GTX 1080 Compatibility contact sheet was inspected. These are candidates awaiting owner appearance review. Weapon poses, movement, collapse/crawl and corpse sprites remain future chunks. The historical production-route options below do not authorize resuming MPFB work.

Build phases 1 to 3 with the current placeholder sprite; the parity test proves combat results do not depend on the visual. Needs per archetype: five directional views mirrored to eight; idle, walk, aim, fire, reload, hit flinch, fall to downed, crawl and death; roughly 70 frames per character. Mirroring puts a rifle on the wrong shoulder.

Production routes (decision open): **A** generate painted sprites per angle (identity and mirroring drift risks), or **B** pre-render from the frozen MPFB rig at eight angles (consistent, but lifts the art freeze for this purpose only). Test one crawl sprite both flat and upright before committing to a full crawl set.

## 12. Open questions

1. Sprite route A or B, and whether to lift the art freeze for B.
2. Zone health values, damage multipliers, and rifle lethality per zone.
3. Separate left and right limbs, and whether to add a stomach zone.
4. Effects of a disabled arm or leg, and overflow damage to a disabled limb.
5. Bleed-out duration and revival requirements.
6. Whether a downed enemy may fire while crawling (default no).
7. Opponent identities, names and historical grounding, with sources.
8. Audio sources and licensing beyond the synthesized placeholders.
9. How the player enters the arena.
10. Enemy aim spread, magazine size, spares and reload time.

## 13. Out of scope

Knife, melee or pistol finishers (decided: not for now), armor and penetration, new weapons, squad tactics beyond local alerts, full wounds and medicine depth, multiplayer authority, campaign persistence, character art polishing unless the freeze is lifted, and edits to the environment or main-menu work.
