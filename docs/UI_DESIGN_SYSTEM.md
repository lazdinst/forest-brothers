# Main menu and training startup

Equipment and inventory layout: see [Inventory UI Design](INVENTORY_UI_DESIGN.md).
It reuses these paper components and opens with Tab during routed training.

Status: UI implementation integrated into the shared `main` branch at the owner's
request. Only the default startup scene changes in project configuration; training,
environment and character source files are unchanged. This work introduces no campaign,
network, save or gameplay rules. Shared design logs are intentionally untouched.

## Visual direction and components

The owner's attached concept supplies the warm lamp, field journal, map, aged paper
and burgundy/cream palette. Live Godot controls reproduce the paper-strip menu;
the title uses the correct spelling **Mežabrāļi**. The scene scales its 1280 × 720
composition uniformly and centers it in other aspect ratios. Georgia is requested
through SystemFont, with installed serif fallbacks; no font files or dependencies
are bundled. Artwork is letterboxed with the composition to keep labels aligned.

Paper finish: the shared theme uses the transparent `paper_sheet_v1.png` texture
with nine-slice StyleBoxTexture surfaces, rather than flat fills or straight border
outlines. The main action list sits on a continuous worn sheet; buttons reuse the
same paper in strip form with burgundy tints for hover/focus/press. Modal and camp
frames use the full sheet with dark ink text. The original PNG is retained at full
resolution; its UI import is limited to 512 px for lightweight reusable rendering.
The existing startup/component regression passed with this theme, and rendered
main-menu and confirmation frames were inspected. No protected asset was modified.

- `ui/themes/field_journal_theme.gd`: shared paper/ink/burgundy theme factory,
  normal/hover/pressed/disabled/focus states and panel styling.
- `ui/components/menu_button.tscn`: reusable minimum-48-unit button; keyboard
  navigation uses Godot's built-in UI actions, without InputMap edits.
- `ui/components/menu_actions.gd`: the shared action-list builder. Views supply
  stable action IDs, captions, enabled states and optional hints; this component
  creates the buttons, keeps Tab/arrow navigation inside the enabled actions, and
  emits `action_selected(id)`.
- `ui/components/menu_panel.gd`: shared themed frame for custom content.
- `ui/components/menu_modal.gd`: shared full-screen scrim, panel, heading, scrollable
  message, action list, focus restoration and Escape cancellation. Pause, leave
  confirmation, Controls and Records all reuse this component. `present()` replaces
  its content; it never creates another modal over the current one.
- `ui/main_menu/main_menu.tscn`: standalone menu view with route request signals.
- `startup/startup.tscn`: functional entry point that connects those signals and
  owns local navigation. No autoload is required.
- `startup/scene_registry.gd`: the sole training/menu path registry and pure
  startup-argument resolver.

Training, Controls, Records and Exit are functional. Continue, New Game and Co-op
Game are visibly unavailable because those systems do not exist. Controls replaces
the concept's Settings entry for now: no settings persistence or rendering changes
are implied. Records explains the prototype's current limits.

## Run

From this worktree, replace `<godot>` with the installed Godot 4.7.2 executable:

```text
<godot> --path . res://startup/startup.tscn
<godot> --path . res://startup/startup.tscn -- --start=training
<godot> --path . res://startup/startup.tscn -- --start=menu
```

Alternatively set `FOREST_BROTHERS_START=training` for the launching process.
User arguments after `--` take precedence over the environment. Only `training`
selects the testbed; empty/unknown routes select the menu. No environment file is
written. F5 now opens the menu; direct training launch remains available. Open
`startup/startup.tscn` in Godot and press F6 to try the launcher in the editor.

Escape from routed training opens a UI-owned navigation layer after any existing
camp panel/planning context has handled Escape. It never opens pause over those
contexts. Resume restores the
same session and its previous mouse/process modes. Return to main menu asks before
discarding this session, then frees the training instance. A fresh launch resets
training through its existing scene lifecycle. This wrapper disables only its owned
local training subtree; it never pauses SceneTree. This is a local prototype
navigation policy, not a multiplayer pause, casualty, disconnect or mission rule.
Directly launching the training scene retains its existing Escape behavior.

## Reusing menu components

New action lists should instantiate `menu_actions.gd` and call
`add_action(id, caption, enabled, hint)`. New messages or confirmations should
instantiate `menu_modal.gd`, connect `action_selected`/`canceled`, then call:

