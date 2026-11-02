# Tactical stance HUD source

Owner-supplied `Three Chalk Partisan Silhouettes.png`, copied unchanged as
`partisan_stances_source.png` for this requested HUD. No historical identity or
third-party licensing claim is inferred. Original image remains in Downloads.

Runtime AtlasTexture regions select standing / partial crouch / full crouch.
A CanvasItem shader turns dark background into transparency using luminance;
source pixels are preserved. Prone uses a separate explicit text indicator,
because the reference contains no prone drawing. These are HUD illustrations,
not new player/NPC meshes or approved character art.
