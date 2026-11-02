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
