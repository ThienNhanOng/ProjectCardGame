# How to Use — Hand & Deck (Battle)

## Purpose

Shuffle draw pile, deal hand, render card fan, feed plays to board.

## Main scripts

- `SCR_Deck_createinit`, `SCR_Deck_Draw`
- `SCR_Hand_Init`, `SCR_Hand_Create`, `SCR_Hand_DrawFromDeck`
- `SCR_Hand_Draw`, `SCR_Hand_Layout`, `SCR_Hand_GetSpacing`

## Main objects

- `OBJ_Deck` — ID array, shuffled
- `OBJ_Hand` — struct array, drawn cards

## Responsibilities

| Object | Stores |
|--------|--------|
| Deck | Card IDs from `global.battle_deck_source` |
| Hand | Full card structs resolved from `card_DB` |

## Dependencies

- `global.battle_deck_source` (from deck builder READY)
- `SCR_Card_Draw` for visuals
- Must exist before `OBJ_BoardManager`

## Public API

```gml
SCR_Deck_createinit();           // OBJ_Deck Create
SCR_Hand_Init();                 // OBJ_Hand Create
SCR_Hand_DrawFromDeck(count);    // Pull cards into hand[]
```

## Initialization order

```
OBJ_Deck Create → OBJ_Hand Create (finds deck instance)
```

## Runtime flow

```
battle_deck_source → shuffle → draw → hand structs → hover/play → remove from hand
```

## Example usage

Battle start in `SCR_Battle_Init` deals opening hand via `SCR_Hand_DrawFromDeck(5)`.

Draw trait mid-battle:
```json
"ability": "draw:2"
```
→ `SCR_Trait_Draw` → `SCR_Hand_DrawFromDeck(2)`

## Common pitfalls

- **Creation order** — Hand before Deck breaks references
- `SCR_Hand_Functions` in old notes — use `SCR_Hand_Create.gml` instead

## Future expansion

- `OBJ_Discard` pile object
- Max hand size with burn-on-overdraw

## Parent / child

`OBJ_Deck` and `OBJ_Hand` — no inheritance parent.
