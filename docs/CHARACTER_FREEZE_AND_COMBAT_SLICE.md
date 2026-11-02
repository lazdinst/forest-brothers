# Character freeze, gameplay audit and proposed combat slice

Status: character art frozen by the owner. Visual validation and the small representation-independence correction are complete. The combat vertical slice below is **proposed for review, not approved or implemented**. No nature/environment or main-menu agent files were edited for this work.

## What is preserved and playable

The owner-selected MPFB base, packed rigged and dressed Blender sources, selected upstream clothing/bodypart resources, initial animation recipe and exported GLB are preserved. `art_source/mpfb_enemy/` contains the frozen source package and a SHA-256 manifest. Its `.gdignore` prevents duplicate source imports into Godot. Original user files and the current GLB were not modified during this freeze. The GLB retains a shared 53-bone skeleton, four clips and six separate meshes. This is one fitted outfit, not a complete runtime wardrobe system.

Both training opponents default to the painted sprite. At **Enemy test controls**, choose **Compare first enemy: Sprite (resets bout)** to use MPFB on the first opponent; press the corresponding MPFB button to return to sprites. Switching intentionally resets the bout/enemies and does not spend supplies or change carried ammunition. The second opponent remains a sprite. No new clothes, textures, models or polished animation clips were created during validation.

## Visual validation findings

Rendered in the actual training scene with Godot 4.7.2 Compatibility on the GTX 1080, 1280x720. Inspected multiple frames during walking, recognition-to-aim, damage/recovery and death. Walking uses actual AI patrol motion; aiming follows actual recognition and engage state; damage/death use the same hit receiver as rifle impacts. Rifle impacts are separately verified in the scene tests. Captures are deterministic review recordings, not performance benchmarks or owner playtest acceptance.

| State | Result and frozen issues |
| --- | --- |
| Idle | Body/skin/hair/eyes render and remain fixed in the world. Noticeable sweater/waistband interpenetration and visible patches near the hem. Hands are stiff; appearance/outfit is provisional. |
| Walking | Legs and clothes deform; no gross exploding mesh or detached garment observed. Feet slide/hover, hand pose remains open and stiff, and limb movement is not matched to lateral patrol motion or exact travel speed. The common AI keeps its existing lane-facing heading. Waist overlap persists. |
| Aiming | The clip loads during engage, but the arms spread outward with open palms instead of holding a rifle. Shoulder/upper-arm seams expose light patches. No held weapon or hand-contact alignment exists. This pose is unsuitable as a finished firing animation. |
| Damage | Forty damage visibly changes health from 100 to 60, with a brief red whole-body tint and small particles; tint clears afterward. No flinch, directional reaction or wound animation. The red sweater makes the hit tint less distinct than a neutral outfit would. |
| Death | Lethal damage stops AI immediately and disables the shared capsule. The clip ends in a prone body and holds. It is a rigid forward pivot with little impact/settling, not a convincing collapse or ragdoll; hand/foot contact and terrain conformance are absent. The blood mark remains near the original standing position instead of following the final body. |

The original sprite is more coherent with the current painted weapon and intended field clothing, so it remains the default. It still billboards, has empty hands and uses a simple collapse; neither presentation is final art. The MPFB comparison is retained as technical evidence. These defects are logged, not repaired during the art freeze.

Evidence: [idle](reviews/character_freeze_2026-11-01/idle.png), [walk](reviews/character_freeze_2026-11-01/walk.png), [actual aim](reviews/character_freeze_2026-11-01/aim.png), [damage](reviews/character_freeze_2026-11-01/damage.png), [recovered tint](reviews/character_freeze_2026-11-01/damage-recovered.png), [death](reviews/character_freeze_2026-11-01/death.png), [sprite comparison](reviews/character_freeze_2026-11-01/sprite.png). The capture helper is saved with them. Earlier aim captures that remained in patrol were discarded; the accepted capture waits for the physics server to synchronize the review player's position before enabling AI.

## Gameplay and presentation independence

