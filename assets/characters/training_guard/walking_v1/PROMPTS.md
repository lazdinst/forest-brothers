# Walking prompts — built-in image generation

All eight selected sheets use the existing `../rifle_poses_v1/holding_8way_v1.png` as the reference. Each final prompt is the common specification below followed verbatim by its direction-specific text. Each sheet was a separate built-in image_gen call with `transparent_background: true`.

## Common specification

Use case: identity-preserve. Asset: one FOUR-FRAME WALK-CYCLE sprite sheet for a game. Use the supplied atlas solely as character, outfit, held rifle and painted-style reference. One direction only throughout this NEW sheet. FOUR full-body figures in a strict TWO COLUMNS by TWO ROWS grid, evenly spaced equal-sized cells. Genuine transparent RGBA background, no ground, shadows, text, labels or frame borders. Same fictional lean adult man, olive field cap/tunic/trousers, brown belt, worn boots, identical face, same wood and steel rifle held low with BOTH hands. Keep right hand on grip and left supporting fore-end; NO shooting or aiming, no new clothes.
The four cells show a complete ordinary WALKING IN PLACE loop in this order: top-left FIRST HEEL CONTACT (one leg forward, other behind), top-right PASSING (rear leg swings forward beside planted supporting leg, bent knee and raised boot), bottom-left OPPOSITE HEEL CONTACT (the OTHER leg now forward; reverse the leading/trailing legs), bottom-right OPPOSITE PASSING (other supporting leg, opposite knee bent and boot raised). Boots must visibly alternate, not shuffle or repeat the same leading leg. In contact frames, one heel contacts and trailing heel lifts. In passing frames boots are close, supporting leg straight, swinging knee flexed. Moderate stride, not running. Torso centered at the same horizontal coordinate relative to each cell, cap same height, planted sole same ground baseline. Only subtle upper-body bob, held rifle stays steady. Full body, feet, cap and barrel fully visible with generous transparent padding. Same cap-to-ground scale every cell, match existing gritty painted guard style.

## Direction 0°


VIEW: exact FRONT, facing directly toward viewer in ALL FOUR frames, equivalent to cell 0 of reference. First contact has anatomical right leg (screen LEFT) forward, opposite contact has anatomical LEFT leg (screen RIGHT) forward. Front steps foreshorten in depth: alternate which boot is larger/lower foreground and which boot recedes. Show both legs separately, avoid crossing them unnaturally.

## Direction 45°


VIEW: FRONT THREE-QUARTER, body and nose facing diagonally toward screen RIGHT (45-degree view), equivalent to reference cell 1. ALL FOUR frames keep this same three-quarter angle. This is NOT the exact side profile: both eyes and front tunic pockets remain visible. Render a consistent complete alternating-leg cycle at this direction.

## Direction 90°


VIEW: EXACT RIGHT-FACING SIDE PROFILE, nose and entire body facing screen RIGHT in all four cells, equivalent to reference cell 2. One eye only. The legs must pass and alternate clearly. TOP LEFT near leg forward straight and far leg behind; TOP RIGHT near leg planted while far knee swings forward; BOTTOM LEFT far leg forward straight and near leg behind; BOTTOM RIGHT far leg planted while near knee swings forward. Draw complete foot contact and natural toe-off, not four copies of one pose. Rifle muzzle points screen-right/down.

## Direction 135°


VIEW: REAR THREE-QUARTER, equivalent to reference cell 3, body faces diagonally AWAY from viewer toward screen RIGHT. Mostly back of tunic, back of cap and a little right-facing face profile. ALL FOUR cells use this same rear-right angle. Muzzle points screen-right/down ahead of the character. Never change to front view. Alternate the legs for the two contact poses and the two passing poses.

## Direction 180°


VIEW: exact BACK, equivalent to reference cell 4. Character walks directly AWAY from viewer in ALL FOUR cells. Back of cap, back of head and back of tunic, NO face or chest visible. Held rifle mostly occluded by torso with same asymmetrical stock and barrel visibility as reference. First contact: one sole lifted behind and visible; opposite contact: OTHER sole lifted behind. Passing poses alternate a lifted boot near the planted opposite ankle. The two legs swap clearly between top and bottom rows.

## Direction 225°


VIEW: REAR THREE-QUARTER facing screen LEFT, equivalent to reference cell 5. Mostly back of tunic and cap, a little left-facing facial profile; walking diagonally AWAY to LEFT in ALL FOUR cells. This must remain the original right-handed held-rifle pose, not a mirrored screen-right view. Muzzle projects toward screen-left/down, stock on original shoulder. Alternate near and far legs in opposing contact and passing poses.

## Direction 270°


VIEW: EXACT LEFT-FACING SIDE PROFILE, nose and entire body facing screen LEFT in all four cells, equivalent to reference cell 6. One eye only. Preserve the rifle's existing right-handed grip from that left profile; no mirroring of a right-facing sheet. TOP LEFT near leg forward to LEFT, far leg behind; TOP RIGHT near leg planted while far knee swings forward to LEFT; BOTTOM LEFT far leg forward to LEFT and near leg behind; BOTTOM RIGHT far leg planted while near knee swings forward. Make the opposite legs visibly alternate as they overlap. Rifle muzzle points screen-left/down.

## Direction 315°


VIEW: FRONT THREE-QUARTER facing screen LEFT (315-degree view), equivalent to reference cell 7. Both eyes and front tunic pockets visible, body turned diagonally toward screen LEFT in ALL FOUR cells. Not a back view or exact profile. Preserve original RIGHT-handed rifle grip; do not mirror the right-facing sheet. Alternate leading legs between the two contact poses and supporting legs between the two passing poses. Rifle held across lower chest, muzzle left/down ahead of body.
