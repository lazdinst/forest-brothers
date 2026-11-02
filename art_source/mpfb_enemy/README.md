# Frozen MPFB character source

Character art is frozen by owner request. Preserve these files; do not create outfits, polish meshes/textures or rebuild character art without a new request. Combat, movement and AI take priority. Normal play uses sprites; the combat table can reset the first enemy with the MPFB comparison.

- `owner_original.blend`: exact owner-supplied source. Its textures were external; use the packed versions below for a self-contained working source.
- `human_base_rigged_v1.blend`: packed skin images and MPFB game-engine rig.
- `enemy_dressed_v1.blend`: packed editable body, separate fitted clothes/eyes/hair and rig. The four animation clips are in the GLB and their original generation recipe below; this editable source was saved before the clips were authored.
- `build_enemy_snapshot.py`: exact generation recipe retained as evidence, including the initial animation definitions. It contains the original machine paths. This is an archived snapshot, not an automatic build hook; do not run it during normal import or validation.
- `resources/`: original selected garment/bodypart meshes, fit definitions, textures and upstream pack metadata. Metadata lists the included assets as CC0. MPFB tool code is not bundled; its separate GPL license is not the asset license.
- `preservation-manifest.json`: byte counts and hashes for the archive and current GLB. Source textures are embedded in the packed blend files, including the skin.

The current GLB lives in `assets/characters/mpfb_enemy/enemy_v1.glb`. The source directory is excluded from Godot imports with `.gdignore`, so Blender sources are not imported as duplicate game characters. No source mesh, clothing or animation was changed as part of this freeze/preservation step.

See `docs/CHARACTER_FREEZE_AND_COMBAT_SLICE.md` for observed visual defects, representation independence, current gameplay and the pending combat-slice proposal. Core asset license: https://static.makehumancommunity.org/about/license.html . Selected packs: https://static.makehumancommunity.org/assets/assetpacks.html .
