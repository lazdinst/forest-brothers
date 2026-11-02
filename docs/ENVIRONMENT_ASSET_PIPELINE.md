# Environment asset pipeline

Status: initial visual proof plus owner-requested dense training woodland, real ground relief and enterable trench, 2026-11-01. The owner explicitly requested this expansion after inspecting the bland initial training yard. The playable environment remains candidate art; final visual approval and the complete original biome milestone are pending.

## Implementation plan and ownership boundary

**Current integration:** F5 loads `training_environment.tscn` within the existing testbed. Its generated subtree supplies the actual terrain/collision and forest. The original box floor and perimeter walls are disabled; movement fixtures, targets, partitions and annex are preserved. Manual environment props remain beside the generated subtree. Player, weapon, character and camp-system source work remains separate. The isolated F6 proof is retained as a comparison scene. The numbered plan below records the original phased approach; the v2 section records the owner's subsequent requested expansion.

1. Inspect the current project, renderer, references and concurrent work. Completed: Godot 4.7.2 standard / Compatibility; reusable player includes weapon; existing training yard stays the main scene. Another chat is implementing weapon reloads. Do not edit its player/weapon/character/training resources or project settings.
2. Build five candidates: spruce, moss/dirt ground, fern, boulder and wooden crate. Assemble a 24 m visual clearing using the existing player scene unchanged. Save editable recipes and reusable Godot resources. Inspect real GPU frames, collision and resource costs.
3. Present proof and known shortcomings for owner review. Iterate before library expansion.
4. After review, add pine/birch, paths, tent/camp, logs/stumps and terrain variation to `forest_biome_test.tscn` (~100 × 100 m). Keep the small proof as a regression reference.
5. Add seeded editor-time placement, density controls, terrain sampling, exclusion corridors, minimum spacing, artist overrides and chunked MultiMesh undergrowth. Bake to scene, never regenerate during ordinary play.
6. Add overcast/day presets, inexpensive depth fog, wind and lantern/fire; demonstrate limited winter material changes. Measure the full scene on the GTX 1080 before accepting budgets. Seasonal gameplay remains design work.

Shared `DECISIONS.md` / `ROADMAP.md` updates must be made against their latest contents after checking concurrent edits. This document records the reversible implementation assumptions meanwhile.

## References and tool selection

Contemporary Latvian landscape references inform shape, planting and palette, not historical claims about 1946:

