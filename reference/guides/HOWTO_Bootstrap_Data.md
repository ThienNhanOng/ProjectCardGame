# How to Use — Bootstrap & Data Layer

## Purpose

Load card and enemy databases at game start. Maintain separate **definitions** (`card_DB`) and **ownership** (`global.player_collection`).

## Main scripts

- `LoadCollection.gml` — `SCR_LoadAllCollections()`
- `LoadMonsters.gml` — `battle_EnsureMonsterDatabase()`
- `SCR_PlayerCollection.gml` — grant, format, ensure initialized
- `SCR_Card_Draw.gml` — render card visuals from structs

## Main objects

- `OBJ_GameController` — Create event only; runs all loads

## Responsibilities

| Global | Contents |
|--------|----------|
| `card_DB` | All card definitions from JSON |
| `monster_DB` | All enemy definitions |
| `global.player_collection` | Cards the player owns |
| `global.battleset_cache` | Parsed battleset files |

## Dependencies

- JSON in `datafiles/` registered as **Included Files**
- Consumed by deck builder, battle, rewards

## Public API

```gml
SCR_LoadAllCollections();           // card_DB
battle_EnsureMonsterDatabase();     // monster_DB
collection_EnsurePlayerInitialized();
collection_GrantBattleReward(card_id, count, collection_name);
```

## Initialization order

```
Room start → OBJ_GameController Create
  → SCR_LoadAllCollections()
  → battle_EnsureMonsterDatabase()
  → collection_EnsurePlayerInitialized()
```

## Runtime flow

Included JSON → parse → structs in globals → other systems query by id

## Example usage

Add a new card set:
1. Place `MyCards.json` in `datafiles/`
2. Add to Included Files in `.yyp`
3. Add filename to `SCR_LoadAllCollections()` merge list

## Common pitfalls

- `file_exists()` fails if JSON not included in build
- Editing `card_DB` does not add cards to player — use `collection_GrantBattleReward`

## Future expansion

- Load paths from `content/cards/` manifest
- Versioned schema validation on parse

## Parent / child

`OBJ_GameController` — standalone root object, no parent.