`enemy_actor.gd` owns health, collision, recognition, sight/hearing/search, actor facing, shot timing, damage acceptance and defeat signals. The MPFB adapter owns imported mesh/materials and animation playback. Neither skeleton, clothing mesh nor animation event awards damage or determines death. The same capsule and hit receiver are used for sprites and MPFB; damage is not location-specific.

One integration error was removed: the MPFB path had changed actor yaw during patrol while the sprite path did not. Both now keep the existing sprite AI heading. No new patrol/scanning design was introduced. Death resolves and emits its gameplay result before choosing the cosmetic corpse animation. Presentation helper code still lives partly in the actor; this is a narrow separation fix, not a new combat architecture.

`enemy_visual_parity_smoke.gd` runs the same scenario twice. Its 14-state traces match for detection, cover, movement/facing, search, shots/hits, health, damage, one-time defeat and collision disablement. It also exercises both comparison switches and checks ammo/stock conservation. `mpfb_enemy_smoke.gd` explicitly opts into the comparison; ordinary training and legacy-rig checks assert sprite defaults.

The first-person weapon controller still combines input/presentation with hit-ray orchestration, while its ammunition/action rules live in separate state/inventory objects. Extracting a broader world-combat service or common health architecture is a possible next-scope change, not something completed here. Networking authority remains unproven.

## Current combat and movement

| Area | Implemented local behavior | Biggest missing piece |
| --- | --- | --- |
| Movement | Adjustable pace, seven stance heights, prone, inertia, independent leg/arm stamina, carried-weight effects, movement noise, jump, collision-limited lean and swept vault/mantle. ADS slows movement; fatigue adds sight-aligned sway. Firing is blocked during sprint/vault; chambering is now K. See TACTICAL_MOVEMENT.md. | Owner feel review and combat tuning remain. Prone uses a short upright capsule; no full horizontal body collider or prone body animation. Injury penalties and broad climbing remain absent. Preserve and validate the new movement rather than rebuilding it. |
| Rifle | Actual chambered cartridges, distinct magazines/loose rounds, manual packing, retained partial magazines, timed reload/clear/service and maintenance-dependent jams. Hip/ADS alignment, muzzle flash and a barrel-origin ray blocked by nearby cover. | One rifle prototype. No projectile drop/penetration or finished recoil/handling balance. Incoming enemy fire is much less developed than player fire. |
| Enemy perception | LOS and recognition affected by distance, actual body height and movement speed; grounded per-player movement noise scales with pace/height/load. Finite approximate investigation, last-known search, local alert and delayed firing. | No surface-dependent footsteps or hearing occlusion, deliberate scanning, richer evidence memory or readable alert cues. Height/motion recognition and per-player movement noise are now present in the concurrent tactical movement work. |
| Enemy movement | Short lateral patrol and straight-line search movement. | No routing around cover, stuck recovery or deliberate combat positioning. |
| Enemy firing | Fixed cooldown, brief reaction delay and obstruction-checked rays at the player's chest. | Exact center targeting, unlimited enemy firing and no shared ammo/reload behavior. Shot origin is a fixed world offset; flash follows local orientation, so those can disagree when turned. Empty-hand firing gives little warning. |
| Damage/consequence | Enemy scalar health, rifle damage, blood, one-time defeat and disabled corpse collision. Armed drills subtract 20 from a separate training vitality counter; zero stops the bout and returns the player to camp. | No actual player wound/health/death receiver, incapacitation/revival, hit-location effects or mission death/gear recovery. Debug vitality is not those systems. |
| Loop/co-op | Camp supplies, training bouts and manual rescue/result fixtures exist; ammo conservation is checked. | No playable objective-to-return combat outing, campaign save/rollback or two-instance authority proof. |

## Proposed vertical slice: recover supplies under fire

