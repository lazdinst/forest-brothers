# Polygon humanoid blockout

Original procedural geometry and animations authored for this project. No external character model, animation pack or raster generation was used. The source recipe and exporter live in `source/`; the imported binary assets are civilian/field color variants of the same 32-bone rig. The player reuses the field variant.

- `civilian_v1.glb`: 1,428 triangles.
- `guard_v1.glb`: 1,416 triangles.
- Three skinned meshes per asset: legs, torso and upper body, with temporary vertex-palette colors.
- Eight original prototype clips: idle, walk, run, crouch, aim, reload, interact, die.
- Version `.glb.import` settings and post-import script alongside source; do not version `.godot` caches.

These are blockouts, not final wardrobe, faces, topology, skin weights or period reconstructions. UV textures, hand/weapon contact, locomotion blending, camera/head alignment and retargeting remain work. Existing sprite art is preserved independently.

See [the character pipeline](../../../docs/POLYGON_CHARACTER_PIPELINE.md) for rebuild/use/validation and the rollout scope.
