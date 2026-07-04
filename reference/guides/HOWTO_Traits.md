# How to Use — Traits & Effects

## Purpose

Single pipeline parsing `ability` / `enemyability` JSON into executable effects for player and enemy actions.

## Main scripts

| Folder | Scripts |
|--------|---------|
| core | `SCR_Trait_Parse`, `SCR_Trait_Execute` |
| Playereffects | `SCR_Trait_Attack`, `Heal`, `Draw`, `OpenZone`, … |
| resources | `SCR_Trait_Resources` |
| conditions | `SCR_Conditions` |
| monsterAbility | `SCR_MonsterAbility_*` |

## Responsibilities

1. `trait_NormalizeEntry(raw)` — string or struct → `{ type, value, ... }`
2. `trait_Execute(entry, ctx)` — dispatch to handler
3. Handler mutates battle state (HP, hand, slots, counters)

## Dependencies

- Called from `SCR_Battle_PlayCard`, weapon equip, action slot, `SCR_Battle_EnemyTurn`
- Board, hand, deck, resource globals

## Public API

```gml
var _entry = trait_NormalizeEntry("attack:3");
trait_Execute(_entry, _context);
```

### Common trait strings (player cards)

| String | Handler |
|--------|---------|
| `attack:N` | `SCR_Trait_Attack` |
| `heal:N` | `SCR_Trait_Heal` |
| `draw:N` | `SCR_Trait_Draw` |
| `openzone:spirit` | `SCR_Trait_OpenZone` |
| `add_counter:energy:1` | `SCR_Trait_Resources` |

Full list: `datafiles/README.md`

## Initialization order

Stateless — no Create event. Loaded with project scripts.

## Runtime flow

```
JSON ability field → normalize → execute → state change
```

## Example usage

Card JSON:
```json
{
  "type": "weapon",
  "ability": ["attack:2", "buff_attack:1"]
}
```

On equip/play, each entry runs through `trait_Execute`.

## Common pitfalls

- New trait in JSON without matching `SCR_Trait_*` script
- Struct syntax errors in `.gml` trait handlers (use `{` not corrupted tokens)

## Future expansion

- Auto-register traits from a manifest table
- Composite traits: `if:condition:then:attack:3`

## Parent / child

Pure script subsystem — no GameMaker object hierarchy.
