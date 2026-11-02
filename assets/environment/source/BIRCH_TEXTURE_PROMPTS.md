# Birch material candidates — 2026-11-01

Method: built-in image-generation tool, two original generated raster assets. No CLI fallback, downloaded reference pixels or paid asset was used. Outputs were inspected before import. Original PNGs are preserved unchanged beside this file; runtime copies live in `../textures/`. Import settings limit bark to 512 px and leaf to 256 px with mipmaps; source files retain full resolution. Leaf alpha is preserved, with alpha-scissor rendering rather than blended transparency. The bark shader uses seam-safe mirrored sampling and an approximate albedo-derived bump; this is not an authored normal or physically calibrated height map.

Reference-led shape/material interpretation: [RHS silver birch](https://www.rhs.org.uk/plants/2261/betula-pendula/details), [Kew silver birch](https://growwild.kew.org/plants/silver-birch), [University of Washington Burke Herbarium](https://burkeherbarium.org/imagecollection/taxon.php?Taxon=Betula+pendula). Contemporary botanical references, not a historical reconstruction. No reference image was supplied to image generation.

## Bark

Source: `birch_bark_generated_v2.png`; runtime: `../textures/birch_bark_v2.png`.

Use case: photorealistic-natural. Asset type: seamless tileable diffuse/albedo game texture for a three-dimensional silver birch (Betula pendula) trunk in a realistic gritty Latvian woodland game. Generate one square 1024x1024 opaque texture, edge-to-edge UNWRAPPED BARK SURFACE, not a picture of a cylindrical tree. Front-on orthographic surface, equal detail and scale everywhere; must repeat horizontally and vertically without a visible join. Chalk-white to silvery cream paper bark, fine layered papery peeling edges, irregular thin HORIZONTAL dark charcoal lenticels, a few small dark grey scars, subtle warm grey mottling and fine tactile grain. Natural realistic surface detail with restrained painterly coherence, muted neutral colors. Texture covers approximately one metre square of upper/middle trunk surface; no large prominent recognizable knot, no giant crack forming a repeated symbol. Even diffuse illumination, no cast shadow, no directional highlights, no ambient vignette or left/right brightness gradient. White bark is dominant with dark marks occupying less than fifteen percent. No tree silhouette, leaves, ground, branches protruding, sky, perspective, frame, text, labels, watermark or decorative border. This is a usable flat material color map, not a rendered tree illustration. No normal-map rainbow colors or baked directional light.

## Leaf

Source: `birch_leaf_generated_v2.png`; runtime: `../textures/birch_leaf_v2.png`.

Use case: photorealistic-natural. Asset type: single alpha-cutout silver birch leaf color texture for a 3D game mesh. Generate ONE single silver birch (Betula pendula) summer leaf, front-on flat orthographic view, stem end at bottom center, sharp tip at top center. Shape: small ovate-rhombic/triangular leaf with pointed tip, wedge-shaped base and fine double-toothed serrated margin. Natural muted forest green, subtle lighter branching veins from one central midrib, tiny organic mottling, realistic botanical surface detail with restrained gritty painterly coherence. Neutral even diffuse illumination, no shiny highlight, no hard shadow. Single leaf fills about 85% of square canvas height, visible pointed tip and entire serrated outline; no twig, branch, other leaves, water droplets, damage holes, text, labels, grid, border or watermark. True transparent alpha outside the leaf, with no white fringe or background pattern. One square 1024x1024 PNG. Intended for UV mapping to gently folded 3D leaf geometry, not an illustration of a tree or a foliage cloud.

## Rebuild

`<godot> --headless --path . --script res://scripts/environment/bake_birch.gd` replaces only the shared birch mesh/material resources. It uses a separate seed and preserves existing forest placement. The full forest baker also calls this recipe after retaining the old species' random draw sequence, so future forest bakes do not silently restore the flat birch or reshuffle placements merely because its art changed.

Textures are skin/detail candidates awaiting owner review. Do not infer that generated images are perfectly tileable or botanically exact. The branch/leaf geometry and material settings must still be checked in the engine; acceptance is not established by successful generation.
