# Physical ammunition and weapon inventory

Status: integrated local training implementation, requested by the owner. This
extends the existing Godot weapon-state owner and paper inventory; it is not a
separate demo. Campaign saves, authenticated networking and final hand animations
are not implemented by this increment.

## Starting kit and controls

The existing SVT-inspired test rifle retains its configurable ten-round capacity.
The [Australian War Memorial record](https://www.awm.gov.au/collection/C246039)
documents the original rifle's ten-round detachable magazine. The UI calibre
identifier `7.62x54` follows the cartridge dimensions listed by the
[Moscow Arms Museum](https://www.moscowarmsmuseum.ru/collections/rifles/svt-40).
The game rifle and new generated icons remain approximations, not verified weapon
models or a claim about a particular Latvian resistance loadout.

- Magazine A: ten rounds, inserted into the rifle; chamber initially empty.
- Magazine B: ten rounds, pocket slot 0.
- One loose stack: 32 rounds, pocket slot 1.
- Exactly two magazines, 52 rounds total. Chambering moves one of those rounds;
  it never creates a 53rd. The 30-round test fixture starts at exactly 92.

Press **K** to chamber, **I** to inspect the inserted magazine, **R** to swap with
a carried magazine, and hold **T** to load the spare one cartridge at a time.
K avoids C, which the movement work uses for stance control. Existing J clearing,
B cleaning, G dirt testing, aiming, shooting, and action timelines remain.

Press **Tab** for equipment. Left-click selects an item and describes it in the lower
strip. Right-click opens a small action menu at the cursor:

- Magazine: inspect; insert/swap; fill; unload; drop. An inserted magazine offers
  inspection/removal and cannot also occupy a pocket.
- Loose stack: choose a split amount, split, merge with a matching partial stack,
  or drop. Overflow stays in the donor; empty stacks disappear.
- Rifle: chamber, unload chamber, inspect/remove inserted magazine, drop with its
  contents, or equip a carried rifle.
- During a timed action, the action menu offers cancellation. Before the effect
  marker nothing transfers; after it the completed transfer remains.

Drag an item to a free pocket/pack square to move it. While dragging, the square
under the cursor turns green if the drop would be accepted and red if not. Drop cartridges on a carried
magazine to fill it, matching cartridge stacks onto one another to merge, and a
magazine on the rifle slot to insert/swap. Occupied incompatible destinations reject.
Each item uses one square. Pockets hold four items; pack capacity remains the
existing configurable training draft of 36, not final balance.

Dropped items have world collision and the existing **F** interaction. Recovery
keeps the same IDs and nested weapon contents. Local carriers can change custody
of a dropped rifle/magazine/stack without copying its rounds. This local rule test
does not prove networked co-op, mission-body recovery, or host-crash rollback.
Ground pickup geometry is a small blockout fixture, not final world item art.

## Magazine knowledge

New magazines show **Unknown · inspect**, including magazines that happen to be full
or empty. Inspection is timed. Only these categories are projected into the HUD,
camp ammo panel, inventory cards, tooltips and inspection dialog:

| Fill | Inspection description |
| --- | --- |
| 90–100% | Almost full |
| 50–89% | More than half |
| 30–49% | Less than half |
| 1–29% | Almost empty |
| 0% | Empty |

Thresholds are configurable on the inventory rule owner. The attachment's 26/30
example conflicts with its table: this implementation follows the table, so 26/30
is **More than half**. No percentage, exact magazine count or exact fill bar is
displayed. Exact counts remain internal for conservation. Loose stacks show their
exact quantity in the lower-right corner of one item card.

Firing/cycling, loading and unloading invalidate magazine knowledge. Moving a
magazine within the same carrier preserves it; transfer to another carrier resets
it. Equipment snapshots retain earned inspection knowledge; saved category text is
recomputed from validated contents rather than trusted. Category stamps use subdued
colours and text, never a quantitative bar.

## Rule ownership and invariants

`scripts/inventory/ammunition_inventory.gd` defines typed ammunition/magazine
definitions, locations, stacks, individual rounds, magazines and weapons. Definitions
are separate from runtime instances. Immutable content IDs/calibre/capacity and new
action durations are configured by `weapon_definition.gd`.

- A magazine's `rounds` array is its sole ammunition authority. Its last element
  is the next round fed/unloaded, allowing mixed compatible variants in order.
- A weapon holds an inserted-magazine ID, a separate nullable chamber round,
  condition and jam state. A chambered round can fire without a magazine. Insertion
  alone never chambers; successful firing consumes the chamber and cycles if able.
- Every item has one ID and one location: pocket, pack, magazine well, equipped
  slot, or ground position. Inserted-magazine ownership is reciprocal and validated.
- Stacks contain one type, hold 1–32 rounds, and never merge across types. Split,
  merge, load, unload, drop, recover and reload conserve physical ammunition.
- Full destinations reject before mutation. Reload swaps the outgoing magazine
  into the incoming magazine's old slot, preserving identity and partial contents.
- Jam failures, busy actions and cooldown failures do not consume cartridges.
  Condition and jams stay on the physical rifle when custody changes.
- The existing camp ledger remains communal stock. Withdrawals preflight stack
  capacity; deposits consume actual compatible stacks. A service job binds a rifle
  ID and cancels/refunds if that rifle stops being the carried service target.

`prototype_weapon_state.gd` retains action scheduling and commits once at existing
timeline markers. Rendering callbacks never manufacture rounds. Its old `magazines`
and `loose_rounds` interfaces are derived compatibility views; they are not duplicate
ammo storage. New code addresses item IDs. While inventory is open the local world
subtree is suspended and the view's fixed-tick adapter advances this same owner.
On close, the existing weapon controller resumes the clock. SceneTree is not paused.

`inventory_snapshot.gd` projects sanitized labels and physical pocket/pack locations.
It contains no camp stores and never exposes raw magazine contents as UI counts.
The current character preview and clothing fallback are unchanged.

## Serialization boundary

`encode()`/`restore()` preserve stable IDs, round order/types, condition, chamber,
inserted ownership, and world/carry locations. They use a versioned JSON-compatible
schema and the currently registered immutable definitions. Invalid data is parsed
and checked in a candidate inventory; failure leaves the current state untouched.
Duplicate IDs/slots, invalid counts, incompatible rounds, broken magazine links,
foreign definitions and invalid locations reject rather than partially loading.

`save_equipment(path)`/`load_equipment(path)` exercise actual file serialization;
the focused check uses an ignored `.godot/` test file. No autosave, quickload menu,
campaign save format or inventory-only campaign rollback is installed. The future
campaign save owner must include these records in its complete transactional
baseline, including communal camp work. A local equipment snapshot must not be used
to award campaign supplies independently.

## Validation

```text
<godot> --headless --path . --script res://tests/ammunition_inventory_smoke.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/inventory_ui_smoke.gd
<godot> --path . --script res://tests/inventory_ui_smoke.gd -- --capture-inventory
```

The rules check covers both 10/30 capacities, exact starting totals, identity and
location, threshold boundaries, stack arithmetic/overflow, type compatibility,
mixed rounds, chamber-only firing, jams, interrupted/repeated reloads, file/JSON
round-trips, malformed save rejection, two local carriers, full inventories,
communal withdrawal failure, and service cancellation/refund.

The scene/UI check exercises actual item actions and the inventory clock, drag
handlers, split/fill/inspection, one-square/four-pocket limits, inserted magazine
art removal, world drops and the real F ray, K input and firing, ammunition
conservation, and Tab/Escape/pause transitions. Existing weapon, reload, traversal,
ADS, muzzle, menu and camp checks remain applicable. Rendered views establish layout
only; owner playtesting, detailed mechanism animations and networking remain open.

## UI artwork provenance

`ui/assets/ammunition_icons_v1.png` is original built-in imagegen output, retained
unchanged with alpha. The inspected output did not use exact quadrants; the UI uses
explicit AtlasTexture regions in `ammunition_art.gd`. The rifle base and magazine
are separate regions and the attachment is drawn only when its physical ID is
inserted. No environment, character, existing gun artwork or asset baker is edited.

Final generation prompt:

> Game UI inventory icon atlas for a gritty illustrated postwar forest survival game,
> warm ink-and-painted finish, physically believable aged steel and worn dark wood,
> original artwork not copied from any game. Transparent 1536x1024 canvas divided
> into four exact equal quadrants (768x512 each), no dividing lines. Upper-left
> quadrant: one left-to-right side-profile SVT-40-inspired 1940s wooden-stock
> semiautomatic rifle, stock LEFT muzzle RIGHT, entire rifle inside that quadrant
> with margins; NO magazine inserted, clearly empty magazine attachment area under
> receiver, NO hands, sling, accessories or text. Upper-right quadrant: one separate
> short ten-round steel detachable rifle magazine, front-three-quarter view, worn
> blued steel fine scuffs, correctly short box form, centered with generous margins.
> Lower-left quadrant: a small bundle of five physical brass rifle cartridges angled
> together, copper pointed tips, readable silhouette, not separate 32 bullets.
> Lower-right quadrant: completely transparent and empty. All three icons distinct,
> isolated, consistent lighting from upper left, no backdrop, no surface, no cast
> shadows outside icons, no letters, no numbers, no watermark. This is a production
> sprite atlas, not a screenshot or a mockup.
