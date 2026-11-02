# Claude progress log

## 2026-11-02 — unattended-work setup

Done:
- Found Godot 4.7.2 console executable in Downloads (not on PATH); headless project load succeeds.
- Created branch `claude/work`.
- Added `tools/run_checks.sh` (runs project load + all 41 headless smoke/check scripts in ~1 min).
- Added `.claude/settings.json` permissions, `CLAUDE.md` notes and this log.
- Did not install GUT: the project already has 41 headless check scripts and AGENTS.md requires
  checking new dependencies with the owner.

Baseline results: 40/41 pass on first run.
- `environment_proof_check` fails consistently: "Existing controller runs along clear trail".
  Belongs to the environment agent's work; left untouched.
- `enemy_encounter_smoke` failed once ("Armed enemy rays reach player hit zones"), passed on rerun — flaky.

Next:
- Waiting for the owner to name the feature task (and approve the combat chunk, per AGENTS.md).

Open questions for the owner:
1. What should be built next?
2. Should the environment_proof_check failure be investigated, or left to the environment agent?
3. Other contributors' uncommitted changes (docs, `assets/props/`, `project.godot`) are in the working
   tree; they are left uncommitted. OK?

## 2026-11-02 — health work and branches combined on `claude/work`

Done:
- Player health (seven parts, bleeds, fractures, pain, energy/water, eight supplies), body looting,
  arm-injury aim sway, tourniquet, surgical kit, infection + sulfa powder, teammate treatment and
  revival (60 s bleed-out, bandage/dressing, 8 s), and a HUD treatment loader. See DECISIONS.md.
- Combined everything on `claude/work` (fast-forward to the merged `health/tarkov-condition`, which
  contains `inventory/body-looting`). The menu, body-zones and enemy-sprite branches were already in
  `main`. Other contributors' uncommitted changes were stashed and re-applied without conflicts.
- The HUD agent's uncommitted `tests/condition_hud_smoke.gd` assumed the old four-zone health; one
  check line now uses `body_part_at(&"arms", ...)`. Their other files are untouched.

Checks: all pass except the known `environment_proof_check`; `enemy_encounter_smoke` still flaky.

Next / open:
- Merge `claude/work` into `main` by pull request when the owner wants.
- Choosing a specific supply/part for a teammate in the inventory; show `care_message` on the HUD;
  lower the rifle during treatment until animations exist; balance numbers; period provenance.
- Old worktrees (`forest-brothers-health`, `-loot`, `-inventory`) can be removed once the owner agrees.

## 2026-11-02 — smarter enemies (owner approved: peek, retreat when hurt, crouch behind crates)

Done:
- Chunk 16, peeking from cover (`enemy_peek_smoke`). `enemy_encounter_smoke` now waits for the solo
  death instead of a fixed 6 s (seven-part health needs a varying number of hits); its 4 s
  "rays reach player" step is still occasionally flaky.

- Chunk 17, blood trails and temperaments (`blood_trail_smoke`): timid flees and hides, steady covers
  and peeks, aggressive pushes while hurt; players and wounded enemies drip blood; enemies follow a
  player's fresh blood. `enemy_encounter_smoke` now waits for the first hit instead of a fixed 4 s.

- Chunk 18, crouching behind crates (`enemy_crouch_smoke`). Cover is now measured from the floor
  (navigation points float 0.5 m up). Crouch sprite is the standing art drawn at 0.9 m (placeholder).

Smarter-enemy chunks done. Next proposed: the arena loop (supply-recovery goal, exit, debrief).
Open: should enemy wounds drain enemy health? Crouch/peek sprite art needs owner direction.
