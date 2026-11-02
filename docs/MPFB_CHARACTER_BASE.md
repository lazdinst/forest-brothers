# Selected MPFB human base

The owner selected `forest_brothers_human_base.blend` in the shared ForestBrothers-Art characters folder as the human base. This replaces the rejected procedural model as the starting point for future character production; it does not approve a finished wardrobe or animation set.

Original source:
`C:\Users\Nauda\Documents\Codex\ForestBrothers-Art\characters\forest_brothers_human_base.blend`

Prepared editable working copy:
`C:\Users\Nauda\Documents\Codex\ForestBrothers-Art\characters\working\forest_brothers_human_base_rigged_v1.blend`

## Intake and preparation

- Opened with installed Blender 5.2.3 LTS and MPFB 2.0.18.
- Original contained one human mesh, skin material, six shape keys, and no armature or clothing. Camera/light are scene utilities.
- Original remains byte-for-byte unchanged; SHA-256: `589ad3e4af9f3498b5c1835802466390377392998ccb4b81d8ed5e5ebd2e01eb`.
- Separate working copy uses MPFB's built-in `game_engine` rig with 53 bones and its supplied skin weights. This is distinct from the rejected experimental 32-bone rig. Existing clips need tested retargeting; do not rename bones blindly or assume animation compatibility.
- Packed both referenced 2048-pixel skin images into the working copy. There are no external blend-library dependencies.
- Reopened the saved copy, confirmed packed images and rig bindings, and rotated an arm bone: actual mesh vertices moved approximately 0.268 m. This is a deformation sanity check, not an animation or visual acceptance test.
- 19,158 source vertices / 18,486 source polygons include MPFB helper geometry. Do not quote these as exported game triangle counts. Helpers must be removed from a separate export copy.

## Provenance

Body: owner-created MPFB human using the MakeHuman core base. Core assets are CC0 per https://static.makehumancommunity.org/about/license.html . The tool source license differs from the asset license.

The installed `skins02.json` pack metadata lists both referenced Jartur69 skin assets as CC0, with original source nodes 1507 and 1508 on makehumancommunity.org. Preserve pack metadata and relevant skin files when moving source into the repository. The skin names are upstream asset labels, not a researched claim about a fictional character's identity or appearance. No additional paid or downloaded assets were added during intake.

## Remaining production work

Add separate eyes and suitable hair, then separate shirt/trousers/boots and jacket/cap with compatible weights and coverage. Keep source shape controls editable. Do not join wardrobe objects into the body. Preserve the selected body proportions and skin unless changing them is necessary and documented.

Create a game-export copy, remove helpers, make game-compatible materials and UV textures, retain separate garment objects and export a skinned GLB. Test the production rig's animation mapping, clothing fit, first-person and planning views. Show the clothed candidate beside the painted sprite before changing normal-play defaults. This intake has not exported to Godot or replaced active actors. See MODULAR_CHARACTER_BRIEF.md for acceptance criteria.

Preparation scripts and `intake-report.json` are in the working-copy folder, enabling the next agent to inspect and continue without requiring the owner to rig or export manually.

## Freeze and preservation update

The dressed GLB, four initial clips and separate clothing/bodyparts were integrated as a comparison enemy, then character art was frozen by owner request. Frozen source copies, raw selected resources, the animation recipe and hashes now live in art_source/mpfb_enemy. Both training enemies default to sprites; MPFB remains available from the combat table. See CHARACTER_FREEZE_AND_COMBAT_SLICE.md for completed visual validation and pending gameplay scope.
