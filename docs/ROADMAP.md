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

## 3 — One meaningful outing

Build the compact forest/camp/farmhouse slice, a simple objective, one threat, and an observable camp outcome. Prototype gunplay and resource handling only as far as needed for this mission.

Done when: the mission can be completed or failed in solo and two-player co-op, supplies have a visible purpose, and a playtester can understand the objective without coaching.

## 4 — A campaign that remembers

Implement the agreed save ownership and failure rules. Persist the relevant camp state, inventory, and mission result.

Done when: completing a mission, quitting, and loading restores the expected state; invalid or incompatible saves fail clearly without silently destroying progress.

## 5 — Prove the intended experience

Improve sound, sprite presentation, feedback, pacing, and usability. Measure performance and test the agreed player count over a real network. Select and validate internet connection/Steam integration options when needed.

Done when: the owner can assess whether the slice delivers tension, immersion, and a reason to care about camp; known networking and performance limits are documented.

## 6 — Expand from evidence

Choose additional locations, tasks, resources, residents, and systems based on playtest findings. Revisit scope before adding AI squadmates, building, vehicles, or a large world.

A Steam release plan follows a convincing slice: store materials, licensing review, packaging, onboarding, and release testing. No release date is committed.
