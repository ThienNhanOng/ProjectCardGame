# Data & JSON Guide

How to create player cards, enemies, battles, and wire traits in this project.

All game data JSON files live in **`datafiles/`**. Traits are implemented as GML scripts under **`scripts/`**, organized in the **Traits** folder in the IDE.

---

## Quick checklist (new JSON file)

1. Create the `.json` file in `datafiles/`
2. Register it in **`ProjectCardGame.yyp`** as a **Data Files** / `GMIncludedFile` entry (same as existing `cardSet_01.json`, `MonsterSet01.json`, etc.)
3. Load it at startup:
   - **Player cards** → `scripts/LoadCollection/LoadCollection.gml` → `load_Collection("your_file.json")`
   - **Enemies** → `scripts/LoadMonsters/LoadMonsters.gml` → `load_MonsterSet("your_file.json")`
   - **Battle wave** → referenced from `scripts/SCR_Monster_Init/SCR_Monster_Init.gml` (or set `global.battle_config_file` before battle init)
4. Use unique **`id`** (cards) or **`enemyID`** (enemies) within each collection

---

## Player cards (`cardSet_*.json`)

### File shape

```json
{
  "collection": "cardsetTest_01",
  "cards": [
    { ... card entries ... }
  ]
}
```

- **`collection`** — internal collection name (stored on each card at load time)
- **`cards`** — array of card definitions

Loaded by `load_Collection()` in `objects/OBJ_GameController/Create_0.gml`, called from `SCR_LoadAllCollections()`.

### Card types

| `type` | Where traits go | Notes |
|--------|-----------------|-------|
| `monster` | `ability` | Placed on player monster board slots |
| `weapon` | `ability` | Needs `attack` + usually an `attack` trait; `equip: true` |
| `action` | `actionType` | Placed in the action slot; supports `cost` |
| `spirit` | `ability` | Extra deck only; optional `conditions` trait for summon rules |
| `special_monster` | `ability` | Summoned spirit on board (runtime type after summon) |

### Common fields

```json
{
  "id": 1,
  "name": "Goblin I [Draw 1]",
  "type": "monster",
  "tag": ["Goblin"],
  "sprite": "SPR_Monsterplaceholder",
  "level": 10,
  "health": 12,
  "ability": [{ "type": "draw", "amount": 1 }]
}
```

| Field | Used by | Notes |
|-------|---------|-------|
| `id` | All | Unique per card DB entry |
| `name` | All | Display name |
| `type` | All | See table above |
| `tag` | All | Array of strings (e.g. `["Goblin"]`) |
| `sprite` | All | Sprite asset name |
| `level` | Monster, spirit | Tier / Lv label in UI |
| `health` | Monster, spirit | Base HP |
| `cost` | Action | Action slot cost |
| `attack` | Weapon | Base weapon attack value |
| `equip` | Weapon | `true` for equippable weapons |
| `ability` | Monster, weapon, spirit | Trait array (see below) |
| `actionType` | Action | Trait array (see below) |

### Examples by type

**Monster**
```json
{
  "id": 5,
  "name": "Goblin I [Atk All 1]",
  "type": "monster",
  "tag": ["Goblin"],
  "sprite": "SPR_Monsterplaceholder",
  "level": 10,
  "health": 10,
  "ability": [{ "type": "attack_all", "amount": 1 }]
}
```

**Action** (traits in `actionType`, not `ability`)
```json
{
  "id": 23,
  "name": "Action I [Attack 4]",
  "type": "action",
  "tag": ["Goblin"],
  "sprite": "SPR_Actionplaceholder",
  "cost": 2,
  "actionType": [{ "type": "attack", "amount": 4, "uses_per_turn": 1 }]
}
```

**Weapon**
```json
{
  "id": 41,
  "name": "Goblin Sword I [Atk 5]",
  "type": "weapon",
  "tag": ["Goblin"],
  "sprite": "SPR_Weaponplaceholder",
  "equip": true,
  "attack": 5,
  "ability": [{ "type": "attack", "amount": 5, "uses_per_turn": 1 }]
}
```

**Spirit** (extra deck; summon conditions optional)
```json
{
  "id": 50,
  "name": "Goblin Spirit",
  "type": "spirit",
  "tag": ["Goblin"],
  "sprite": "SPR_Monsterplaceholder",
  "level": 30,
  "health": 30,
  "ability": [
    {
      "type": "conditions",
      "requirements": [
        { "type": "min_turn", "amount": 2 },
        { "type": "sacrifice_tag", "amount": 1, "tags": ["Goblin"] }
      ]
    }
  ]
}
```

Omit the `conditions` entry (or use `"ability": []`) for a spirit with no summon requirements.

---

## Traits in JSON

Traits are entries inside **`ability`** (monster / weapon / spirit) or **`actionType`** (action).

### Trait entry format

```json
{ "type": "heal", "amount": 3, "uses_per_turn": 1 }
```

