# Combat choices to resolve

Status: stealth, sound, enemy searching, ammunition scarcity, and weapon condition are confirmed priorities. Detailed mechanics below are discussion choices, not approved behavior.

The useful design questions describe what the player can observe and do, rather than merely asking whether a system is important.

| Topic | Concrete decision | Proposed starting behavior |
|---|---|---|
| Visual detection | How do stance, movement, distance, light, and cover affect detection? | Enemies need line of sight; recognition builds with exposure instead of every distant glimpse causing immediate combat |
| Sound | Which actions can enemies hear, and how accurately can they locate them? | Footsteps depend on pace/surface; gunfire alerts nearby enemies to an approximate location rather than granting knowledge through walls |
| Searching | What happens after an enemy hears a sound or loses sight of a player? | Investigate/search the last-known area, with defined escalation and eventual search decay |
| Group alerts | Does one alerted enemy instantly alert the whole map? | Local communication/escalation rather than automatic map-wide shared knowledge |
| Ammunition | Are cartridges tracked individually, are partial magazines retained, and is ammo count exact? | Finite ammunition and retained partial magazines; exact magazine/loading interaction needs a weapon prototype |
| Weapon condition | Does wear affect reliability, accuracy, or both; can weapons malfunction? | Visible condition and a repair path; approve malfunction behavior before adding random failures |
| Enemy accuracy | Do reactions, aim, and information obey readable limits? | Avoid immediate perfect fire through vegetation or from unseen positions; choose reaction/accuracy values through tests |
| Friendly fire | Can players injure/incapacitate each other? | Undecided; settle before treatment and hit validation depend on it |

The proposed behaviors are a discussion baseline, not a promise to build every factor at once. Start by testing one enemy with visual detection, a sound investigation, last-known-position search, and one weapon. Define observable tests before adding additional perception factors or tactical coordination.

Historical weapons and ammunition must fit the working 1946 setting and local availability; no weapon roster is approved yet. Do not infer specific suppressed weapons, advanced optics, modern equipment, or elaborate ballistics from the Tarkov reference.
