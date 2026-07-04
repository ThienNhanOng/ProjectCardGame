# How to Use — Monster System

## Purpose

Spawn enemy waves from battleset JSON, animate attacks, run `enemyability` traits on enemy turn.

## Main scripts

| Area | Scripts |
|------|---------|
| Core | `SCR_Monster_Init`, `SCR_Monster_Data`, `SCR_Monster_Queue`, `SCR_Monster_Draw` |
| Animations | `SCR_Monster_AnimRegistry`, `SCR_MonsterAnim_Goblin*` etc. |
| Abilities | `SCR_MonsterAbility_Execute`, `SCR_MonsterAbility_Picker`, `SCR_MonsterAbility_*` |

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
- `SCR_Battle_EnemyTurn`

## Public API

```gml
SCR_Monster_Init();                          // Create
SCR_MonsterAbility_Execute(enemy, entry);    // Run one ability
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
