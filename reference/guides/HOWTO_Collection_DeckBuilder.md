# How to Use — Collection & Deck Builder

## Purpose

Build a battle-ready deck from owned cards. Minimum 8 cards in main deck; spirits auto-route to extra deck.

## Main scripts

| Phase | Scripts |
|-------|---------|
| Create | `SCR_DBC_Create`, `SCR_DBC_InitGrid`, `SCR_DBC_InitDeck` |
| Draw | `SCR_DBD_Draw`, `SCR_CardSlot_Draw*` |
| Step | `SCR_DBS_HandleScrolling`, `SCR_DBS_HandleDeckClick`, `SCR_DBS_HandleReadyButton` |

## Main objects

- `OBJ_DeckBuilder` — UI controller
- `OBJ_CardSlot` — one per grid cell (dynamic instances)
- `OBJ_GameController` — must load data first

## Responsibilities

- Show paginated owned cards
- Add/remove cards from main deck list
- Validate READY (≥ 8 cards)
- Save to `global.battle_deck_source` and `global.battle_extra_deck_source`

## Dependencies

- `card_DB`, `global.player_collection`
- `worldmap_GetCollectionReturnRoom()` for exit target

## Public API

```gml
SCR_DBC_Create();                    // Deckbuilder Create
SCR_DBS_HandleReadyButton();         // Save + leave
battle_SaveDeckSources();            // Writes globals
worldmap_OpenCollection();           // Map → collection room
```

## Initialization order

```
OBJ_GameController (loads DBs)
  → OBJ_DeckBuilder Create → SCR_DBC_Create()
    → spawns OBJ_CardSlot grid
```

## Runtime flow

```
Browse grid → click card → add to deck → READY → save globals → room_goto map
```

## Example usage

From world map HUD, click **Collection** button → `worldmap_OpenCollection()` → edit deck → **READY** → return to map.

## Common pitfalls

- Fewer than 8 cards blocks READY
- Main deck stores IDs; hand in battle resolves to full structs via `card_DB`

## Future expansion

- Named deck slots (Deck A / Deck B)
- Search/filter by card type

## Parent / child

No object inheritance. `OBJ_CardSlot` instances are children of the room, not of `OBJ_DeckBuilder` type hierarchy.
