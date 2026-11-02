# Personal inventory interface

Status: integrated local carried inventory with physical ammunition actions. See
[Physical Ammunition](AMMUNITION_INVENTORY.md) for the rule model, controls, initial
kit, estimated magazine knowledge and serialization boundary. Worn equipment, a current
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
preview. This version owns an independent reset-on-run instance of the same training
kit. Its Back action emits a view-close signal for a containing owner; F8
stops the standalone scene in the editor. The main-menu Controls panel lists Tab.

The composition scales uniformly from 1600 × 900. The large right sheet contains
four pocket cells and a provisional 9 × 4 pack layout (36 shown spaces, preserving
the prior draft's slot count). Only the four-pocket capacity and one-square item
footprint are confirmed; total pack capacity remains unapproved.

The training adapter reads only the supplied player's physical weapon inventory.
It does not read camp stock. The spare magazine and 32-round stack now occupy real
pocket locations with unique IDs. The inserted magazine appears only on the rifle,
and ammunition actions use these same items in play. Empty pack spaces contain no
invented possessions. Raw magazine counts stay internal; inspected categories are
the only magazine quantities projected into UI labels and tooltips.

## Current character limitation

The owner rejected the procedural character blockout, and the current playable
player normally has no BodyVisual. This UI does not reload that rejected asset or
substitute the civilian/enemy sprite as the player. It displays a labelled neutral
ink mannequin and marks live clothing slots as not recorded until actual equipment
records exist. No sample outfit is asserted as the current player's equipment.

`character_preview.gd.bind_visual(visual)` accepts the supplied current Node3D body
when one exists. It duplicates that visual with scripts/signals/groups disabled
into an isolated SubViewport world, restores full mesh rendering in the copy and
supports left/right rotation. It does not rotate or change the world character.
This is a binding point for the character owner's approved replacement; it does
not prove that replacement's framing, garment fit, rig or animations. Skeleton and
wardrobe validation remains with that workstream under MODULAR_CHARACTER_BRIEF.md.

## Components and ownership

- `ui/inventory/inventory_snapshot.gd`: read-only training-to-UI adapter plus clearly
  separate standalone rule instance. Takes only an explicit player; no global
  player reference or new inventory authority.
- `ui/inventory/inventory_grid.gd`: reusable view grid with selectable item cards.
  Each entry takes one square regardless of legacy span metadata. Over-capacity
  snapshots are rejected before changing visible entries, so a fifth pocket item
  cannot disappear silently or displace an existing item. This view validation does
  is supplemented by the physical item's authoritative local location checks.
- `ui/inventory/inventory_item_card.gd` / `inventory_weapon_slot.gd`: ID-only drag
  payloads. The weapon-state owner validates movement, loading, merging and insertion.
- `ui/inventory/ammunition_art.gd`: separate original rifle, magazine and cartridge
  AtlasTextures. An inserted-magazine overlay follows the current weapon item.
- `ui/inventory/item_symbol.gd`: original code-drawn category sketches, not final or
  historically verified item art. No protected asset-generation pipeline is used.
- `ui/inventory/character_preview.gd`: isolated visual preview and honest fallback.
- `ui/inventory/inventory_view.gd` / `.tscn`: character/carried paper sheets and inspection strip,
  reusing shared MenuPanel/MenuButton/theme resources.
- `startup/startup_router.gd`: local opening/closing, input precedence and restoration.

All new GDScript UIDs are retained. The ammunition increment includes focused
weapon/input and camp transfer/service integration. Environment and character art,
project.godot, rendering and input mappings are unchanged by that increment.

## Validation

```text
<godot> --headless --path . --script res://tests/inventory_ui_smoke.gd
<godot> --path . --script res://tests/inventory_ui_smoke.gd -- --capture-inventory
<godot> --headless --path . --script res://tests/menu_startup_smoke.gd
```

The inventory check covers the initial physical kit, no camp-stock data, unknown
magazine counts, ID-preserving movement, splitting/loading/inspection, four pockets,
fifth-item rejection, dynamic magazine attachment art, real ground/F recovery, K
chambering and firing, Tab/Escape/pause transitions and conservation. The separate
ammunition rule check covers compatibility, mixed rounds and save validation.

Performed on Godot 4.7.2: inventory and existing menu/startup checks passed
headlessly; the inventory check also passed with GTX 1080 Compatibility rendering.
Rendered layout views were inspected at 1280 × 720 and 1920 × 1080. Item-card
rectangles are checked for overlap. Restricted-environment certificate-store and
shader-cache write warnings occurred; no gameplay, networking or approved-character
art acceptance is implied.

Before campaign integration: approve final pack capacity, supply clothing records
and an approved character visual, and connect the existing local item commands to
authenticated multiplayer and full campaign transactions. Local ammunition actions,
equipping, drag/drop, ground recovery and equipment snapshot serialization exist;
network synchronization and campaign casualty/save/rollback do not follow from them.

## Tarkov-style handling (2026-11-02)

The owner asked to follow Escape from Tarkov's inventory handling where it fits.
Planned chunks, each with a headless check and owner approval before starting:

1. Done: compact 64-unit flat cells (short name top-right, count bottom-right),
   item-picture drag preview, green/red drop preview from side-effect-free rule
   checks (`can_move_item`, `can_merge_stacks`, `can_load_round`), left-click
   selects, right-click opens a small cursor menu. Only splitting keeps the paper
   dialog because it needs an amount.
2. Done: multi-square items and rotation. Rules own footprints (`FOOTPRINTS`,
   `footprint`, `area`), overlap checks and the saved `rotated` flag; the grid draws
   each item across its cells and the drop tint covers the whole footprint, anchored
   at the grabbed cell. R while dragging turns the item about the cursor. Approved
   placeholder sizes: rifle 5 × 2, magazine 1 × 1, cartridge stack 1 × 1; pockets
   stay 1 × 1. The owner then asked for a larger pack: now 9 × 6 (54 cells), which
   holds a turned rifle. The grid reads its size from the rules.
3. Done: ctrl-click pocket ↔ pack, alt-click insert magazine, shift-drag split
   (rules: `can_split_stack`, `split_stack` with a destination), Delete drops the
   selected item to the ground.

Requested next (2026-11-02): the pack should be an item itself, as Tarkov's
backpacks are. Not designed yet; see DECISIONS.md.
4. Loading progress on the magazine cell; double-click inspect panel.
5. Rifle slot drag both ways (stow in pack, drag back to equip).

Left out: secure container, insurance, traders/prices, found-in-raid, private stash,
remote camp access, weight, containers within containers. A nearby-loot panel
would change the "only what is on the person" rule and needs owner approval.
