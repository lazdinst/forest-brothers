# Starting civilian — generation prompts

Status: first visual candidate; owner approval pending. Fictional starting camp resident, no finalized name or biography. Not a complete animated/directional sprite set.

Mode: built-in image generation. No CLI/API fallback used.

Selected output: painted front idle candidate (second pass), 1024 x 1536 PNG with alpha. Transparent corner and outside-silhouette sample points were checked. Source remains at the generated-image path; a copy is preserved with the project.

Historical status: plausible civilian design direction, not a verified reconstruction of a particular 1946 Latvian outfit. Local clothing references still need research before final production.

## First generation

Use case: stylized-concept
Asset type: first character reference / front idle sprite candidate for the indie first-person game Forest Brothers (Mežabrāļi).
Primary request: Create ONE fictional older Latvian civilian, the sole starting camp resident, in a plausible rural civilian outfit for Latvia around 1946. This is a design candidate, not a portrait of any real person.
Subject: a weathered man in his late sixties, lean but sturdy build, slightly stooped shoulders, a tired kind face, short grey moustache and grey hair under a worn dark brown flat cap. Worn earth-brown wool work jacket with subtle repairs over a grey wool sweater, faded charcoal trousers, scuffed practical dark leather boots. Empty hands relaxed slightly away from his hips so the silhouette reads. No weapon, military uniform, insignia or national costume.
Style/medium: gritty illustrated game sprite, hand-painted with broad deliberate shapes and a restrained low-resolution finish. Believable anatomy and material wear, clear readable silhouette, limited olive, umber, charcoal and muted warm-grey colors with enough face/hand contrast to read on a forest background. Slightly simplified details, crisp controlled edges, no glossy 3D render or photographic microtexture. Character should remain readable when later downscaled to approximately 192 pixels tall.
Composition: single full-body front view at eye level, nearly orthographic perspective, neutral idle stance with both boots flat on one baseline and visible separately. Head to boots fully inside the frame, centered with at least 10 percent transparent margin all around. Both arms, hands, legs and feet anatomically coherent. One character only, no turnaround sheet, no extra poses or inset portraits.
Lighting: soft neutral diffuse illumination, mild consistent top/front light, no strong rim lighting or dramatic cast shadows.
Background: genuinely transparent alpha background, clean cutout, no background scenery, floor, pedestal, ground shadow, color swatch, checkerboard illustration, text, labels, border or watermark.
Avoid: modern equipment, tactical gear, helmets, medals, glowing effects, huge caricature features, chibi/cartoon styling, hard black outlines, excessive tiny texture, cropped feet.

## Selected painted revision

Input: the first generated image, used as the identity/outfit reference.

Edit the supplied character image into a game-ready illustrated SPRITE CANDIDATE. Preserve this exact fictional older man's identity, flat cap, grey moustache, brown repaired work jacket, grey sweater, charcoal trousers, boots, front-facing idle stance and full-body proportions. Change the rendering treatment: replace photographic microtexture with broad, deliberately hand-painted shapes and simplified 3-to-5-value shading for each material, a gritty low-resolution painted adventure-game look. Facial planes and clothing folds should be clear and sparse enough to read at 192 pixels character height. Avoid photorealistic pores, individual cloth fibers, brushy noise, and cartoon/chibi exaggeration. Maintain recognizable weary human expression and naturally coherent hands. Keep both feet fully visible on one baseline. Preserve a single centered character with generous margin, neutral diffuse lighting, and no text or other figures. Crucially remove EVERY surrounding brown glow, vignette, soft cast shadow and haze: outside the actual body/clothing silhouette the pixels must be completely transparent alpha. Clean cutout with only a narrow antialiased contour. Genuine transparent background, no checkerboard drawn into the image. Do not add a floor, scenery, weapon or props.

## Next validation

Approve or revise the appearance, then test a small sprite size and consistent alignment in Godot before generating directional views or animation. No game integration, NPC labor behavior, collision, or character animation is included by this image alone.