```gdscript
modal.present("Leave training?", "Discard this training session?", [
    {"id": &"cancel", "caption": "Keep training"},
    {"id": &"confirm_leave", "caption": "Return to main menu"},
])
```

Use one modal instance per navigation owner; change its content for confirmation
and cancel back to the prior view. Call `dismiss()` when done. Do not create native
AcceptDialog/ConfirmationDialog windows or duplicate button/layout construction in
each view. The theme factory returns one shared Theme resource for every component.

`ui/training_ui_bridge.gd` is a narrow compatibility adapter for the existing camp
UI. It inserts the shared panel frame, applies the same theme/button sizing to
existing and dynamically added buttons, and reports active camp/planning contexts
to startup navigation. It preserves their callbacks and does not change camp,
character, combat or environment source files. It currently binds the existing
`SystemsAnnex` presentation fields; if that view is replaced, update this adapter
or have its owner adopt the shared components directly. This adapter is installed
by routed training; direct standalone training still uses its original UI.

## Approved integration

The owner requested integration into the branch used by the other agents. The
one-line change in the existing `[application]` section of `project.godot` is:

```diff
-run/main_scene="res://scenes/prototype/camp_test.tscn"
+run/main_scene="res://startup/startup.tscn"
```

This change has been applied. No rendering, input, autoload or other project settings
were changed by this work. The UI commit was cherry-picked into `main`, preserving
the other agents' uncommitted changes. The registry loads the combined checkout's
current training scene at its existing path.

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
The original isolated checks proved routing to the committed training version.
After integration, the focused check passed against the combined current checkout,
including its environment and polygon character additions. Default startup and the
`--start=training` override also launched successfully with bounded headless runs.
These integration runs do not establish graphics quality or multiplayer support.

Shared-component follow-up: the focused startup check also covers the single
modal instance, in-place confirmation/cancel, shared theme identity, dynamically
created camp button styling, a real click on the restyled camp action without
firing, and Escape precedence for both camp panels and planning. The existing
`camp_annex_smoke.gd` regression passed. Compatibility-rendered Controls, pause,
leave confirmation and camp-panel frames were inspected. Certificate/shader-cache
write warnings occurred in the restricted environment; checks passed.

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
claimed. These results describe the original isolated validation; the approved
shared default-startup integration is described above.

Changed-file manifest (UI files new; project startup setting modified on integration):

```text
docs/UI_DESIGN_SYSTEM.md
project.godot
startup/scene_registry.gd
startup/scene_registry.gd.uid
startup/startup.tscn
startup/startup_router.gd
startup/startup_router.gd.uid
tests/menu_startup_smoke.gd
tests/menu_startup_smoke.gd.uid
ui/assets/field_journal_background_v1.png
ui/assets/field_journal_background_v1.png.import
ui/assets/paper_sheet_v1.png
ui/assets/paper_sheet_v1.png.import
ui/components/menu_button.tscn
ui/components/menu_actions.gd
ui/components/menu_actions.gd.uid
ui/components/menu_modal.gd
ui/components/menu_modal.gd.uid
ui/components/menu_panel.gd
ui/components/menu_panel.gd.uid
ui/main_menu/main_menu.gd
ui/main_menu/main_menu.gd.uid
ui/main_menu/main_menu.tscn
ui/themes/field_journal_theme.gd
ui/themes/field_journal_theme.gd.uid
ui/training_ui_bridge.gd
ui/training_ui_bridge.gd.uid
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

The paper asset was generated with the built-in imagegen tool, requesting actual
transparency (verified corner alpha 0), with this prompt:

> Asset type: reusable game UI parchment texture, not a finished menu screenshot.
> A SINGLE blank rectangular piece of warm aged cream paper, flat front-on scan,
> roughly 3:2 landscape aspect. It fills nearly the entire canvas, with only 2
> percent transparent padding on each side. All four edges are gently irregular
> torn/deckled paper with small nicks and frayed fibers, NOT heavily burned, no
> rolled corners. Fine pressed paper fibers, subtle creases and uneven pale ochre
> staining at perimeter; mostly light softly varied center for dark text
> readability. Gritty painted material realism like a worn 1940s field notebook
> in warm lamplight. Entire object uniformly lit, no perspective, no cast shadow
> outside the paper. Perfectly blank: NO writing, NO lettering, NO icons, NO
> border lines, NO other objects. Real transparent background. Important this
> will be nine-sliced and stretched for reusable menu panels and paper strips;
> keep corners flat and avoid distinctive large marks.
