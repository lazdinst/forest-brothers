@AGENTS.md

# Claude Code notes — Forest Brothers

`AGENTS.md` (imported above) is the authoritative project guide; this file only adds
machine-specific commands and unattended-work rules. Do not duplicate design content here.

## Engine and language

- Godot **4.7.2 stable**, Compatibility renderer (`project.godot` features `4.7`, `GL Compatibility`).
- GDScript only; no C#/.NET, no addons.
- Executable (not on PATH):
  `/c/Users/Nauda/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`
- Main scene: `res://startup/startup.tscn`. No autoloads.

## Folders

- `scripts/<area>/` — GDScript by system (camp, characters, combat, environment, inventory, player, weapons, …).
- `scenes/<area>/` — matching `.tscn` scenes. `startup/`, `ui/` — menu and interface.
- `weapons/` — weapon definition resources (`.tres`). `assets/` — imported art/audio. `art_source/` — preserved sources, excluded from import.
- `tests/` — headless smoke/check scripts (`*_smoke.gd`, `*_check.gd`); `*_review.gd`/`*_preview.gd`/`*_visual.gd` need a GPU.
- `docs/` — design, decisions, roadmap, pipelines. `tools/` — helper scripts.

## Validation and tests

The project uses its own headless check scripts (exit nonzero on failure), not GUT/gdUnit4.

```bash
tools/run_checks.sh                 # project load + every smoke/check script (~1 min)
tools/run_checks.sh enemy           # only checks whose name contains "enemy"
```

Single check: `<godot> --headless --fixed-fps 60 --path . --script res://tests/<name>.gd`.
If `.godot/` is missing, run `<godot> --headless --path . --import` first (the runner does this).
Headless checks do not prove visuals, game feel or multiplayer.

Known baseline (2026-11-02): `environment_proof_check` fails ("Existing controller runs along clear
trail") — environment agent's area, do not modify; `enemy_encounter_smoke` is intermittently flaky.

## Code style observed

- Tabs for indentation; `snake_case` functions/variables, `UPPER_SNAKE` constants.
- Scripts start with `extends`, then a `##` doc comment stating the script's responsibility.
- `preload` dependencies into `const` names in PascalCase; typed vars (`var x: int`, `Array[int]`).
- Rules (state/authority) separate from presentation/input adapters; definitions in `.tres` resources.
- Commit `.gd.uid` files alongside new scripts; never commit `.godot/`.

## Unattended working rules

- Work on branch `claude/work`. Never commit to or check out `main`; never force-push or delete branches.
- **Commit after every working step with a clear message.** Before each commit: run `tools/run_checks.sh`
  and fix anything you broke. Never leave the project failing to load.
- Stage only your own files (`git add <paths>`); the working tree contains other contributors'
  uncommitted changes (docs, `assets/props/`, `project.godot`) that must not be committed by you.
- Combat chunks need owner approval before starting (see AGENTS.md). Stop and ask for anything hard to
  reverse or ambiguous: deleting scenes/assets, core architecture, autoloads, new dependencies.
- Keep `CLAUDE_PROGRESS.md` current: done, next, open questions.
