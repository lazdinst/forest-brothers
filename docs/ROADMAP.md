# Development roadmap

All milestones are pending. This is a proposed order, designed for a first-time developer and early multiplayer validation.

## 0 — Agree on the first experiment

Review the concept, select the engine/version, and settle the intended multiplayer format sufficiently to guide the prototype. Leave unrelated campaign decisions open.

Done when: the decision log records those choices and the next playable milestone has a clear boundary.

## 1 — A room you can inhabit

Create the minimal engine project. Add first-person movement, mouse look, collision, a door, and a single pickup in a tiny test area. Use placeholders.

Done when: the owner can launch it, move reliably, open the door, collect the item, and follow documented run instructions. It works offline.

## 2 — Two players, one shared world

Add a basic host/join test before building a large inventory or campaign. Exercise two player characters, shared door state, and host-validated pickups.

Done when: two running instances observe the same world; simultaneous pickup attempts award only one item; disconnecting does not leave invalid shared state. Record how movement behaves with simulated latency and how the test was performed.

## 2A — Individual casualties and teammate rescue

Before adding a broad medical inventory, create a minimal playable state flow for injury, incapacitation, teammate treatment during a finite window, mission death, and return to camp. The full medical range is the product direction; this milestone proves the underlying behavior with placeholders.

Done when: a teammate can revive a downed player before expiry; expiry sends only that player to camp; survivors continue; host-character death also leaves survivors playing. Both camp-side and mission-side players stay connected. Interrupted/concurrent treatments and expiry at treatment completion have a defined, consistent result without duplicate item use. Solo/all-incapacitated cases resolve as mission death. Verify that dead players cannot rejoin the same mission, their carried equipment remains recoverable on the body, and camp-stored supplies remain safe. Revival must preserve injuries and temporary capability penalties; agree on placeholder balance values before implementation.

## 3 — One meaningful outing

Build the compact forest/camp/farmhouse slice, a simple objective, one threat, and an observable camp outcome. Prototype gunplay and resource handling only as far as needed for this mission. Add distinct light/heavy bleed, fracture, and pain treatment categories incrementally; keep period research and gameplay effects separate.

Done when: the mission can be completed or failed in solo and co-op, supplies have a visible purpose, individual death leaves surviving teammates able to finish, and a playtester can understand the objective without coaching. Exercise all four player slots before expanding content.

## 3A — Useful work at camp

Prove one minimal camp activity while another player remains on mission: for example, collect water and cook a simple meal, or use a storage station and repair a weapon. Add a small placeable functional structure and a bounded trench interaction in a later increment of this milestone; do not begin with a full terrain system.

Done when: a returned player can complete the chosen camp task without interrupting survivors; costs/results are shared consistently; injuries have the agreed effect; mission lockout still holds. A separate construction increment must demonstrate validated placement, persistent structure state, and the chosen trench representation before broad building content is added. This milestone covers a proof of camp work, not the entire promised camp feature set.

## 4 — A campaign that remembers

Implement the agreed save ownership and failure rules. Persist the relevant camp state, inventory, and mission result, including built structures, station/storage state, recoverable gear rules, and per-player mission death lockouts where an active mission can be resumed.

Done when: completing a mission, quitting, and loading restores the expected state; invalid or incompatible saves fail clearly without silently destroying progress.

## 5 — Prove the intended experience

Improve sound, sprite presentation, feedback, pacing, and usability. Measure performance and test one through four players over a real network, including the four-player cap and individual camp returns during an active mission. Select and validate internet connection/Steam integration options when needed.

Done when: the owner can assess whether the slice delivers tension, immersion, and a reason to care about camp; known networking and performance limits are documented.

## 6 — Expand from evidence

Choose additional locations, tasks, resources, residents, and systems based on playtest findings. Expand the confirmed camp building, trench, food, water, and maintenance systems from the small camp proof. Revisit scope before adding AI squadmates, vehicles, or a large world; these remain unapproved/deferred.

A Steam release plan follows a convincing slice: store materials, licensing review, packaging, onboarding, and release testing. No release date is committed.
