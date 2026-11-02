# Environment candidates — visual proof 01

Original procedural source assets, 2026-11-01. No downloaded/reference pixels, third-party meshes or generated-image outputs are included. Rights follow this private repository's project policy; no public redistribution license is added.

Source of truth:

- `source/bake_textures.py`: original periodic texture recipe, seeds 1946–1949, Python standard library.
- `../../scripts/environment/bake_visual_proof.gd`: original mesh/resource recipes, seed 1946, Godot 4.7.2 standard.
- `../../scripts/environment/*_v1.gdshader`: editable ground/stone material sources.

`textures/`, `materials/`, `meshes/`, `scenes/` contain baked game-ready outputs. Keep `.png.import` files (lossless, mipmaps on, no automatic 3D compression change), `.gd.uid` and shader UID files. Do not commit `.godot/` caches. Run recipes only when deliberately replacing these named candidates. Keep manual variants separate. Geometry is deterministic; Godot may rewrite scene/resource IDs when repacking, so output files are not promised byte-identical.

| Candidate | Dimensions / collision | Mesh cost |
|---|---|---|
| Spruce | 11 m height; 0.46 m trunk base diameter; cylinder collider | 13,056 bough triangles plus native 9-sided trunk; no foliage collision |
| Fern | ~1.6 m spread / ~0.5 m high; decorative | 324 triangles; no collision |
| Boulder | ~2.5 × 1.6 × 1.9 m; randomized silhouette | 168 triangles, one convex collider |
| Crate | ~1.06 × 0.82 × 0.84 m; no contents or ownership state | 300 triangles, box collider; body in existing `vaultable` group |
| Ground | 24 × 24 m; flat proof only | 1,152 triangles, matching static trimesh |

No LOD, billboard or batching is provided for these proof scenes. Do not scatter hundreds of them before review and optimization. Ferns and spruce leaflets are opaque two-sided geometry; no blended alpha overdraw. This trades more triangles for simpler transparency and needs comparison with alpha-scissor foliage later.

Press F5 for the shared weapon/control/animation training yard, which now includes these woodland props and moss/dirt ground. For isolated inspection, open `scenes/environment/environment_visual_proof.tscn` and press F6. That bounded candidate clearing is not the requested final `forest_biome_test.tscn`; use P if you walk off its floor. The existing civilian and rifle remain owned by their original asset pipelines.

See [the production plan and validation record](../../docs/ENVIRONMENT_ASSET_PIPELINE.md). Botanical shapes, texture finish and palette are awaiting owner review.

## Dense training woodland and terrain — v2

The owner requested a denser forest, low ground variation and an enterable trench. `scripts/environment/forest_layout.gd` is the editable height/exclusion recipe; `bake_training_forest.gd` extends the original resource baker to add three tree recipes, deadwood, stumps, grass, moss clumps, litter, a 100 m terrain mesh and timber-supported trench. All are original procedural sources; no image-generation or third-party art is claimed. See the pipeline for references.

Run `<godot> --path . --script res://scripts/environment/bake_training_forest.gd` with the **real renderer**, omitting `--headless`. The dummy renderer cannot retain MultiMesh instance buffers during serialization, so this tool rejects it before changing outputs. Optional arguments after `--`: `--seed=19461101 --tree-spacing=5 --undergrowth=6500`. Tree spacing is metres (larger means fewer trees); undergrowth is placement attempts, not guaranteed accepted instances. Rebuilding overwrites only the named generated resources/subscene; keep manual additions beside `GeneratedForest` in `training_environment.tscn`.

Default generated counts: 229 trees, 21 logs, 12 stumps, 9 rocks, 961 ferns, 1,661 grass tufts, 1,667 litter clusters and 576 moss clumps. Original hand-placed proof props are additional. Mesh and collision come from the same half-metre terrain grid; primitive collisions cover trees/deadwood. Small plants/litter/moss have no collision or collection behavior. The trunk and crown meshes are shared in 14 m spatial MultiMesh cells. No runtime scattering occurs. Foliage has no solid collision curtain; timber revetments follow the trench's earth collision and stay decorative. This is not an approved historical trench reconstruction or a dig/build mechanic.

## Birch skins — detailed candidate

Birches now use generated bark/leaf skins, curved smooth wood, tapered forks, drooping twigs and folded cutout leaves. Existing placed birches pick up the shared resource replacement on restart; positions/collision remain fixed. Run `<godot> --headless --path . --script res://scripts/environment/bake_birch.gd` for a species-only rebuild. Full forest baking calls the same recipe. See [source images, exact prompts and provenance](source/BIRCH_TEXTURE_PROMPTS.md). New generated images are preserved unchanged; import settings use 512 px bark / 256 px leaf with mipmaps. The heavier 86,710-triangle tree is a detail candidate requiring LOD before wider expansion; measured results and visual checks are in the pipeline's v3 section.

## Pine skins and deadwood — detailed candidate

Existing pines now use generated fissured lower bark, flaky warm upper bark and alpha-scissor needle sprays on curved branches, with dead lower limbs and solid splintered ends. Additional scene `pine_debris_generated.tscn` supplies two fallen pines, three hollow decayed/mossy logs, two broken snags and twelve loose branches. Large deadwood has mesh-matched collision and supports the existing vault system; loose branches are decorative.

Run `<godot> --headless --path . --script res://scripts/environment/bake_pines.gd` for species resources, and `bake_pine_debris.gd` for additive placement. Both preserve the original forest placements. The full MultiMesh forest bake still requires a real renderer. [Exact prompts, source/runtime paths and provenance](source/PINE_TEXTURE_PROMPTS.md) are retained. See the pipeline v4 section for render checks and measured costs; distance LOD remains pending.