| Field | Purpose |
|-------|---------|
| `type` | Trait id (see table below) |
| `amount` | Numeric strength (player cards) |
| `value` | Alias for `amount` (enemies often use this) |
| `uses_per_turn` | Action slot only — how many times per turn (default `1`) |
| `id` / `card_id` | For `add`, `add_deck`, `add_extra_deck` — target card id in DB |
| `requirements` | For `conditions` only — array of summon requirement objects |

**Aliases** (normalized in `SCR_Trait_Parse`):
- `draw` → `draw_cards`
- `add_to_hand` → `add`
- `add_to_deck` → `add_deck`
- `add_to_extra_deck` → `add_extra_deck`
- `buff_attack` → `self_buff`
- `destroy_target` → `destroy`

### Supported trait types

| JSON `type` | What it does | Example JSON | Trait script (effects folder) |
|-------------|--------------|--------------|-------------------------------|
| `draw` / `draw_cards` | Draw cards | `{ "type": "draw", "amount": 2 }` | `SCR_Trait_Draw` |
| `attack` | Single-target attack | `{ "type": "attack", "amount": 4, "uses_per_turn": 1 }` | `SCR_Trait_Attack` |
| `attack_all` | Hit all enemies | `{ "type": "attack_all", "amount": 2 }` | `SCR_Trait_AttackAll` |
| `heal` | Heal one ally | `{ "type": "heal", "amount": 5 }` | `SCR_Trait_Heal` |
| `heal_all` | Heal all allies | `{ "type": "heal_all", "amount": 2 }` | `SCR_Trait_HealAll` |
| `self_buff` | Buff ATK on self | `{ "type": "self_buff", "amount": 2 }` | `SCR_Trait_BuffAttack` |
| `buff` | Buff ATK on any target | `{ "type": "buff", "amount": 2 }` | `SCR_Trait_BuffAttack` |
| `destroy` | Destroy one enemy | `{ "type": "destroy", "amount": 1 }` | `SCR_Trait_Destroy` |
| `silence` | Silence enemy | `{ "type": "silence", "amount": 2 }` | `SCR_Trait_Silence` |
| `add` | Add card id to hand | `{ "type": "add", "id": 41 }` | `SCR_Trait_AddHand` |
| `add_deck` | Add card id to main deck | `{ "type": "add_deck", "id": 1 }` | `SCR_Trait_AddDeck` |
| `add_extra_deck` | Add card id to extra deck | `{ "type": "add_extra_deck", "id": 50 }` | `SCR_Trait_AddDeck` |
| `conditions` | Spirit summon rules | See spirit example above | `SCR_Conditions` (conditions folder) |
| `none` | No ability (enemies) | `{ "type": "none" }` | — |

### Conditions requirements (spirit summon)

Used inside a `conditions` trait’s `requirements` array:

| Requirement `type` | Fields | Meaning |
|--------------------|--------|---------|
| `min_turn` | `amount` | Can only summon on turn N+ |
| `sacrifice_monster` | `amount`, optional `slots` [1–5] | Sacrifice ally monsters |
| `sacrifice_tag` | `amount`, `tags` | Sacrifice monsters with matching tags |
| `destroy_weapons` | `amount` | Destroy equipped weapons |
| `discard_action` | `amount` | Discard action cards from hand |
| `discard_monster` | `amount` | Discard monster cards from hand |
| `discard_weapon` | `amount` | Discard weapon cards from hand |

---

## Enemies (`MonsterSet*.json`)

### File shape

```json
{
  "collection": "enemySet_01",
  "enemy": [
    { ... enemy entries ... }
  ]
}
```

- **`collection`** must match the `collection` string used in battle wave JSON (e.g. `"enemySet_01"`)
- Loaded by `load_MonsterSet()` in `OBJ_GameController` Create, via `SCR_LoadAllMonsters()`

### Enemy entry

```json
{
  "enemyID": 1,
  "enemyname": "Grunt [Heal 3]",
  "type": "monster",
  "tag": ["Set1"],
  "sprite": "SPR_Monsterplaceholder",
  "level": 10,
  "enemyhealthvalue": 12,
  "enemyattackvalue": 3,
  "enemyability": [{ "type": "heal", "value": 3 }]
}
```

| Field | Notes |
|-------|-------|
| `enemyID` | Unique within this monster set |
| `enemyname` | Display name |
| `enemyhealthvalue` | Max HP |
| `enemyattackvalue` | Base attack (also used each turn) |
| `enemyability` | Trait array — same `type` names as player cards; use `value` instead of `amount` |
| `elite` | Optional `true` — elite styling / naming |
| `animation` | Optional — custom anim key for `SCR_MonsterAnim_*` scripts |

**Multiple traits** (enemy uses one per turn, cycling):
```json
"enemyability": [
  { "type": "heal_all", "value": 2 },
  { "type": "self_buff", "value": 2 },
  { "type": "heal", "value": 3 }
]
```

