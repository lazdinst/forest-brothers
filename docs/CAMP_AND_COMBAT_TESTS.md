# Camp, NPC and enemy training tests

Restart Godot with **F8 → F5**. The shooting range, movement course and camp/enemy training area form one walkable map. From the original spawn, turn around and follow the **Camp / Workshops** signs to the right, behind the firing lanes (approximately z 18). Continue east through the open west entrance into camp. Walk back the same way to return; there are no travel tables or transition menus. The existing player, rifle state and communal supplies stay intact. **P** still resets to the original spawn.

Everything here is a local test fixture. Costs, job times, damage, rewards, healing and debug supplies are temporary. Nothing saves when the game closes. This is not the implemented campaign, multiplayer, or a cash-trading economy.

## Recommended test order

1. **Starting supplies / quartermaster:** every fresh training session begins with 100 food, 100 water, 30 medicine, 30 meals, 200 timber, 60 parts, 80 cloth and 500 communal cartridges. Icons with names/counts appear in the HUD, camp panels and inventory. The center-front quartermaster table offers an additional one-time training cache; repeated claims fail. No money or private player stash is introduced. Original yard pickups still use this same ledger.
2. **Civilian (optional):** you can do station tasks yourself without any assignment. To try delegated work, walk around the quartermaster table to the older civilian, press F, and assign **cook**. One initial worker is available. The preserved painted civilian represents training roles; this does not add a finalized cast.
3. **Well:** draw water. It takes two seconds and deposits two water in communal storage.
4. **Cooking workshop:** cook a meal for one food and one water. Choose **Do it yourself** and remain at the station until the timer completes, or **Assign civilian cook** with an available cook. Ingredients are reserved once at the start; the meal appears when work completes. For personal work, closing the menu or leaving cancels and refunds reserved ingredients. Delegated civilian work continues when you leave. Foreman assistance shortens a civilian job once. Trying another job on the same worker while busy fails clearly.
5. **Food store:** inspect raw food and meal quantities, then provision the starting resident with one meal and one water. This fixture provisions each resident once; automatic hunger, starvation and spoilage are not implemented.
6. **Armourer:** use G outside menus to dirty your carried rifle, then order service at the bench. It consumes one part and restores cleanliness after three seconds. A jam remains a separate problem, cleared with J. This does not restore fired ammunition.
7. **Ammunition store:** withdraw or return ten loose cartridges. Compare communal stock and carried loose rounds; the sum stays constant. Packing still requires holding T, and R still swaps actual magazines.
8. **Medical post:** the separate test patient starts with bleeding, a fracture and recovery time. Bandaging uses cloth and treats bleeding only; splinting uses cloth and timber and treats the fracture. Medical recovery requires those conditions to be treated and then uses one medicine. The visible cot uses the preserved civilian sprite as a stand-in. These are test abstractions, not period medical research or the player casualty system. The vitality reset button is explicitly a combat-debug control.
9. **Building:** upgrade the shelter yourself, or assign the available civilian **builder** to delegate it. Order the shelter upgrade for four timber and one part; inspect the added walls. You can help once as foreman. Cancel an active job to return its reserved materials once. Repeated refunds and duplicate upgrades are blocked.
10. **Planning table:** enter the overhead view. Click inside the marked west plot to place a supply-rack plan. Invalid/overlapping footprints fail without spending. Press Esc to return to first person; use the table again to build the placed plan yourself for two timber, or assign a civilian builder. Completed racks become solid. Construction waits if a player/solid object occupies the footprint, then finishes once it clears. This proves one freely placed plan alongside the predefined shelter upgrade, not a finished city-building interface or capacity system.
11. **Trench site:** order the marked dig task and inspect the resulting earthwork marker and banks. It is an authored surface representation; the floor is not excavated or deformed yet.
12. **Headquarters:** begin a rescue exercise. It resets the opponents and makes the northern marked civilian available. Find that civilian, press F, and watch the civilian depart using the preserved sprite movement. They remain pending; the camp count must not increase yet. At HQ choose **safe return** to secure them, or **group-death result** to lose pending recruits while established residents remain. Safe return without the objective secures the recruit but awards no objective reward. Defeating a test enemy during an active exercise sets the objective; a subsequent safe return awards three timber once. These manual result controls test recruitment/accounting, not a real mission map, deadline, individual deaths or networking.

## Enemy encounter

The northern lane has two fictional test opponents and solid cover. Their default idle state lets you inspect both painted sprite opponents and shoot without being attacked. Three normal forty-damage rifle hits defeat one; reloading and jams still apply.

At **Enemy test controls**, arm the bout to exercise detection and return fire. It moves you to the lane entrance. Enemies build recognition through visible exposure, react after a delay, and ray-check before firing. Cover blocks sight and fire. They investigate approximate gunshot/footstep positions, share nearby alerts, and eventually stop searching when no new sight or sound occurs. Crouching reduces visual recognition and footstep range; running is louder. This is a small movement/search test without navigation-pathfinding, surface-specific footsteps, squads or finished accuracy tuning.

