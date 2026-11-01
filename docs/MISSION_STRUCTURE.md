# Mission structure and campaign progression

Status: confirmed product rules with explicit remaining design questions. No gameplay is implemented.

## Setting and map

Working setting: Latvia around 1946. Region and exact settlement remain open. Start with one handcrafted map; a Latvian town/city is an example. Supplies and selected portions vary randomly between outings. This does not commit to a fully procedural city: the degree of variation is undecided. Candidate approaches include authored alternate interiors, blocked routes, or modular areas, to be evaluated rather than treated as requirements.

Generate each session's variation once under host authority. Reconnecting must return to the same world, loot, and time state.

## Quests, returns, and survival are separate

Players may leave early with carried supplies and rescued civilians even if they have not completed the main objective. Returning alive does not itself complete a quest. Incomplete quests do not advance the main chain or grant completion rewards. Whether sub-objective progress persists across attempts, and what counts as completing/turning in an objective, remain open.

Main-quest completion unlocks more missions and provides construction-material rewards. The long-term goal for now is developing the camp and resisting; no final ending is specified. Reward amounts, replay rules, upgrade dependencies, and additional equipment/location unlocks remain to be designed.

Optional scavenging outings allow recovery when the group lacks supplies for main missions. Scavenging is an activity on the mission map, not approval for a separate faction, free random loadout, PvP mode, or automatic supply grant.

## Outcomes

| Event | Confirmed result |
|---|---|
| Early safe return with objective incomplete | Preserve safely returned supplies and secure rescued civilians; main quest remains incomplete |
| Main quest completed | Advance the relevant chain and award its construction materials under the eventual completion/turn-in rule |
| Individual mission death | Return that player to camp; carried gear stays behind; no same-mission redeployment; survivors continue |
| Rescuer dies, teammates safely return | Teammates can still secure the group's pending recruits |
| Solo/total-group mission death | Pending recruits are lost or die en route; carried gear is not brought home |
| Mission deadline expires | Fail the outing; players still on the map suffer mission death, losing carried gear and pending civilians |
| Non-host disconnect | Character remains present and vulnerable; reconnect can restore control if alive |
| Host crash | End the outing; restore the entire campaign to the pre-mission baseline, as if the outing never happened |

Existing camp residents are unaffected by an ordinary pending-recruit loss, but can separately die from camp shortages. A crash rollback also restores their pre-mission state.

## Deadline and returns

Outings last a maximum of one hour. Deadline expiry is confirmed as mission death for players still on the map, not a safe automatic return. Exact clock basis, shorter mission limits, warning schedule, exit interaction, and how to resolve return/death at the deadline need implementation rules.

Players who already returned safely are not still on-map and must not be killed by a later timeout. How shared civilian arrivals and quest outcomes commit when players leave at different times, especially when others later time out, must be settled explicitly. Do not silently erase secured returns or award pending arrivals twice.

## Disconnection and hosting

Non-host disconnection is not a safe exit. The same character remains in the mission until killed or otherwise normally resolved. Reconnecting resumes that living character; death lockout still applies if they died while disconnected. Uncontrolled posture/behavior, grace periods if any, authenticated identity, and intentional quit behavior remain to design. Host-character death is separate and does not stop the session.

First pass: a host crash ends the mission and rolls back every player and the entire campaign, including concurrent camp building, cooking, material use, resident state, rewards, and mission outcomes, to before deployment. Earlier safe returns within that running outing are also undone by a crash rollback. Save a consistent durable baseline before mission side effects begin.

Intentional shutdown, crash detection, and commit-boundary behavior still need specification. Later dedicated-server support is a confirmed goal, inspired by the owner's Valheim reference; hosting/security/deployment operations are not part of the first prototype.

## Camp economy and recovery

Civilians construct, cook, and perform similar jobs; players may assist as foremen. Some residents can be ordinary NPCs rather than workers. Main-mission rewards supply construction materials, with quantities and additional sources undecided.

Shortages can kill civilians and leave the group unable to prepare for main-quest outings. There is no permanent campaign game-over. Optional scavenging must allow recovery, including a viable design for having no workers or almost no equipment. Exact minimum loadout, civilian-needs rates, warnings, and deployment gates remain open; do not invent free supplies or a hard soft-lock.

A medical facility unlocks after a handful of completed main missions and speeds healing. Exact duration, unlock count, and recovery multiplier are intentionally deferred.

## Questions still requiring decisions

- Physical exit locations, exit requirements, and whether players can return independently.
- When returned supplies/recruits become usable during staggered co-op returns.
- Partial quest progress, required return/turn-in items, and objective completion if a player later dies or times out.
- Which authored map portions vary, and whether new outings reset all supplies.
- Civilian work assignment and player assistance behavior.
- Shortage warnings, population consumption, and how an almost empty camp can recover.
- Clock behavior, planning/pause rules, and intentional host shutdown.
- Concrete combat and enemy-perception rules: see [combat design](COMBAT_DESIGN.md).
