# Combat design

Status: approved behavior from the owner's combat discussion on 2026-11-01. Detailed interaction design, numerical tuning, and weapon selection remain open. A local training rifle now tests cartridges, retained magazines, manual loading, dirt/jams, and targets. Local opponent damage, bounded perception/search, return fire, hit feedback, blood and procedural death now have a training test; see CAMP_AND_COMBAT_TESTS.md. Full AI/navigation, player wounds/casualties, friendly fire and multiplayer remain unimplemented. See `GETTING_STARTED.md`; test timings and the sample rifle do not settle final balance or the weapon roster.

## Perception and searching — confirmed

- Enemies need line of sight for visual recognition. Recognition builds with exposure, affected by distance, movement, and stance rather than every distant glimpse producing instant combat.
- Footstep sound depends on pace and surface. Gunfire/noise prompts investigation toward an approximate location, without granting exact tracking through walls.
- After losing sight or hearing a suspicious sound, enemies investigate/search a last-known area. Searches eventually decay, allowing successfully hidden players to escape detection.
- Alerts spread locally with escalation, not through instant map-wide shared knowledge.
- Reaction and accuracy follow readable limits. Avoid immediate perfect fire through vegetation or from unseen positions.

Exact detection curves, hearing range/occlusion, recognition thresholds, search duration, communication range/delay, and reaction/accuracy values require playtesting. Light/cover modeling and additional perception factors need a scoped implementation decision; acceptance of the starting behavior is not approval for unlimited AI complexity.

## Physical ammunition and manual magazine loading — confirmed

Loose cartridges and magazines are separate inventory items. Players refill magazines using the cartridges they have, rather than reloading from an abstract ammo pool. A partial magazine retains its remaining rounds when removed or moved between inventories. All items remain communal; physical custody still controls which ammunition a player can use.

The owner cites Tarkov's manual loading as the reference. This does not automatically approve its complete ammunition catalog, UI, inventory layout, skills, or loading timings.

Detailed choices still open:
- Loading duration, interruption behavior, and whether unloading is supported initially.
- Magazine/weapon compatibility, capacities, and which historical weapon is prototyped first.
- Detachable versus integral-magazine handling for the eventual roster; do not force every period weapon into one detachable-magazine model.
- Chamber representation, mixed cartridge types/order, and ammunition variants.
- Exact versus estimated on-weapon counts, inspection interaction, magazine selection, and reload controls.

Readable communal stock counts remain required. This does not settle whether the firing HUD exposes an exact magazine count. Any stock summary must avoid counting loaded rounds twice.

## Maintenance and jams — confirmed

Weapons can jam. Jam risk rises when a weapon is not cleaned or serviced. Condition is visible, and there is a maintenance/repair path. Cleaning, servicing, repair, and clearing a current jam are related concepts whose exact gameplay relationship still needs design; do not silently make them identical or automatically repair a weapon during a reload.

Open choices include how maintenance degrades, what supplies/workstations are needed, whether field cleaning is possible, who performs service, how a jam is communicated and cleared, and how service changes reliability. Accuracy penalties, permanent deterioration, specific malfunction types, and exact jam rates are not confirmed.

The prototype should make a neglected weapon measurably less reliable under controlled tests while keeping state understandable. Fairness and final frequency need playtesting.

## Friendly fire — confirmed

Teammates can injure and incapacitate one another. Apply the normal medical, rescue-window, and mission-death rules to friendly-fire casualties. Friendly fire does not itself make competitive PvP an approved mode.

Damage scaling, identity cues, accidental-fire feedback, camp weapon use, explosive interactions, optional toggles, and anti-griefing policies are unresolved. Do not invent immunity, punishments, or a safety switch as default behavior.

## Verification and scope

Start with one appropriate weapon and a bounded encounter. Verify round conservation, partial-magazine persistence, jam-state agreement, teammate injury/revival, recognition buildup, approximate sound investigation, and search decay. Test interruption, disconnect, death recovery, and full-campaign rollback once those systems exist.

Historical weapons and ammunition must fit the working 1946 setting and local availability; no roster is selected yet. Modern optics, specific suppressors, elaborate ballistics, and a full tactical AI squad system are not implied by these approvals.