Target a replayable **5–8 minute solo training drill**, using the current rifle, existing camp/enemy lane and its two cover blocks, two guards of one type and one supply objective. Prepare and chamber the rifle, approach, use crouch/lean/cover to avoid or fight the guards, recover the marked supply item, and physically return to the camp side of the lane. A player defeat ends the attempt with a clear debrief. This is a local combat trial; campaign rewards, gear loss and full mission rules must not be inferred from it.

| Increment, pending review | Bounded work | Observable completion |
| --- | --- | --- |
| A. Damage and readable firefight | Give the drill a player damage/defeat path using an actor-level receiver; keep source/team identity explicit. Use the same enemy rules for both visuals. Add basic incoming-hit, exposure/recognition and fire-warning feedback, align enemy ray/flash origin mathematically and introduce deliberate accuracy/reaction limits. | Cover blocks actual hits; enemies do not instantly laser an unseen player; damage and defeat have one owner; zero ends once; swapping visuals leaves results identical. |
| B. Cover traversal and enemy investigation | Use a small authored route/waypoint fixture around the two existing lane cover blocks, collision-check movement, handle blocked routes and return to patrol after losing evidence. Validate and tune the newly implemented tactical movement during combat, retaining its stamina/load rules, stance clearance and sprint/vault firing restrictions. Do not rebuild that movement system. Evaluate one finite enemy magazine/reload cycle using existing weapon rules where practical. | Both guards can reach an observed last-known position around cover without passing through it; they stop tracking an unseen moving player; shots/actions respect the agreed movement rules; enemy reload/exposure creates a usable opening. |
| C. One objective and debrief | Add a single marked supply pickup, return trigger, attempt state and repeatable reset within combat-owned scripts. Show success/defeat, recovered objective and ammunition spent. Prototype attempt snapshots only; do not call this campaign rollback. | Objective counts once; leaving it behind is not success; defeat prevents completing the same attempt; a fresh run resets actors/objective cleanly without duplicating resources. The loop can be completed using cover or avoidance without a forced kill-all condition. |

Keep debug aids toggleable so normal playtests show the intended feedback. Separate perceived facts from actual player coordinates in AI debug views. Use controlled seed/setup for regression checks and human playtests for fairness; passing tests cannot establish compelling gunplay.

Before expanding enemy types, medical depth or maps, plan an early **two-instance combat authority checkpoint**: agree on shots, shared target health, pickups and one player's defeat without ending the other player's play. Four-player maximum, individual mission death, revival and future host-crash campaign rollback remain requirements; this local drill does not prove them. The checkpoint is follow-up scope for review, not newly implemented multiplayer.

## Scope boundary and review decision

No new environment/nature assets, forest layout/terrain/navigation edits, main-menu changes, outfits, character polishing, new weapons, full body-part medicine, armor/penetration, squads, procedural maps, campaign persistence, Steam integration or dedicated servers. Navigation is bounded to a combat-owned lane fixture; no environment-agent scene needs modification. Preserve concurrent inventory work and reuse its physical ammunition rules.

Recommended review scope is A–C with a scalar player damage/defeat model first, then the two-instance checkpoint. Full wounds/revival remain the next casualty milestone. Approve or adjust this boundary before implementing a common health system, weapon-controller extraction or AI navigation changes. No major combat refactor has started.

## Validation completed

Ten focused checks pass in the latest combined local tree: enemy visual parity, MPFB rig/combat, legacy rig/defaults, enemy encounter, tactical movement rules/input/collision/prone/inertia/load/stamina, movement/traversal, ADS, muzzle/obstruction, physical ammunition inventory, and camp interactions. The enemy encounter was rerun after restoring shared lane-facing AI and passes. Render logs for all accepted captures have no script/renderer errors. No multiplayer, campaign persistence, terrain art or main-menu acceptance is claimed.

Concurrent-work reconciliation: the tactical movement agent landed its implementation during this review. Its controller, tuning, HUD, weapon gating and perception changes were inspected read-only and preserved. All ten checks above were rerun against that newer state. Nature/environment and main-menu implementations were not edited. Tactical movement feel and visual acceptance remain the owning agent/owner playtest task.
