# How to Use — Board Manager

## Purpose

Manage battle board columns and drag-drop card placement.

## Main scripts

- `SCR_Board_Create` — entry
- `scr_board_setup`, `SCR_Board_EnemySlots`, `scr_board_setup`
- `scr_board_setup`, `scr_board_setup`
- `SCR_DragDrop_Init`, `scr_board_slots`, `SCR_Board_Draw`

## Main objects

- `OBJ_BoardManager`

## Responsibilities

| Column | Card types |
|--------|------------|
| Monster | monster, special_monster |
| Weapon | weapon |
| Action | action |
| Spirit | spirit |

- Track `zone_open` per column (via `openzone` trait)
- Drag from hand → valid slot → triggers play

## Dependencies

- `OBJ_Hand` for drag source
- `scr_battle_play` for validation
- `scr_card_effects`

## Public API

```gml
SCR_Board_Create();        // Create event
SCR_DragDrop_Init();       // Step input
scr_board_slots();   // Per-step updates
```

## Initialization order

After `OBJ_Hand`, before `OBJ_BattleManager`.

## Runtime flow

```
Hand card selected → drag → slot hit test → scr_battle_play → traits
```

## Example usage

Spirit summon requires open spirit zone — play a card with `openzone:spirit` trait first, then drag spirit card.

## Common pitfalls

- Dropping on closed column silently fails
- Slot pixel layout must match `SCR_Board_Dimensions`

## Future expansion

- Enemy-side visible board slots
- Slot highlight for valid drop targets

## Parent / child

`OBJ_BoardManager` has no inheritance parent. Slot instances are factory-spawned helpers.
