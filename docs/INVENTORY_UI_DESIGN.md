# Personal inventory interface

Status: owner-requested inventory design prototype. Worn equipment, a current
character pane and a large carried-inventory area are requested. Owner-confirmed:
this screen shows only what is on the person; camp storage is a separate interaction.
Each pack item occupies one square. Pockets are exactly four squares in a horizontal
line and hold at most four items. Total pack capacity, clothing slots, stack limits
and other interactions remain proposals.

## Reference review

The owner's supplied Escape from Tarkov screenshot is the primary visual reference:
equipment slots flank a central character, smaller carried containers occupy the
middle, and a large contextual container occupies the right. Item footprints,
quantity labels, visible empty space and clear container boundaries make custody
and capacity easy to scan. The screenshot's right pane is labelled loot/ground
cache. Following owner clarification, this personal screen omits that external
container and devotes the large right sheet to pockets and pack space instead.

The [publisher's Steam listing](https://store.steampowered.com/app/3932890/Escape_from_Tarkov/)
was checked for product context. The official website rejected automated access
with HTTP 403. No current-version inventory mechanic is inferred from that failed
lookup. Layout analysis is based on the supplied image, not third-party guides.
No Tarkov artwork, icons, fonts, weapon pictures, branding or UI files are copied.

| Reference pattern | Forest Brothers interpretation |
| --- | --- |
| Character with equipped slots | Left paper sheet, current visual pane and six proposed clothing/equipment positions |
| Carried magazines and small containers | Separate loaded/spare magazine and loose-cartridge quantities from existing weapon state |
| Backpack grid | Large right-hand pack grid; every item takes exactly one square |
| Small carried containers | Four pocket squares in one horizontal row, maximum four items |
| Large external container | Omitted here; camp stores require their own separate interaction/menu |
| Item inspection | Click a card/slot to read its context in the lower paper strip |
| Dark modern interface | Existing torn paper, fibers, ink lines, serif type and burgundy interaction states |

No secure container, item insurance, cash economy, private stash, modern armour
roster, weight balance or remote transfer mechanic is introduced.

## Run and inspect

In the shared main checkout, start training from the menu and press **Tab**.
Alternatively choose **Equipment & inventory** in the pause menu. **Tab**, **Escape**
or **Back** closes inventory and restores the previous local control mode. Inventory
does not stack over an open camp panel/planning view or the pause menu. Only the
local training subtree is suspended; SceneTree is never globally paused.

Open `ui/inventory/inventory_view.tscn` and press F6 for the standalone design
preview. This version explicitly labels its sample outfit, provisions and pack
arrangement. Its Back action emits a view-close signal for a containing owner; F8
stops the standalone scene in the editor. The main-menu Controls panel lists Tab.

The composition scales uniformly from 1600 × 900. The large right sheet contains
four pocket cells and a provisional 9 × 4 pack layout (36 shown spaces, preserving
the prior draft's slot count). Only the four-pocket capacity and one-square item
footprint are confirmed; total pack capacity remains unapproved.

The training adapter reads only the supplied player's rifle definition, condition,
jam state, magazine contents and loose rounds. It no longer accepts or reads camp
stock. The live build has no per-location carried-item records yet: pack and pocket
entries stay empty rather than inventing possessions or assigning existing ammo to
an unconfirmed pocket location. Carried ammunition remains a separate summary.
Standalone preview data demonstrates pocket and pack items and is clearly labelled.
No source is mutated, transferred or refilled by viewing this screen.

## Current character limitation

The owner rejected the procedural character blockout, and the current playable
player normally has no BodyVisual. This UI does not reload that rejected asset or
substitute the civilian/enemy sprite as the player. It displays a labelled neutral
ink mannequin and marks live clothing slots as not recorded until actual equipment
records exist. Only the standalone preview uses an explicitly sample outfit.

`character_preview.gd.bind_visual(visual)` accepts the supplied current Node3D body
when one exists. It duplicates that visual with scripts/signals/groups disabled
into an isolated SubViewport world, restores full mesh rendering in the copy and
supports left/right rotation. It does not rotate or change the world character.
This is a binding point for the character owner's approved replacement; it does
not prove that replacement's framing, garment fit, rig or animations. Skeleton and
wardrobe validation remains with that workstream under MODULAR_CHARACTER_BRIEF.md.

## Components and ownership

- `ui/inventory/inventory_snapshot.gd`: read-only training-to-UI adapter plus clearly
  separate standalone sample data. Takes only an explicit player; no global
  player reference or new inventory authority.
- `ui/inventory/inventory_grid.gd`: reusable view grid with selectable item cards.
  Each entry takes one square regardless of legacy span metadata. Over-capacity
  snapshots are rejected before changing visible entries, so a fifth pocket item
  cannot disappear silently or displace an existing item. This view validation does
  not replace future authoritative pickup/transfer rules.
- `ui/inventory/item_symbol.gd`: original code-drawn category sketches, not final or
  historically verified item art. No protected asset-generation pipeline is used.
- `ui/inventory/character_preview.gd`: isolated visual preview and honest fallback.
- `ui/inventory/inventory_view.gd` / `.tscn`: character/carried paper sheets and inspection strip,
  reusing shared MenuPanel/MenuButton/theme resources.
- `startup/startup_router.gd`: local opening/closing, input precedence and restoration.

All new GDScript UIDs are retained. Environment, character, camp, weapon and player
source files and project.godot are unchanged by this work. No dependencies added.

## Validation

```text
<godot> --headless --path . --script res://tests/inventory_ui_smoke.gd
<godot> --path . --script res://tests/inventory_ui_smoke.gd -- --capture-inventory
<godot> --headless --path . --script res://tests/menu_startup_smoke.gd
```

The inventory check covers sample/live separation, no camp-stock data in the
snapshot, item detail, one-square item footprints, four pockets on one row, fifth-item
rejection without replacing contents, absent-body fallback, isolated supplied-visual
rotation, actual ammunition, Tab/Escape/pause routing, local process restoration,
no stacking over camp panels, and conservation of ammunition/stock during inspection.
The supplied-visual check uses a synthetic mesh, not the rejected character.

Performed on Godot 4.7.2: inventory and existing menu/startup checks passed
headlessly; the inventory check also passed with GTX 1080 Compatibility rendering.
Rendered layout views were inspected at 1280 × 720 and 1920 × 1080. Item-card
rectangles are checked for overlap. Restricted-environment certificate-store and
shader-cache write warnings occurred; no gameplay, networking or approved-character
art acceptance is implied.

Before real inventory manipulation: approve total pack capacity, stacking and physical access,
introduce item/location IDs and authoritative transfer/equip rules, supply current
clothing records and an approved character visual, then connect requests to those
rules. No drag/drop, equip, consumption, persistence, network synchronization or
campaign casualty behavior is claimed by this design prototype.