- [Latvian Nature Fund forest guide](https://old.ldf.lv/upload_file/29887/Mezu_celvedis_web_ENG.pdf): woodland photographs and habitat variety. Reference viewing only; do not copy photographs into textures.
- [Latvia Travel: forest bathing](https://www.latvia.travel/en/forest-bathing-what-it): pine groves, young stands and older spruce forest near Riga.
- [Abava valley](https://www.latvia.travel/en/sight/ancient-valley-abava-nature-park): mixed spruce/broadleaf, pine/birch and meadow landscape reference.
- [EnterGauja woodland photograph](https://www.entergauja.com/en/news-events/events/2019/day-tour-escape-at-the-nature-of-gauja-national-park) and [Rauda Forest trail photographs](https://www.visittukums.lv/en/What-to-see/Unusual-places/Will-O-the-Wisp-of-the-Werewolves-Trail): visual references for moss, trunk spacing and forest-floor clutter. Reference only; images are not copied into assets. The forest guide's web PDF screenshot retrieval failed; its text was accessible.
- [Godot MultiMesh guidance](https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html): useful for repeated meshes; one large batch cannot cull individual plants. Split later forest placement into spatial cells.

Available methods: Godot native mesh/resource generation and Python standard library texture authoring require no third-party runtime dependency. Image generation is available for later painted candidates, but is not used for this proof: source recipes give reproducible scale, UVs and seamless texture edges. A generated photograph would still need delighting, seam/alpha inspection and import preparation. No external mesh-generation tool has been verified. No downloaded art, paid asset, or new dependency is introduced.

## Asset standard — candidate values, validate before production

| Topic | Convention |
|---|---|
| Naming | `assets/environment/{materials,textures,meshes,scenes}`; lowercase snake_case, species/material and version in names. Sources in `assets/environment/source/`; placement tools in `scripts/environment/`. |
| Provenance | Each batch has a source recipe, seed, date, method, references and rights note. This proof is original procedural geometry/textures; references are links only. Repository privacy is unchanged. |
| Units / pivot | 1 Godot unit = 1 m. +Y up; asset origin at ground contact; props face -Z when a front exists. Avoid scaled physics shapes. |
| Textures | Proof uses 128² seamless opaque RGB PNGs, nearest-with-mipmaps sampling, repeat enabled. Ground repeats over 2 m with a second scale and low-frequency blend. Enlarge only after first-person inspection. Preserve source recipes. |
| Materials | Roughness 1, metallic 0; neutral albedo without baked directional light. Restrained soil/olive/grey palette. No glossy leaves. No baked labels or gameplay text. |
| Transparency | Initial fern/spruce use opaque, double-sided leaf triangles rather than blended cards. Later cards must use alpha scissor, transparent-edge color dilation, mipmaps, and sky/ground/flash checks. Never use foliage as a solid collision sheet. |
| Collisions | World layer 1; trunks use primitive shapes, boulders one convex hull, crate box. Ground uses matching static triangle mesh. Decorative fern/needles have no collision; no gameplay/collection behavior in art. |
| Scene structure | `Node3D` asset root, `Visual` mesh child; optional `StaticBody3D` / `CollisionShape3D` child. Reuse external mesh/material resources; collision never depends on billboard rotation. |
| LOD / billboard | Proof is small and has no LOD. Do not infer 100 m suitability. Future tree LOD must preserve trunk collision and silhouette; billboard/impostor candidates need first-person and elevated camera review. |
| Budgets | Proposed full biome: <1 M visible triangles, <500 draw calls, <256 MiB environment textures, <8 ms frame median at 1280×720 on GTX 1080, 95th percentile <16.7 ms. These are targets, not measurements or approved final limits. |

## Library specification and expansion backlog

All items below are specifications, not claims of completed assets. Reuse shared materials; stable content filenames identify definitions, not ownership or collectible state.

| Category | Coverage / method | Initial proof / later acceptance |
|---|---|---|
| Ground | dirt, sand, mud, moss, needles, leaves, gravel, trail, wet, snow, mixed snow/soil; shared world-coordinate blend masks, macro variation | Moss/dirt now; validate continuous blends and tile repetition. Remaining layers after review. |
| Trees | Scots pine, Norway spruce, silver birch, saplings, dead/broken/fallen trees, stumps; reusable branch/trunk meshes + material variants | One spruce candidate now. Later vary height/girth/crown using a small vetted mesh set. |
| Undergrowth | moss clumps, ferns, grass, heather, bilberry, lingonberry, shrubs, mushrooms, lichens, branches, twigs, cones, litter | One fern candidate now, opaque geometry. Later batch decorations; collectible wrappers remain separate. Botanical fidelity needs review. |
| Obstacles | stones, rocks, boulders, mossy boulders, roots, logs, decayed stumps, uneven ground | One boulder now. Later log/trunk primitives must pass movement, lean, vault and muzzle-ray checks. |
| Camp | cut logs, firewood, planks/posts, crates/barrels, canvas tents, rope, sandbags, shovels/axes/saws, buckets, cookware, sacks, shelves, bunker entrance pieces | One crate now. Props need scale and historical review; construction functionality remains separate from asset scenes. |
| Atmosphere | canopy daylight, overcast, dawn/dusk, moonlight, lantern/candle/fire/stove, fog/smoke/rain/snow/wind | One shadowed sun + depth fog in proof. Later budget local lights/particles; no volumetric-fog assumption in Compatibility. |

## Repeatable production and acceptance

Run the texture recipe, import textures, then run the Godot resource baker. Exact commands and proof validation are recorded below when available. The baker writes only its named environment output files, so artist edits belong in separate variant scenes. Never hand-edit baked resources and expect regeneration to preserve them. Ordinary scene loads do not run the baker.

Check each new asset at eye height (1.6 m), crouched, close and far; inspect against sky and ground, side/back light, muzzle flash and elevated planning view. Check seams at texture borders and across multiple repeats, scale/pivot, wind roots, transparency halos and imported mips. Review silhouette first, then surface character. A technical pass does not approve a visual asset.

For the full forest, record seed/density/cell size and exclusion shapes alongside baked placement. Keep manual overrides under a separate scene branch so regeneration affects only generated content. Query terrain height/normal and reject steep or intersecting large-object placements. Clear paths must include capsule clearance, not just tree centers.

Season plan: summer is the initial target. Later autumn changes ground cover/deciduous foliage; winter swaps ground and adds upward-facing accumulation masks; spring introduces patchy snow/wet soil. No dynamic accumulation simulation is planned. Visibility, footstep/movement effects and survival balance are proposals requiring separate gameplay decisions.

## Rebuild and play

Replace `<godot>` with the installed 4.7.2 executable. Run from the repository. Rebuilding is optional: the game-ready resources are included.

```text
python assets/environment/source/bake_textures.py
<godot> --headless --path . --import
<godot> --headless --path . --script res://scripts/environment/bake_visual_proof.gd
<godot> --headless --fixed-fps 60 --path . --script res://tests/environment_proof_check.gd
<godot> --path . res://scenes/environment/environment_visual_proof.tscn
```

On a first-ever texture import with no `.png.import` presets, rerun the Python recipe and import once more to enable mipmaps. Existing tracked presets already contain the settings. No project-wide texture filter or main-scene setting is changed. In the editor open the proof scene and use **F6**; **F5** still launches the training yard. Existing controls apply; vault the low crate with V. Ground ends 12 m from its center; P resets an off-edge fall. The proof does not represent a playable mission boundary.

For actual-renderer captures and an uncapped stationary frame sample:

```text
<godot> --path . --disable-vsync --max-fps 0 --script res://tests/environment_proof_check.gd -- --capture-dir=<absolute writable directory>
```

The runner saves five PNGs and `performance.json`, then exits nonzero on failed checks. Use a local output directory outside tracked art. Do not use `--fixed-fps`, movie capture or a short frame-count quit limit for timing: they invalidate or truncate real-time sampling.

## Validation record — 2026-11-01

- Resource baker passed; four 128² textures and five reusable asset scenes. The proof is a 24 × 24 m clearing with six repeated spruce, five ferns, one boulder, one crate, plus existing player/rifle and civilian reference.
- Focused integration passed headless at fixed 60 Hz and on the actual renderer: ground landing, sprinting, crouch, lean, ADS, vault and landing over crate; trunk/boulder world-layer rays block and decorative fern/foliage rays pass. No multiplayer validation is claimed.
- Five actual GPU frames inspected at eye level and close to spruce, fern/ground, crate and boulder. Fixed reversed ground/rock winding, changed broad spruce triangles into narrow needle sprays, softened moss edges on stone, enabled texture mipmaps and reduced yellow lighting. Source artwork from other pipelines was untouched.
- Current run: Godot 4.7.2 official; OpenGL 3.3 Compatibility; NVIDIA GTX 1080, driver 582.28; 1280 × 720; one shadowed directional light; depth fog; no alpha foliage, particles or added local lights. Existing weapon can create a brief muzzle light when firing, but no firing occurred during the stationary sample.
- 240 frame-interval samples after 60 settling physics frames: **median 0.762 ms; 95th percentile 1.866 ms**. Raw counters are preserved in [environment_proof_measurements.json](environment_proof_measurements.json). This is a brief uncapped process-frame interval sample, not GPU-timestamp profiling, a traversal benchmark or a stable-FPS guarantee. Concurrent desktop activity was not controlled.
- Maximum engine counters during the sample: **82 draw calls; 315,450 rendered primitives including passes**. These are renderer counters, not unique asset triangle counts. Whole-process texture memory **77,293,219 bytes (~73.7 MiB)** and video memory **102,188,643 bytes (~97.5 MiB)** include the existing weapon and civilian art. Four RGB environment textures plus mipmaps contain about **256 KiB** uncompressed before renderer overhead; profiler counters are process-wide, not that estimate.
- Logs also report unavailable system root-certificate access, blocked editor-settings save and GL shader-cache writes in this restricted run. No scene/script/shader compilation errors remain. These environment warnings are not silently counted as a clean engine log.
- After the concurrent reload change landed as `d75f67d`, the proof integration was rechecked against that current player/weapon. Only new environment files were edited until its shared-document changes were committed; later roadmap/decision entries append to the latest versions.
- Existing `training_smoke.gd` also passed after the final material change, covering jump, tunnel/stand clearance, lean collision, vault/mantle rejection, aimed hits and walking frames. This is a focused regression, not a claim that all project checks were rerun.
- Integrated training-yard follow-up: five spruce and five ferns, boulder and vaultable crate added in clear areas of the existing yard; existing floor collider retained with a material override. Six checks passed: `prototype_smoke`, `training_smoke`, `ads_smoke`, `muzzle_smoke`, `reload_animation_smoke`, `training_environment_check`. The last also passed on the GTX 1080 renderer, and its combined-yard frame was visually inspected. Existing certificate/cache warnings persist. Earlier measurements in this document describe the isolated proof, not the combined yard; the combined scene has not been benchmarked.

**Visual status: candidate, not approved.** Spruce silhouette is clearer after iteration but still regular, bark/stone surfaces show procedural character, fern detail aliases at distance, the flat floor has visible proof edges, and ground needs richer organic macro variation. No tent, full biome, winter variant, wind, fire, MultiMesh placement or density tool is implemented yet. Next review should settle whether to refine these mesh candidates or introduce reference-led painted texture/alpha-scissor foliage before expansion. Elevated planning-camera review, prolonged motion inspection, shadow/LOD/overdraw A/B profiling and target acceptance remain pending. Do not mark the forest milestone complete from proof measurements.

## Dense woodland, ground relief and trench — v2

This section supersedes the initial proof's placement/terrain status above. Owner requests: make the current testbed a detailed Latvian forest, vary the mostly flat ground, and add a trench the player can enter. This authorizes the detail iteration, not final art approval or a change to campaign construction rules.

### Terrain and layout

`forest_layout.gd` defines a 100 × 100 m footprint (x −55…45, z −54…46), excluding the existing annex footprint on the east. It combines low broad undulations, small hummocks, a sandy rise and a shallow damp hollow. There are no mountain landforms. Course landings, central interactions, civilian/rig demonstrations, the firing lanes and annex entry retain level clearances. Terrain is baked on a half-metre grid into a mesh and matching static collision; this is real walking height, not vertex-only displacement or shading. The original yard's box floor and perimeter collision are disabled. Its supplies-room partition still provides the wall-collision regression fixture.

The trench runs along x −9, z 19…33 with a side branch west to x −18 at z 27. A gradual entrance descends over approximately 4.5 m; the bottom is about 1.55 m below the zero-height clearing datum and 1.4 m wide. Soil walls use the terrain collision, so there is no invisible flat floor capping the excavation. Timber revetments are decorative over the earth walls. The design is a fictional traversal fixture, not a researched historical reconstruction, runtime digging, construction costs or a functional camp job. The existing annex's construction exercise remains separate.

This is a finite prototype patch with low outer rises; mission boundaries/edge handling are not implemented. Use P after walking past the far terrain edge or getting stuck. An unbounded world generator is not introduced.

### Detailed assets and placement

Default seed 19461101 produces **229 trees, 21 fallen logs, 12 stumps, 9 rocks, 961 ferns, 1,661 grass tufts, 1,667 litter clusters and 576 moss clumps**, in addition to the original manual proof props. Spruce, Scots-pine-inspired and birch-inspired meshes vary by height, orientation and palette. Native opaque geometry is original procedural work; shapes and materials remain stylized candidates. Branch proportions, bark/wood texture character, leaf aliasing and species fidelity still need art refinement. No new image-generation output or external art is claimed.

The scene bakes 391 spatial MultiMesh batches in 14 m cells, using shared mesh/material resources. Large-object spacing, fixture/annex/trail/trench exclusions and terrain height placement are deterministic. Trunks use cylinders, logs/stumps primitive colliders; small vegetation, moss and litter are decorative and nonblocking. No scattering runs during ordinary play. Manual artists can add overrides beside `GeneratedForest`; rebaking replaces its named resources and generated scene only.

Natural-reference links: the [Latvian National Museum of Natural History's forest exhibit](https://www.dabasmuzejs.gov.lv/en/temporary-exhibitions/exhibition-there-life-without-biodiversity/forest) describes fallen deadwood and associated forest life; Latvia's [Nature Conservation Agency describes moss on trunks and decaying wood](https://www.daba.gov.lv/en/biologically-valuable-tree). These contemporary ecology references inform the deadwood/moss emphasis, not a reconstruction of a specific place in 1946. No reference pixels were copied.

### Bake and verification commands

```text
<godot> --path . --script res://scripts/environment/bake_training_forest.gd
<godot> --path . --script res://scripts/environment/bake_training_forest.gd -- --seed=19461101 --tree-spacing=5 --undergrowth=6500
<godot> --headless --fixed-fps 60 --path . --script res://tests/forest_terrain_check.gd
<godot> --path . --disable-vsync --max-fps 0 --script res://tests/forest_terrain_check.gd -- --evidence=<absolute writable directory>
```

**Baking requires the actual Compatibility renderer; omit `--headless`.** Dummy headless rendering saved MultiMeshes without their instance-transform buffers during the first attempt. GPU inspection caught the invisible scenery. The baker now rejects headless use before mutating outputs, and the integration test checks for serialized buffers. Physics checks on the included baked content still run headless. Tree spacing accepts 3–12 m; undergrowth accepts 0–30,000 attempts. These parameters are authoring controls, not runtime gameplay settings.

Seven focused checks passed after the terrain/detail changes: `prototype_smoke`, `training_smoke`, `ads_smoke`, `muzzle_smoke`, `training_environment_check`, `forest_terrain_check`, `camp_annex_smoke`. The updated terrain check additionally passed walking beyond the old perimeter, descending/returning via the ramp, traversing the trench branch, wall containment, weapon-height ray cover and height/collision agreement. The GPU run passed too. Four rendered views were inspected; an interior capture was moved out of a canopy to avoid presenting a foliage-obscured inspection frame. No co-op, prolonged motion quality or completed art acceptance is claimed.

### Measured results

Raw results: [forest_training_measurements.json](forest_training_measurements.json). Godot 4.7.2 official, OpenGL Compatibility, GTX 1080 (driver 582.28), 1280 × 720, default shadowed sun/depth fog, complete F5 scene including annex/character prototypes. Each view settled for 30 physics ticks and sampled 300 uncapped process-frame intervals. No movie writer or fixed-FPS option was used.

| View | Median interval | 95th percentile | Max draw calls | Rendered primitives including passes |
|---|---:|---:|---:|---:|
| Clearing toward woodland | 1.886 ms | 3.164 ms | 295 | 2,013,375 |
| Forest interior | 1.739 ms | 2.678 ms | 154 | 1,787,953 |
| Inside trench | 1.209 ms | 1.928 ms | 169 | 1,070,019 |
| Trench approach | 1.685 ms | 2.403 ms | 233 | 1,907,576 |

Process texture memory: 89,070,775 bytes; process video memory: 134,304,527 bytes, including character/weapon/annex assets. These counters are not environment-only or unique triangle counts. The short stationary intervals are not GPU timestamps, guaranteed FPS or a sustained traversal benchmark; concurrent desktop activity is uncontrolled. The final run still reports unavailable root-certificate-store access; earlier runs also reported blocked shader-cache writes. No scene/script/shader compilation errors remained in the accepted capture run.

Remaining original biome work: a dedicated `forest_biome_test.tscn` if still desired alongside F5, tent/camp environment art, seasonal snow, wind/fire, LOD, extended traversal/planning-view checks and owner visual/performance acceptance. The newly added terrain, density controls and instancing must not remain listed as unimplemented merely because the initial proof record above predates them.

## Birch texture skins and three-dimensional detail — v3 candidate

Owner feedback: the birch's broad flat polygons lacked detail, followed by a request to wrap trees in detailed skins. Replaced this species' shared resources with a curved, smoothly shaded trunk, tapered forks, drooping twigs and folded individual leaf surfaces. **Detailed generated textures now wrap the wood and leaf geometry.** Other tree species, world placement, terrain, collision primitives and player/weapon/character work are unchanged.

Source: `scripts/environment/birch_recipe.gd`, using its own seed 194611013. `bake_birch.gd` rebuilds only birch resources, without regenerating the forest. The full forest baker retains its original random draws before calling the improved recipe, preserving placement determinism on future bakes. Existing material/mesh resource paths keep all placed/batched birches updated automatically.

Two built-in image-generation outputs are preserved unchanged in `assets/environment/source/`; runtime PNG copies and tracked import presets are in `assets/environment/textures/`. Bark imports at a maximum 512 px, leaf at 256 px, both with mipmaps. Bark uses linear anisotropic sampling and a complete mirrored texture period around the trunk to close the UV seam. Leaf cutouts use alpha scissor 0.4 and four folded triangles per leaf, with varied orientation/tint; no blended foliage transparency is introduced. Approximate bump shading is inferred from bark albedo, not an authored or calibrated normal/height map.

Exact prompts, generated source/runtime paths, method and botanical reference links are in [BIRCH_TEXTURE_PROMPTS.md](../assets/environment/source/BIRCH_TEXTURE_PROMPTS.md). Sources include RHS, Kew and the Burke Herbarium for white/papery upper bark, rougher lower bark, drooping tips and toothed leaves. Texture generation did not consume downloaded reference images. The deliberately enlarged 8.5–12.5 cm leaf cards aid prototype readability and should not be mistaken for exact botanical leaf dimensions.

Validation: original and revised candidates captured from matching whole-tree, bark, crown and reverse views; revised seam-side and leaf-skin close-ups were also inspected on the GTX 1080 Compatibility renderer. Bark detail/UV seam and alpha edges were checked visually. Initial sparse foliage was thickened before acceptance of this candidate. No obvious white cutout fringe or hard cylinder seam appeared in the inspected views; this does not establish all-angle/motion acceptance. Structural report: [birch_asset_review.json](birch_asset_review.json).

Geometry tradeoff: old birch 1,218 wood + 1,680 crown triangles; revised candidate **19,510 wood + 67,200 foliage triangles**, including 16,800 folded cutout leaves. This is a close-detail candidate, not an approved final vegetation budget. Distance LOD remains needed before larger population expansion.

`training_environment_check` and `forest_terrain_check` passed headless against the updated assets, and the real-renderer terrain/trench run also passed. Current F5 samples: [birch_forest_measurements.json](birch_forest_measurements.json). Same GTX 1080 / Compatibility / 1280 × 720 / 300 uncapped frame-interval samples per view, no fixed-FPS or movie writer. Clearing median/p95 **5.688/8.817 ms**; forest interior **2.256/5.842 ms**; trench interior **5.034/7.466 ms**; trench approach **5.616/6.348 ms**. Max counters: 300 draw calls and 4,171,767 rendered primitives including passes; process texture/video counters 90,774,708 / 144,141,296 bytes. These are short stationary process-frame samples, not GPU timestamps or sustained performance guarantees. Certificate-store and shader-cache-write diagnostics remain in restricted-run logs; no scene/script/shader compile errors were reported.

Commands:

```text
<godot> --headless --path . --script res://scripts/environment/bake_birch.gd
<godot> --path . --script res://tests/birch_visual_review.gd -- --evidence=<absolute writable directory>
```

The birch-only baker can run headless because it saves ordinary meshes/materials; the full forest MultiMesh baker still requires actual rendering. Owner visual review, leaf sizing/distance readability, long-motion shimmer, LOD and further texture variation remain pending. No new final art style, gameplay treatment or historical reconstruction is approved.

### Birch root-collar refinement — v2.1

Owner gave positive feedback on the skins, then requested a more birch-like root flare. The original six small radial root tubes looked like attached fins. The revised base is one continuous trunk surface: gradual widening concentrated near soil level, four unequal low root shoulders, denser geometry around the collar and a buried lower rim. Surface normals follow the flared geometry. A soft darker soil-contact band ties the existing bark skin into the base. Branches, leaves, skins, art random stream, forest placement and existing approximate trunk collision remain unchanged.

Reference interpretation: [RHS silver birch](https://www.rhs.org.uk/plants/2261/betula-pendula/details) describes darker rugged bark at the base; [Clemson Extension's root-flare guidance](https://hgic.clemson.edu/its-shrub-and-tree-planting-time-mind-your-roots/) shows the trunk-to-structural-root transition. The chosen subtle collar is an artistic candidate, not a measured reconstruction of a particular birch or a planting instruction.

Validation: before/after root close-ups at eye height, low front and reverse angles were rendered and inspected on GTX 1080 Compatibility. Reduced the first collar's widening after inspection to avoid a skirt-like base. `training_environment_check` passed against the rebuilt shared resources; no new unit tests or broad repeated gameplay suite were added for this local art change. Existing certificate-store/cache-write diagnostics remain. Current asset cost: 20,582 wood + 67,200 leaf triangles (87,782 total); [birch_root_review.json](birch_root_review.json) preserves the render report. Earlier timing samples above predate this small collar change; no new performance benchmark is claimed. Owner root-shape review and checks across more ground slopes remain pending.

## Pine skins and deadwood — v4 candidate

Owner requested the same detail upgrade for pines, including dead/broken branches, fallen pines and rotten moss-covered fallen pines. Existing training forest pine instances now use a curved tapered trunk, 25 irregular high crown limbs, folded/crossed needle sprays, and dead lower branch stubs with solid splintered breaks. Generated lower grey fissured bark blends into warmer flaky upper bark. The mature high-crown interpretation is based on [RHS Scots pine](https://www.rhs.org.uk/plants/13141/pinus-sylvestris/details/), [Flora of New Zealand](https://www.nzflora.info/factsheet/taxon/Pinus-sylvestris.html) and [Forestry England](https://www.forestryengland.uk/article/scots-pine). Proportions remain artistic candidates, not exact botanical measurements.

Four unchanged generated source PNGs and their runtime copies are retained; bark/decay imports at 512 px and needles at 256 px with mipmaps. Needles use alpha scissor 0.45 and small bent/crossed cards, not whole-tree billboards. Bark includes approximate albedo-derived bump. See [PINE_TEXTURE_PROMPTS.md](../assets/environment/source/PINE_TEXTURE_PROMPTS.md) for exact generation/edit prompts, tool output paths, references and low-alpha source fringe findings. No downloaded reference pixels or third-party textures were used.

### Assets and placement

`pine_recipe.gd` reuses birch tube/curve authoring helpers without changing birch resources. `bake_pines.gd` rebuilds ordinary pine mesh/material/scene resources headless, retaining the existing `forest_pine_{wood,crown}_v1.res` paths so all placed pine MultiMeshes update on restart. The full forest baker consumes its legacy pine random draws before delegating, preserving deterministic placements. No full forest scatter was rerun for this iteration.

A separate additive `pine_debris_generated.tscn` contains **2 fallen pines, 3 rotten logs, 2 standing broken snags and 12 loose dead/broken branches**. Own placement seed: 194611020. Existing forest seed/counts remain unchanged; these 19 props are additional to the old logs/stumps. Placement samples terrain along log footprints and excludes fixtures, annex access, trail and trench. This keeps concurrent character/UI/gameplay work separate. Only `training_environment.tscn` adds the new subscene; player/weapon rules were not edited.

Fresh fallen pines have taper, residual needle sprays, projecting dead limbs and splintered ends. Rotten logs have irregular flattened shells, real missing upper sections, inset inner wood, open jagged ends and low moss cushions. Large deadwood uses matching static mesh collision so hollow ends remain open; fresh/rotten bodies join the existing vaultable group. Snags have trunk collision. Small loose branches remain decorative/nonblocking; no resource collection or woodcutting gameplay is implied.

| Asset | Triangles |
|---|---:|
| Living pine | 50,760 |
| Fallen pine including crown remnants | 5,398 |
| Rotten log including moss cushions | 4,214 |
| Broken snag | 1,338 |
| Loose broken branch | 532 |
| Loose dead branch | 362 |

Counts are unique mesh triangles, not renderer pass totals. Structural render report: [pine_asset_review.json](pine_asset_review.json).

### Rebuilding and validation

```text
<godot> --headless --path . --script res://scripts/environment/bake_pines.gd
<godot> --headless --path . --script res://scripts/environment/bake_pine_debris.gd
<godot> --path . --script res://tests/pine_visual_review.gd -- --evidence=<absolute writable directory>
<godot> --headless --fixed-fps 60 --path . --script res://tests/pine_debris_check.gd
<godot> --fixed-fps 60 --path . --script res://tests/pine_debris_check.gd -- --evidence=<absolute writable directory>
```

The additive placement baker saves ordinary scene nodes and can run headless. The **full forest MultiMesh baker still needs the real renderer**. Species rebuilds preserve world transforms.

Validation: asset bake passed; `training_environment_check`, `forest_terrain_check`, `training_smoke` and new `pine_debris_check` passed. The latter verifies solid fresh/rotten wood ray blocking, an open hollow end, nonblocking decorative branches, and an actual existing-controller vault over the clear butt section with a clear opposite landing. GPU asset views and fresh/rotten props in the actual training forest were inspected on GTX 1080 Compatibility. First sparse crowns, flat splinters and overly raised moss were revised following rendered inspection. The final real-renderer terrain/trench check and debris check also passed. These checks do not establish all approach angles, prolonged play, multiplayer or owner art acceptance.

### Measured cost and remaining work

Raw current complete-scene results: [pine_forest_measurements.json](pine_forest_measurements.json). Godot 4.7.2, GTX 1080 / OpenGL Compatibility, 1280 × 720, existing shadowed sun/depth fog, 300 uncapped process-frame intervals per view after 30 settling physics ticks. No fixed FPS or movie writer was used for this timing run.

| View | Median interval | 95th percentile | Max draw calls | Rendered primitives including passes |
|---|---:|---:|---:|---:|
| Clearing toward woodland | 13.290 ms | 21.377 ms | 380 | 7,840,191 |
| Forest interior | 2.343 ms | 9.204 ms | 150 | 1,787,553 |
| Inside trench | 10.421 ms | 18.190 ms | 210 | 6,090,827 |
| Trench approach | 8.444 ms | 17.816 ms | 300 | 5,879,468 |

Process texture/video counters: 95,298,053 / 153,601,413 bytes, including unrelated game assets. Detail raises the rendering cost materially relative to the previous birch-only sample. These short stationary process intervals are not GPU timestamps or guaranteed sustained FPS; desktop activity was uncontrolled. Restricted-run certificate-store and shader-cache-write diagnostics remain; accepted runs had no script/shader compilation failures.

This is a close-detail candidate. **Distance LOD and foliage/shadow optimization are the next performance work before expanding density.** Silhouette variation, long-motion needle shimmer, moss variety, all-slope seating and owner visual acceptance remain open. No winter, wind, fire, campaign construction or final biome completion is claimed.


## Nature asset lineup — review scene

Owner requested all nature assets in one labeled line. `scenes/environment/environment_asset_test.tscn` is a separate F6 review area. `nature_asset_catalog.gd` explicitly lists 17 current specimens: the first spruce proof, forest spruce, detailed pine and birch, original fallen log and stump, detailed fallen/rotten/snapped pine, two loose branch variants, boulder, fern, grass tuft, leaf litter, moss clump and the original 24 m moss/dirt ground surface. Composite forest/debris scenes and the manufactured crate are excluded. The remaining simpler conifers are spruce resources; no fictional old-pine comparison was manufactured after its shared resources were upgraded.

Each specimen retains the actual current source resource and authored scale. Bounds determine spacing and place its front behind the aisle. Numbered world labels show name/status, and the HUD names the nearest station. Page Up/Down jumps between specimens and frames their height; WASD/mouse allows close/reverse inspection. The local gallery-player adapter reuses movement and clearance while hiding/disabling weapon presentation and rejecting firing commands. Main player, weapon, menu and forest resources were not changed for this review area. Running it in the editor does not scatter or rebake anything.

Open the scene and press F6, or run `<godot> --path . res://scenes/environment/environment_asset_test.tscn`. Check: `<godot> --headless --fixed-fps 60 --path . --script res://tests/environment_asset_test_check.gd`. Add the real renderer and `-- --evidence=<absolute writable directory>` to capture review frames.

Validation: coverage check confirms every current standalone nature scene plus the three separate ground-cover mesh resources appears, with a label and visible geometry. It verifies nonoverlapping specimen bounds, a clear front lane, solid floor and actual walking at every station, previous/next input, boundary handling and suppressed gallery shooting. Headless and real GTX 1080 Compatibility runs passed. Tree, old log/stump, detailed pine deadwood and ground-cover captures were inspected; enlarged the first labels and reduced the HUD after visual review. Restricted-run root-certificate/shader-cache diagnostics remain. The gallery is not a completed forest biome or art acceptance; original log/stump/spruce/ground-cover upgrades and pine/birch LOD remain pending owner priorities.
