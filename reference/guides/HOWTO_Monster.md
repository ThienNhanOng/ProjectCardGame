# How to Use — Monster System

## Purpose

Spawn enemy waves from battleset JSON, animate attacks, run `enemyability` traits on enemy turn.

## Main scripts

| Area | Scripts |
|------|---------|
| Core | `SCR_Monster_Init`, `scr_monster_data`, `scr_monster_manager`, `SCR_Monster_Draw` |
| Animations | `scr_monster_anim` (registry + per-monster hooks `monsterAnim_<Name>_Draw/Update`) |
| Abilities | `scr_enemy_ai` (decisions/targets), `scr_enemy_abilities` (execution via `trait_Execute`), `scr_enemy_picker` |

## Main objects

- `OBJ_MonsterManager`

## Responsibilities

- Parse wave list from `global.battle_runtime_config`
- Spawn enemies with HP, sprite, ability list from `monster_DB`
- Victory when queue empty + all dead
- Enemy turn → pick ability → animate → apply

## Dependencies

- `EnemyCollection01.json` (monster_DB)
- `Grasslands_Battleset01_starter.json` (wave definitions)
- `scr_battle_turn`

## Public API

```gml
SCR_Monster_Init();                          // Create
scr_enemy_abilities(enemy, entry);    // Run one ability
monster_CheckVictory();                      // Win detection
```

## Initialization order

Last object created in `Room_battle` (after BattleManager).

## Runtime flow

```
Init → read wave → spawn queue → loop enemy turns → abilities → check victory
```

## Example usage

Battleset entry:
```json
"battle01": { "enemies": ["goblin_soldier", "goblin_mage"] }
```

Enemy JSON:
```json
"enemyability": ["attack:2", "buff_attack:1"]
```

## Common pitfalls

- Enemy id in battleset missing from `monster_DB`
- No animation script registered → enemy appears static

## Future expansion

- Register animations via JSON `animation_id` field
- Spawn-on-death adds to queue mid-fight

## Parent / child

`OBJ_MonsterManager` — no parent object.
