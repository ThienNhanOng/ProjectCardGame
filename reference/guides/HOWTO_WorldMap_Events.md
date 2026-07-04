# How to Use — World Map & Events

## Purpose

Overworld progression: move player, interact with markers, launch battles, earn rewards, return after victory.

## Main scripts

- `SCR_WorldMap_Controller` — map room init, HUD, collection button
- `SCR_WorldMap_Config` — globals, JSON load, event flow, cleared state
- `SCR_WorldMap_Progress` — battle launch, victory, spawn, player movement
- `SCR_EventMaker` — `eventmarker_*` marker API

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
- `WORLDMAP_SNAP_BREAK_HOLD` macro in `SCR_WorldMap_Config` controls hold duration (0.25s)

## Future expansion

- `EVENT_TYPE.DIALOG` standalone markers
- `EVENT_TYPE.ROOM_TRANSITION` between maps

## Parent / child

Only `OBJ_EventMarker` uses inheritance. Child markers inherit Create/Draw/Step from parent; override Create for config.
