# Modular character production brief

**Current owner priority: character art is frozen.** Preserve MPFB sources/rig/clips/clothes; do not create outfits or polish appearance. Sprites are the default; retain MPFB for comparison. See [CHARACTER_FREEZE_AND_COMBAT_SLICE.md](CHARACTER_FREEZE_AND_COMBAT_SLICE.md) for validated defects and the pending combat-first proposal. This supersedes further production steps below.

Status: owner rejected the procedural humanoids on visual quality and scalability. Rigged polygonal characters remain the goal. The existing meshes are technical fixtures, not an art foundation to multiply into a roster. Painted sprites are restored for normal training play until a replacement earns the change.

## Selected base

The owner has now chosen an MPFB human. See [MPFB_CHARACTER_BASE.md](MPFB_CHARACTER_BASE.md) for its editable source, prepared rigged copy and pending clothing/export work. MPFB is now installed and this base has been inspected; the candidate/tool-availability discussion below describes the earlier research stage.

## Why the first attempt failed

The original builder creates angular body segments with vertex colors. It has no convincing anatomical forms, UV-painted surfaces, garment construction or distinct clothing pieces. Its three skinned groups divide visibility, not wardrobe slots. Increasing subdivisions or recoloring those groups does not solve those problems. Passing skeleton tests cannot establish that a character looks good.

## First replacement: one civilian, two outfits

Build one believable old civilian matching the character and gritty painted finish of the approved front sprite. Preserve adult proportions, an identifiable face, hands, believable shoulder/elbow/knee forms and a readable silhouette from front, profile and rear. Keep geometry economical, but do not use an arbitrary low triangle cap that sacrifices those forms.

Create two outfits on that same body: a work shirt with trousers and boots; then a separate jacket and cap over compatible clothing. These are fictional art briefs, not validated Latvian 1946 wardrobe references. Research period silhouettes, closures, materials and footwear before accepting them as historical assets. Do not produce an enemy roster before this civilian and clothing swap work.

## Separate body, clothing and equipment

| Part | Representation | Fit and visibility responsibility |
| --- | --- | --- |
| Body/head | Shared skinned base with identity variations | Keep face and hands detailed enough for close conversation; start with one body size |
| Shirt/trousers | Separate skinned garments | Garments deform on the same skeleton; hide covered body regions |
| Jacket/coat | Separate outer garment | Defines which shirt regions it covers and which underlying items can remain visible |
| Boots/gloves | Separate pieces fitted to the body | Hide covered feet/hands as needed; test ankles and wrists in motion |
| Cap/hair | Separate meshes | Define hair coverage and skull fit; prevent protruding hair |
| Belt/pouches/backpack | Separate equipment | Attach rigid parts to named sockets; skin straps or flexible parts where needed |

Use a shared exported deformation skeleton, bind pose, scale and bone names. Each clothing mesh must retain its skin binding to that rig; merely parenting a shirt to the chest bone will not bend its sleeves correctly. Do not blindly bind imported clothing to the current experimental 32-bone rig. Establish the production rig and a tested animation bone map first.

Clothing definitions should identify the asset, slot, compatible body/garments, covered body regions and material variants. Outfit presets combine these IDs. Appearance is separate from communal ownership, carried inventory and damage rules. There is no inventory/equipment implementation implied by this art brief. Begin with a fixed body size and explicitly tested combinations; arbitrary body morphs require garment fitting and are deferred.

Support cloth color, dirt and wear variants after the garments have good shapes and UVs. Color variants cannot replace distinct silhouettes. Retain editable source meshes, UV layouts, texture sources, bind data and provenance alongside exported GLBs. Do not merge the outfit into one immutable mesh during export. Any later runtime mesh combining is an optimization that must preserve equip changes.

## Production route to evaluate

Use Blender to edit and inspect a properly authored human base, create/fix separate clothing, paint or project textures onto a UV layout, weight garments and export GLB. MPFB is a promising free starting point for body proportions and its clothing/rig tools; it is a candidate, not an installed or validated dependency for this project. It will not automatically create the game's finished art or researched period clothing.

Official references checked on 2026-11-01:

- [MPFB overview](https://static.makehumancommunity.org/mpfb.html): human generation within Blender.
- [Asset tools](https://static.makehumancommunity.org/mpfb/docs/assets/asset_creation_intro.html): clothing, materials and weight tools.
- [Core asset license](https://static.makehumancommunity.org/about/license.html): core assets are CC0; tool source licenses differ. Check every additional asset's license individually.
- [Download guidance](https://static.makehumancommunity.org/mpfb/downloads.html): recommends Blender's extension platform and notes that additional asset packs are separate downloads.

No 3D modeling connection was found in the available plugin search for Blender. The built-in image generator produces raster images, not rigged GLB meshes. It can help with design references and texture sources; those images still need fitting to UVs and inspection on the model. No software, external asset pack or paid generation service was installed or purchased for this correction.

An image-to-3D service could provide a draft sculpt, but do not assume it returns clean animation topology, separate garments, a shared rig or usable skin weights. Inspect and repair these before integrating its output. Check service terms and source rights before using it.

## Visual acceptance before replacing sprites

1. Show the sprite and replacement in the same Godot scene, lighting, camera and approximate screen size. Capture front, side, back and close conversation views. The model must retain its identity and look at least as convincing as the sprite.
2. Show the same body wearing both outfits. Swap garments without changing the skeleton, replaying gameplay initialization or duplicating the whole character asset. Hide covered body regions and restore them when removing clothing.
3. Inspect shoulder, elbow, wrist, crotch, knee, ankle and jacket seams through idle, walking, crouching, aiming, reloading, interaction and death. Check garment clipping and boot/ground contact. Automated rig checks support this review; they do not replace it.
4. Inspect player first-person arms, looking down, leaning and planning-camera visibility separately. A good third-person model does not automatically make a good first-person arm rig.
5. Measure representative dressed characters on the GTX 1080 in the actual training environment. Record triangles, materials/draw calls, texture memory and frame timing before choosing LOD or crowd budgets.
6. Record owner visual feedback. Only then replace normal-play sprites and expand civilian/opponent outfit sets. Preserve accepted source art and prior versions for comparison.

## Current implementation boundary

Normal camp residents, patient and opponents use the preserved painted sprites. The rejected polygon player body is disabled by default. The original-yard display at x -6, z 11 remains labeled REJECTED ART / rig test only. Explicit `use_polygon_body`, `use_polygon_characters` and resident/enemy `use_polygon` switches preserve rig experiments. These are debug presentation switches, not the future outfit system. No improved production model or modular garment runtime has been delivered yet.