---

## Battles (`Battle*.json`)

Defines which enemies spawn and how many enemy slots are active.

```json
{
  "battle": "battle01",
  "active_slots": 3,
  "wave": [
    { "collection": "enemySet_01", "enemyID": 1 },
    { "collection": "enemySet_01", "enemyID": 2 },
    { "collection": "enemySet_02", "enemyID": 1 }
  ]
}
```

| Field | Notes |
|-------|-------|
| `battle` | Battle id label (debug / UI) |
| `active_slots` | How many enemy slots are visible (max 5) |
| `wave` | Spawn queue — each entry references a loaded monster set |

Loaded by `battle_LoadConfig()` in `scripts/SCR_Battle_Load/SCR_Battle_Load.gml`.

Default file: **`Battle01.json`**, set in `scripts/SCR_Monster_Init/SCR_Monster_Init.gml`. Override with `global.battle_config_file = "Battle02.json"` before monster init.

**Important:** `wave[].collection` must match the `"collection"` field in the corresponding `MonsterSet*.json`, and `enemyID` must exist in that set.

---

## Traits folder (IDE layout)

In GameMaker: **Scripts → Traits**

```
Traits/
├── core/           Parsing + dispatch
│   ├── SCR_Trait_Parse      ← reads JSON ability/actionType → trait structs
│   └── SCR_Trait_Execute    ← routes trait type → effect script
├── effects/        One script per combat effect
│   ├── SCR_Trait_Attack
│   ├── SCR_Trait_AttackAll
│   ├── SCR_Trait_Heal
│   ├── SCR_Trait_HealAll
│   ├── SCR_Trait_Draw
│   ├── SCR_Trait_Destroy
│   ├── SCR_Trait_Silence
│   ├── SCR_Trait_BuffAttack   ← self_buff + buff
│   ├── SCR_Trait_AddHand
│   └── SCR_Trait_AddDeck      ← add_deck + add_extra_deck
└── conditions/     Spirit summon (not battle-turn traits)
    └── SCR_Conditions
```

### How JSON reaches traits

```
cardSet JSON
  └─ ability / actionType array
       └─ trait_NormalizeEntry()     [SCR_Trait_Parse]
            └─ trait_Execute()       [SCR_Trait_Execute]
                 └─ SCR_Trait_*      [effect script]
```

Enemy JSON follows the same path via `trait_GetFromMonster()` → `enemyability`.

Spirit `conditions` is parsed by `SCR_Trait_Parse` but executed by **`SCR_Conditions`** during extra-deck summon (not `trait_Execute`).

### Adding a new trait type

1. Add JSON examples using a new `"type": "your_trait"` in `cardSet` / `MonsterSet`
2. Create `scripts/SCR_Trait_YourTrait/SCR_Trait_YourTrait.gml` under **Traits/effects**
3. Register the script in **`ProjectCardGame.yyp`**
4. Add a `case` in **`SCR_Trait_Execute`** → call your `trait_ExecuteYourTrait()`
5. Update **`SCR_Trait_Parse`**:
   - `trait_NormalizeEntry` — aliases if needed
   - `trait_GetDisplayText` — preview text
   - `trait_ActionNeedsTargeting` / `trait_ExecuteOnPlay` — if used from action slot
6. Wire player/enemy activation in battle scripts if targeting or turn logic is needed (`SCR_Battle_PlayCard`, `SCR_Battle_EnemyTurn`, etc.)

---

## Load order at game start

`OBJ_GameController` Create event:

1. `SCR_LoadAllCollections()` → fills `card_DB.cards`
2. `SCR_LoadAllMonsters()` → fills `monster_DB.enemies`

Battle room then loads `Battle01.json` (or override) into the enemy spawn queue.

Player ownership for deckbuilder (`owned` counts) is separate — built in `SCR_TestCollection` from `card_DB` at collection room start.

---

## Reference files

| Purpose | Example file |
|---------|----------------|
| Full player card set | `datafiles/cardSet_01.json` |
| Legacy card formats | `datafiles/cardSet_02.json` |
| Enemy set | `datafiles/MonsterSet01.json` |
| Elite enemies | `datafiles/MonsterSet03.json` |
| Battle wave | `datafiles/Battle01.json` |
| Load player cards | `scripts/LoadCollection/LoadCollection.gml` |
| Load enemies | `scripts/LoadMonsters/LoadMonsters.gml` |
| Load battle | `scripts/SCR_Battle_Load/SCR_Battle_Load.gml` |
| Trait parse / display | `scripts/SCR_Trait_Parse/SCR_Trait_Parse.gml` |
| Trait dispatch | `scripts/SCR_Trait_Execute/SCR_Trait_Execute.gml` |
| Spirit conditions | `scripts/SCR_Conditions/SCR_Conditions.gml` |