The training vitality counter loses twenty per enemy hit while armed. At zero, opponents stop and you return to the annex entrance. Restore vitality from the medical panel before another bout. **This is not mission death, carried-gear loss, wounds, incapacitation or revival.** Those campaign rules remain pending. Armed enemies continue while menus are open.

Hits show a brief tint and small dark-red particle burst. Both default opponents use the preserved sprite collapse into a ground corpse, a temporary small blood mark, and disabled body collision. It is not a generated death sprite sequence or a dismemberment system. Use the controls to reset enemies/corpses/blood or disable future blood effects. Opponent art currently has empty hands; a small flash proxy represents firing until weapon/aim poses exist. It is not an approved uniform or historical character reconstruction.

## Shared assets and other-agent review

Reviewed **Prototype Latvian forest biome**, its current files and training integration. That work owns the spruce, fern, moss/dirt, boulder, crate and environment pipeline. Those scenes/materials are unchanged here. The annex optionally reuses its crate on storage tables; no duplicate trees, textures, rocks or crates were generated. Camp workshop geometry is functional blockout geometry intended to accept future environment-art replacements.

The annex is installed additively by `scripts/prototype/training_course.gd`; the environment agent's main-scene/material changes remain intact. Camp mechanics live under `scripts/camp`, combat under `scripts/combat`. Only one new neutral guard image was generated for the initial laboratory. That image and the civilian sprites remain the normal-play art after the owner rejected the procedural polygon blockout. Exact generation prompt and provenance are in `assets/characters/training_guard/PROVENANCE.md`.

The environment agent has since expanded the testbed forest/terrain and added a physical trench. Refer to ENVIRONMENT_ASSET_PIPELINE.md for its current scope, measurements and owner-review status. This annex does not regenerate those assets.

## Validation and next milestones

At the original laboratory milestone, thirteen checks passed against the combined local tree: the eight existing player/weapon/character checks, `environment_proof_check`, `training_environment_check`, and the three new checks below. GPU-rendered camp, workshop menu, planning, enemy and corpse frames were inspected on the GTX 1080 Compatibility renderer. No multiplayer or final animation quality is claimed.

```text
<godot> --headless --fixed-fps 60 --path . --script res://tests/camp_workshops_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/camp_annex_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/enemy_encounter_smoke.gd
```

The rule check exercises every workshop, atomic shortages, duplicate spending, cancellation/refunds, worker ownership, assistance, ammo conservation, plans, and recruitment results. The scene check uses the player's real interaction ray for twelve stations, a real UI click without firing the rifle, the resident panel, a projected planning click, and camera/yard return. The encounter check uses actual rifle shots, corpse transitions, cover, search decay, reaction delay and firing.

Next foundational work remains host/join authority and two-instance testing, then individual casualties/revival and a real mission-return loop. Full injuries, co-op friendly fire, host-crash rollback, campaign persistence, NPC work movement/hauling, proper opponent weapon/death frames, and final period research remain unfinished. Do not mark roadmap milestones 2, 2A, 2B or 3A–3D complete from these local fixtures.

A shared polygon rig was subsequently tested, then rejected by the owner on appearance and clothing scalability. Normal-play residents/patient/opponents now use sprites again; the polygon player body is off by default and the rig display remains an explicitly labeled technical fixture. Read MODULAR_CHARACTER_BRIEF.md before replacement work. See POLYGON_CHARACTER_PIPELINE.md for current asset source, rig/animation validation and remaining art work. Current combined validation has fifteen checks including that rig check and the other agent's physical forest/trench check.

### Continuous-map verification

The annex integration check now walks the player from the main yard along z 18.3 through the open west entrance and back, using movement input without jumping or interacting. It checks carried ammunition and all twelve station interactions/planning afterward. Movement/range, training environment, forest terrain/trench and opponent checks also pass. Compatibility-rendered entrance/return views were inspected; owner playtesting remains pending.

Resource display validation: startup supplies and additive one-shot pickups, camp station interactions, workshop spending/refunds and inventory snapshot checks pass. Drawn category icons reuse the inventory symbol component; medicine, cloth and cooked meals have distinct marks. Counts update from the communal ledger. Supplies reset on a fresh training launch and do not define campaign balance.

Personal-work validation covers cooking/upgrading/rack building without any civilians, one personal job per player, duplicate/remote request rejection, interrupted refunds once, and civilian jobs continuing independently. The annex check presses the primary cooking button with the civilian unassigned and verifies actual meal production and closing-panel cancellation.

## Latest priority: character comparison frozen

Both enemies default to sprites. The combat-control panel's **Compare first enemy** button resets the bout with MPFB or the sprite; the second enemy stays a sprite. This control changes presentation only and does not change communal stock or carried ammo. Read CHARACTER_FREEZE_AND_COMBAT_SLICE.md for visual issues, current combat/movement and the proposed next drill. No further character art or major combat refactor is authorized until the proposed scope is reviewed.
