# Main menu and training startup

Status: isolated UI implementation for review. No project configuration, training,
environment or character source files are changed. This work introduces no campaign,
network, save or gameplay rules. Shared design logs are intentionally untouched.

## Visual direction and components

The owner's attached concept supplies the warm lamp, field journal, map, aged paper
and burgundy/cream palette. Live Godot controls reproduce the paper-strip menu;
the title uses the correct spelling **Mežabrāļi**. The scene scales its 1280 × 720
composition uniformly and centers it in other aspect ratios. Georgia is requested
through SystemFont, with installed serif fallbacks; no font files or dependencies
are bundled. Artwork is letterboxed with the composition to keep labels aligned.

- `ui/themes/field_journal_theme.gd`: shared paper/ink/burgundy theme factory,
  normal/hover/pressed/disabled/focus states and panel styling.
- `ui/components/menu_button.tscn`: reusable minimum-48-unit button; keyboard
  navigation uses Godot's built-in UI actions, without InputMap edits.
- `ui/main_menu/main_menu.tscn`: standalone menu view with route request signals.
- `startup/startup.tscn`: functional entry point that connects those signals and
  owns local navigation. No autoload is required.
- `startup/scene_registry.gd`: the sole training/menu path registry and pure
  startup-argument resolver.

Training, Controls, Records and Exit are functional. Continue, New Game and Co-op
Game are visibly unavailable because those systems do not exist. Controls replaces
the concept's Settings entry for now: no settings persistence or rendering changes
are implied. Records explains the prototype's current limits.

## Run without changing project.godot

From this worktree, replace `<godot>` with the installed Godot 4.7.2 executable:

```text
<godot> --path . res://startup/startup.tscn
<godot> --path . res://startup/startup.tscn -- --start=training
<godot> --path . res://startup/startup.tscn -- --start=menu
```

Alternatively set `FOREST_BROTHERS_START=training` for the launching process.
User arguments after `--` take precedence over the environment. Only `training`
selects the testbed; empty/unknown routes select the menu. No environment file is
written. Existing F5 behavior and direct training launch remain unchanged. Open
`startup/startup.tscn` in Godot and press F6 to try the launcher in the editor.

Escape from routed training opens a UI-owned navigation layer. Resume restores the
same session and its previous mouse/process modes. Return to main menu asks before
discarding this session, then frees the training instance. A fresh launch resets
training through its existing scene lifecycle. This wrapper disables only its owned
local training subtree; it never pauses SceneTree. This is a local prototype
navigation policy, not a multiplayer pause, casualty, disconnect or mission rule.
Directly launching the training scene retains its existing Escape behavior.

## Integration checkpoint (approval required)

After reviewing this branch and coordinating shared-file ownership, the optional
one-line change in the existing `[application]` section of `project.godot` is:

```diff
-run/main_scene="res://scenes/prototype/camp_test.tscn"
+run/main_scene="res://startup/startup.tscn"
```

This change has **not** been applied. No rendering, input, autoload or other project
settings are needed. Integrate only this branch's UI/startup files, focused test and
this document; retain other agents' training/environment/character changes. The
registry will then load the combined checkout's current training scene at its
existing path. Do not cherry-pick other workstreams to make the launcher work.

## Validation and manual acceptance

```text
<godot> --headless --path . --script res://tests/menu_startup_smoke.gd
<godot> --path . --script res://tests/menu_startup_smoke.gd -- --capture-menu
```

The focused test covers default/environment/CLI precedence, unknown-route fallback,
initial focus, actual Training button routing, existing-scene instantiation, Escape
navigation, process-mode restoration, confirmation cancellation, return and fresh
relaunch. Graphics acceptance requires a rendered view and owner playtesting.
Verify arrow keys/Tab/Enter, mouse hover, Controls/Records closing, Escape/resume,
discard confirmation, and readable layouts at 1280 × 720 and 1920 × 1080.

The worktree starts at commit `55d727e`. Other agents' uncommitted environment and
polygon changes remain in the original checkout and are not copied or committed.
Tests here prove routing to the committed training version; the combined current
training content needs an integration run after authorized integration.

## Validation record and changed files

Validation performed on Godot 4.7.2: the focused check passed headlessly with default
routing, with the training environment override, and with CLI menu overriding that
environment. It also passed using real Compatibility rendering on GTX 1080.
Rendered menu frames were inspected at 1280 × 720 and 1920 × 1080. A direct startup
invocation with `--start=training --quit-after 15` exited successfully. The engine
reported restricted-environment certificate-store warnings; initial editor import
also could not save user-level editor settings. Neither blocked the scene checks.
Import's incidental line-ending changes were restored only in the isolated worktree;
the final protected-path diff is empty. No game-feel or multiplayer validation is
claimed. No merge or shared default-startup change was performed.

Changed-file manifest (all new):

```text
docs/UI_DESIGN_SYSTEM.md
startup/scene_registry.gd
startup/scene_registry.gd.uid
startup/startup.tscn
startup/startup_router.gd
startup/startup_router.gd.uid
tests/menu_startup_smoke.gd
tests/menu_startup_smoke.gd.uid
ui/assets/field_journal_background_v1.png
ui/assets/field_journal_background_v1.png.import
ui/components/menu_button.tscn
ui/main_menu/main_menu.gd
ui/main_menu/main_menu.gd.uid
ui/main_menu/main_menu.tscn
ui/themes/field_journal_theme.gd
ui/themes/field_journal_theme.gd.uid
```

## Artwork source and prompt

`ui/assets/field_journal_background_v1.png` was prepared using the built-in imagegen
tool from the owner's supplied concept image. It is an independent UI asset, not
an environment/character production dependency. The pictured photograph is concept
art, not an archival source; no historical identity, map accuracy or emblem
interpretation is asserted. No in-image text is used as a control or translation.

Final prompt:

> Use case: precise-object-edit. Asset type: 16:9 Godot main-menu background plate.
> Edit the supplied concept art. Preserve the warm lantern, worn olive field journal
> with Latvian burgundy/cream woven ribbon, compass, photograph, map, wood table,
> exact composition and gritty painted material richness. Remove the entire left
> menu panel including its paper strips, icons and all menu text, reconstructing
> the underlying map naturally. Remove ALL lettering and emblem from the book
> cover, leaving a blank worn olive cloth cover with its tree silhouette illustration
> retained low on the cover. The game engine will render accessible live menu text
> and title separately. No new words or symbols, no watermark. Keep clear map space
> on left for overlay controls, book on right. Output landscape 16:9.
