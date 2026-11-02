# NPC interaction and dialogue

Status: implemented 2026-11-02 at owner request (generic NPC interaction system; first NPC Ģirts
Ozoliņš). Authored dialogue only; no language-model provider. Numbers (relationship thresholds,
prices, stock) are placeholders.

## Architecture

| Piece | File | Role |
|---|---|---|
| NPC definition | `scripts/npc/npc_definition.gd`, `npcs/*.tres` | Names, portrait, actions offered (`talk`, `trade`, `leave`, later others), dialogue file, relationship stage thresholds, limited trade stock. |
| Dialogue data | `npcs/*_dialogue.json` | Greetings (with conditions and priority), greeting replies, categories, topics, nodes with choices, visit rules, goodbyes. |
| Dialogue provider | `scripts/npc/dialogue_database.gd` | Loads and validates a dialogue file. Another provider (for example a generated one) only needs the same fields and `node()`/`topic()`. |
| Conditions and effects | `scripts/npc/dialogue_rules.gd` | Shared condition and effect vocabulary (listed in the script header). |
| Relationship and memory | `scripts/npc/npc_state.gd` | Hidden values (familiarity, trust, respect, suspicion), memory flags, told nodes, visit flags, bounded event list (20), trade stock left. Saved in the world's camp under `npcs`. |
| Conversation | `scripts/npc/dialogue_controller.gd` | Picks the greeting, filters topics and choices, applies effects, asks the host for gifts or trade. No UI. |
| Trade | `scripts/npc/npc_trade.gd` | Limited lots at fixed rubles/lats prices from the treasury; restocks per outing. Selling uses `CampRuntime.sell_value`. |
| Host | `scripts/npc/npc_host.gd` | Registers NPC bodies in a scene (`F  Interact — name`), keeps states, runs the windows, freezes the player while open. |
| UI | `ui/npc/npc_interaction_menu.gd`, `ui/npc/dialogue_window.gd`, `ui/camp/trader_window.gd` | Menu, dialogue (topic view and conversation view), trade window. Keyboard and mouse; number keys pick replies; Escape steps back, then closes. |

Flow: F on an NPC → menu (from the definition's actions) → Talk opens the dialogue window
(greeting, replies, topics by category, follow-ups, Back, Goodbye) → Trade opens the trade
window → Leave closes and gives control back. Interact is F (the project's existing
`interact` action), not E.

A visit is the time between outings (`GameSession` world `outings`, incremented when an outing
ends). A new visit clears visit flags and runs the NPC's visit rules (for Ģirts: familiarity +1,
and trust and respect +1 when missions were completed since the last visit). Relationship stages
come from the definition's thresholds; suspicion at or above `suspicion_cap` keeps the stage at
the second one. Repeated dialogue clicks do not raise values: once-effects apply a single time.

Context the camp supplies (`ForestCamp.npc_context()`): outings, missions completed, completed
mission ids, time of day, season, weather, player injured/bleeding, rifle carried, Soviet activity
(high after three completed missions). The game has no clock, weather or seasons yet, so those
read as day, overcast and autumn; the night and winter lines exist and are tested with injected
context.

To add an NPC: write a definition `.tres` and a dialogue `.json`, give the NPC body `prompt` and
`action` properties (`scripts/camp/camp_interactable.gd` for a plain body, or a small script like
`scripts/camp/camp_old_man.gd`), and call `npcs.register(body, definition)` in the scene. The
second NPC, Arvīds (a placeholder figure by the path), proves this with Talk and Leave only.

## Ģirts Ozoliņš

Fictional. Ģirts is the camp's existing old man: same sprite, portrait cropped from it, no new
art (character art is frozen). His dialogue (`npcs/girts_dialogue.json`, 129 nodes, 51 topics,
11 contextual greetings) is gated by stage: stranger (small talk, news, basic local knowledge),
acquaintance (childhood, 1905, independence, occupations, family), trusted (the Riflemen and
the Red Riflemen, the security men, informants, supplies, regrets), confidant (helping wounded
partisans, his son in the forest, unguarded opinion of Soviet power). He remembers meeting the
player, stories told, being asked about his service, threats (and an apology), kindness, gifts
and supplies traded.

Trade: three loaves, four portions of potatoes, two bandages, and two village lots for the camp
stores; lots return one or two per outing. Trusted players may get a loaf as a gift once per
visit. Potatoes were added to the supply catalog for him. Salt, matches and candles have no item
definitions yet and are not stocked.

### Historical basis and premises

Researched, used as events he lived through:
- 1905 revolution in the Baltic provinces: manors burned; punitive expeditions executed people
  without trial and burned farms ([latviansonline](https://latviansonline.com/?p=1232),
  [Suiti history](https://suitunovads.lv/en/suiti-history/events-of-year-1905/)).
- Latvian Riflemen battalions formed in 1915; Christmas Battles west of Riga in late December
  1916 / early January 1917 with very heavy losses; by 1917 most riflemen backed the Bolsheviks,
  a minority (mostly officers) did not; about 11,000 former Red Riflemen returned to Latvia
  after the 1920 peace treaty ([Latvian Riflemen](https://en.wikipedia.org/wiki/Latvian_Riflemen),
  [militaryheritagetourism.info](https://militaryheritagetourism.info/en/military/topics/view/83?lang=en)).
- The lats replaced by the ruble in March 1941 ([Bank of Latvia](https://www.bank.lv/en/component/content/article/562-about-the-bank-of-latvia/2611-the-national-currency-of-latvia)).
- 14 June 1941 deportation, about 15,000 people ([June deportation](https://en.wikipedia.org/wiki/June_deportation)).

Widely documented, used without a specific citation here and worth checking before narrative
use: the 1940 occupation and single-list elections; German occupation from 1941, Legion
conscription from 1943, the murder of Latvia's Jews; the front returning in 1944 and Courland
until 1945; compulsory grain deliveries after 1944; hopes of Western intervention after 1945;
the security service being renamed (he only says "a new name every few years").

Game premises, not researched claims: his family and life; villagers trusting lats more than
paper; the forester, his map and the hidden food (they match the game's missions); every place
name in the game.

He knows nothing after 1946: no 1949 deportation, no collectivisation in Latvia (only fear of
it is implied through "lists").

## Testing

- `tests/npc_dialogue_smoke.gd`: data valid (60+ nodes), first/varied/contextual greetings,
  stage-gated topics and branches, threat memory, JSON save/restore, limited stock and restock,
  the second NPC, and the camp window flow (F, Talk, topics, Escape, Goodbye, save).
- `tests/forest_camp_smoke.gd`: F on Ģirts through the real interaction ray, menu, trade, leave.
- `tests/session_persistence_smoke.gd`: his memory survives leaving and rejoining a world.

By hand: Play, a character and a world; at the fire, look at Ģirts and press F. Talk, try
small talk; most of his past is locked at first. Each outing that ends counts as a new visit;
completing missions earns trust. Trusted (about three visits with two completed missions and a
kind reply or two), "His past → Were you a soldier?" opens the Riflemen story.

Limitations: no time of day, weather or seasons yet (context defaults); no Give Item, Recruit or
other actions yet (the menu supports them by name); no voice or animation; Arvīds is a
placeholder figure; the old man still also stands in the camp, though his lines speak of his own
farm nearby.
