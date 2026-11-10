# How to Use — World Map & Events

## Purpose

Overworld progression: move player, interact with markers, launch battles, earn rewards, return after victory.

**Making a new map, step by step** (map JSON, room, markers, hooking it up, linking from the previous map), and the
**battle background rules** (where the ground must be so units stand on it): see `datafiles/README.md` →
*World maps (making a new map)* and *Battle backgrounds and where units stand*.

## Main scripts

- `scr_worldmap_controller` — map room init, HUD, collection button
- `scr_worldmap_config` — globals, JSON load, event flow, cleared state
- `scr_worldmap_progress` — battle launch, victory, spawn, player movement
- `scr_worldmap_events` — `eventmarker_*` marker API
- `scr_worldmap_graph` — node travel (WASD / click, "are you sure?" box) and random side branches

## Story path + random side branches

Your hand-placed markers stay the story path, in `event_flow` order: start → 1 → 2 → …
The next story node opens once the one before it is cleared; you can walk back to earlier ones.

After each **first** win of a story battle, a random side branch may pop up off that node:

```
story → side                 (single)
story → side → side          (chain: the second opens after the first is done)
side ← story → side          (fork: one on each side of the path)
```

Side nodes are a side battle (from the map's `battleset`, near the story battle's difficulty) or a treasure
(a short scene — "Hero has explored the valley." / "What's this?!?!" / "Found a card - <name>" — then the card).
A branch **stays until every node in it is done** — you can walk away and come back. Once it's all done it
disappears as soon as you walk off it. Several branches (one per story node) can be on the map at once.
Side nodes are one-shot (no replay). Side node ids start at 1001; `global.worldmap.side_branches` holds the
branches (each node has `parent` and `children` ids).

```json
"side_events": {
  "chance": 1.0,
  "shape_weights": { "single": 1, "fork": 1, "chain": 1 },
  "treasure_chance": 0.3,
  "chain_treasure_chance": 0.5,
  "battle_rewards": [],
  "chain_battle_rewards": [ { "id": 6, "chance": 100 }, { "id": 11, "chance": 100 }, 12 ],
  "treasure_rewards": [{ "id": 8, "chance": 100, "once": true }, { "id": 9, "chance": 100 }],
  "battle_names": ["Bandit Ambush", "Wolf Den", "Goblin Camp"],
  "treasure_names": ["Hidden Cache", "Old Chest", "Mossy Shrine"],
  "places": ["valley", "forest clearing", "old ruins"]
}
```

| Setting | What it controls |
|---------|------------------|
| `chance` | 0–1 chance of a branch after each first story win (1.0 = always) |
| `shape_weights` | how often each shape appears — `single` (left **or** right), `fork` (left **and** right), `chain` (two in a row). 0 = never |
| `treasure_chance` | single / fork: chance each node is a treasure instead of a battle |
| `chain_treasure_chance` | chain: chance of **battle → treasure** instead of **battle → battle** (a chain always starts with a battle) |
| `battle_rewards` | single / fork side battles drop one card from this list (`[]` = no card) |
| `chain_battle_rewards` | battle → battle: **each** of the two battles drops one card from this list |
| `treasure_rewards` | treasures give one card from this list |

Battle → treasure: the battle drops nothing, only the treasure gives a card.
Reward lists take `{ "id", "chance", "once" }` entries or plain card ids (`12` = id 12, chance 100);
`chance` is a weight — one card is picked per battle / treasure.

`battle_names` / `treasure_names` are the names shown on side nodes (picked at random, avoiding names already
on the map). `places` is only used in the treasure scene text. Remove the block to turn side events off for that map. No branch is made when the win sends you to another map.

**Controls:** WASD / arrow keys slide to the linked node in that direction; clicking a glowing node travels there.
Arriving never starts anything — press **E / Enter** on a node to start it (or replay a cleared story battle).
With the mouse, clicking a node that would start something opens **"Are you sure you want to go here?" Yes / No**
(Y / N / Esc also work); Yes travels there and starts it.

**Winning a battle:** the battle ends the moment the last enemy dies — a Victory panel shows the reward and the
map comes back after 2 seconds (click / E skips the wait).

## Main objects

```
OBJ_EventMarker          ← parent template (DO NOT place in room)
├── OBJ_Map1_Marker01
├── OBJ_Map1_Marker02
├── OBJ_Map1_Marker03
├── OBJ_Map1_Marker04
├── OBJ_Map1_Marker05
└── OBJ_Map2_Marker01

OBJ_WorldMapController   ← map init / HUD
OBJ_PlayerMarker         ← player movement + E interact
```

## Responsibilities

- Assign `event_id` from room marker `marker_order`
- Unlock chain via `event_flow` in map JSON
- Snap player to event (hold WASD 0.25s to break free)
- Launch battle, grant first-clear rewards, spawn above beaten marker
- Dialog pre/post with `_once` flags

## Dependencies

- Dialog system, battle room, collection, bootstrap data

## Public API

```gml
// Marker Create (content wiring)
eventmarker_apply_config(order, label, battle_id, battleset_file, replay_pool_csv);
eventmarker_apply_reward(gift_count, randomize);
eventmarker_reward_add(card_id, weight, collection, once);
eventmarker_set_dialog_pre(script_func);
eventmarker_set_dialog_pre_once(true);   // skip on replay
eventmarker_set_dialog_post(script_func);
eventmarker_set_dialog_post_once(true);

// Runtime
worldmap_InitRoom("Grasslands_WorldMap01.json");
worldmap_LaunchEventBattle(event_id);
worldmap_ReturnToMapAfterVictory();
worldmap_PlayerMovementStep(player_id);
worldmap_TryPlayerInteract(player_id);
```

## Initialization order

```
Room_Worldmap1 creation code → global.worldmap_room_config_file
OBJ_WorldMapController Create → SCR_WorldMapController_Init()
  → worldmap_InitRoom()
  → worldmap_SyncMarkersFromRoom()  // assigns event_id
  → worldmap_ApplyPendingPlayerSpawn()  // after battle
  → dialog_TryRunPendingPost()
```

## Runtime flow

```
WASD move → enter marker radius → snap
Hold WASD 0.25s → break snap
Press E → pre-dialog (first time) → battle → victory → return above marker
Replay → skip dialog → random replay_pool battle
```

## Example usage

```gml
// OBJ_Map1_Marker01/Create_0.gml
event_inherited();
eventmarker_apply_config(1, "Trail Start", "battle01",
    "Grasslands_Battleset01_starter.json", "battle01,battle02,battle03");
eventmarker_set_dialog_pre(dialog_Map1_Marker01_PreBattle);
eventmarker_set_dialog_pre_once(true);
eventmarker_apply_reward(1, true);
eventmarker_reward_add(9, 100);
```

## Common pitfalls

- Place `OBJ_Map1_MarkerXX` in room, **not** `OBJ_EventMarker`
- `marker_order` must match intended unlock sequence
- `WORLDMAP_SNAP_BREAK_HOLD` macro in `scr_worldmap_config` controls hold duration (0.25s)

## Future expansion

- `EVENT_TYPE.DIALOG` standalone markers
- `EVENT_TYPE.ROOM_TRANSITION` between maps

## Parent / child

Only `OBJ_EventMarker` uses inheritance. Child markers inherit Create/Draw/Step from parent; override Create for config.
