# Data & JSON Guide

How to create player cards, enemies, battles, and wire traits in this project.

All game data JSON files live in **`datafiles/`**. Traits are implemented as GML scripts under **`scripts/`**, organized in the **Traits** folder in the IDE.

---

## Quick checklist (new JSON file)

1. Create the `.json` file in `datafiles/`
2. Register it in **`ProjectCardGame.yyp`** as a **Data Files** / `GMIncludedFile` entry (filename must match exactly, e.g. `CardSet01.json`)
3. Load it at startup:
   - **Player cards** → `scripts/LoadCollection/LoadCollection.gml` → `load_Collection("YourFile.json")`
   - **Enemies** → `scripts/LoadMonsters/LoadMonsters.gml` → `load_MonsterSet("YourFile.json")`
   - **Battle wave** → referenced from `scripts/SCR_Monster_Init/SCR_Monster_Init.gml` (or set `global.battle_config_file` before battle init)
4. Use unique **`id`** (cards) or **`enemyID`** (enemies) within each collection

---

## Player cards (`CardSet*.json`)

### File shape

```json
{
  "collection": "cardSet_01",
  "cards": [
    { ... card entries ... }
  ]
}
```

- **`collection`** — internal collection name (stored on each card at load time)
- **`cards`** — array of card definitions

Loaded by `load_Collection()` via `SCR_LoadAllCollections()` in `objects/OBJ_GameController/Create_0.gml`.

**Active set:** `datafiles/CardSet01.json`

### Card types

| `type` | Where traits go | Notes |
|--------|-----------------|-------|
| `monster` | `ability` | Placed on player monster board slots |
| `weapon` | `ability` | Needs `attack`; see [Weapons](#weapons) |
| `action` | `actionType` | Placed in the action slot; supports `cost` |
| `spirit` | `ability` | Extra deck only; optional `conditions` trait for summon rules |
| `special_monster` | `ability` | Summoned spirit on board (runtime type after summon) |

### Common fields

```json
{
  "id": 1,
  "own": 2,
  "cardRarity": 0,
  "name": "Warrior I",
  "type": "monster",
  "tag": ["Warrior"],
  "sprite": "SPR_Monsterplaceholder",
  "health": 10,
  "ability": []
}
```

| Field | Used by | Notes |
|-------|---------|-------|
| `id` | All | Unique per card DB entry |
| `name` | All | Display name |
| `type` | All | See table above |
| `tag` | All | Array of strings (e.g. `["Warrior"]`) |
| `sprite` | All | Sprite asset name |
| `own` | Collection init | Copies granted at deckbuilder start. Omit for unobtainable cards |
| `cardRarity` | Monster, weapon, action | `0` = common, `1` = cultivated (UI tier label). Spirits omit this |
| `health` | Monster, spirit | Base HP |
| `cost` | Action | Action slot cost |
| `attack` | Weapon, spirit | Weapon strike value; spirit innate single-target strike (optional) |
| `equip` | Weapon | `true` for equippable weapons |
| `attackRecursion` | Weapon | Attacks allowed per turn in a column (default `1`). See [Weapons](#weapons) |
| `effectRecursion` | Weapon | Non-attack repeatable effects per turn (default `1`) |
| `ability` | Monster, weapon, spirit | Trait array (see [Traits](#traits-in-json)) |
| `actionType` | Action | Trait array (see [Traits](#traits-in-json)) |

### Ownership & deck limits

- **`own`** — at collection init, `collection_GrantFromDatabase()` in `SCR_TestCollection` grants that many copies into `global.player_collection`.
- Cards **without** `own` exist in the DB but are not owned until earned via traits/rewards.
- **Deck copy caps** (even if `own` is higher):
  - `monster`, `weapon` → max **3** per deck
  - `action` → max **4** per deck
  - `spirit` — extra deck only (no main-deck cap)

### Rarity (`cardRarity`)

| Value | UI label | Notes |
|-------|----------|-------|
| `0` | common | Default |
| `1` | cultivated | Yellow tier label in deckbuilder / preview |

Spirits do not use `cardRarity` or tier labels — they show type only.

---

## Examples by type

**Monster (on-play ability)**
```json
{
  "id": 6,
  "own": 2,
  "cardRarity": 0,
  "name": "At Arms!",
  "type": "monster",
  "tag": ["Warrior"],
  "sprite": "SPR_Monsterplaceholder",
  "health": 5,
  "ability": [
    { "type": "add", "id": 7, "repeat": false, "recursion": 1 },
    { "type": "add", "id": 7, "repeat": false, "recursion": 1 }
  ]
}
```

**Monster (tag search → deck)**
```json
{
  "id": 3,
  "own": 1,
  "cardRarity": 0,
  "name": "Scout In Training",
  "type": "monster",
  "tag": ["Warrior"],
  "sprite": "SPR_Monsterplaceholder",
  "health": 5,
  "ability": [
    {
      "type": "add_deck_tag",
      "tags": ["Warrior"],
      "repeat": false,
      "recursion": 1
    }
  ]
}
```

**Action** (traits in `actionType`, not `ability`)
```json
{
  "id": 7,
  "own": 3,
  "cardRarity": 0,
  "name": "Basic Strike",
  "type": "action",
  "tag": ["Warrior"],
  "sprite": "SPR_Actionplaceholder",
  "cost": 1,
  "actionType": [
    { "type": "attack", "amount": 4, "repeat": false, "recursion": 1 }
  ]
}
```

**Weapon (attack)**
```json
{
  "id": 9,
  "own": 1,
  "cardRarity": 0,
  "name": "Wooden Training Sword",
  "type": "weapon",
  "tag": ["Warrior"],
  "sprite": "SPR_Weaponplaceholder",
  "equip": true,
  "attack": 5,
  "ability": [
    { "type": "attack", "amount": 5, "repeat": true, "recursion": 1 }
  ]
}
```

**Weapon (cultivated — repeatable self-buff, no attack trait)**
```json
{
  "id": 10,
  "own": 1,
  "cardRarity": 1,
  "name": "Wooden Training Sword",
  "type": "weapon",
  "tag": ["Warrior"],
  "sprite": "SPR_Weaponplaceholder",
  "equip": true,
  "attack": 5,
  "ability": [
    { "type": "self_buff", "amount": 2, "repeat": true, "recursion": 1 }
  ]
}
```

**Weapon (multi-attack per turn)**
```json
{
  "id": 99,
  "own": 1,
  "cardRarity": 0,
  "name": "Twin Blades",
  "type": "weapon",
  "tag": ["Warrior"],
  "sprite": "SPR_Weaponplaceholder",
  "equip": true,
  "attack": 4,
  "attackRecursion": 2,
  "ability": [
    { "type": "attack", "amount": 4, "repeat": true, "recursion": 2 }
  ]
}
```

**Spirit** (extra deck; summon conditions + combat abilities)
```json
{
  "id": 11,
  "own": 1,
  "name": "Warrior Soul I",
  "type": "spirit",
  "tag": ["Warrior"],
  "sprite": "SPR_Monsterplaceholder",
  "health": 30,
  "ability": [
    {
      "type": "conditions",
      "repeat": false,
      "recursion": 1,
      "requirements": [
        { "type": "sacrifice_monster", "amount": 1 }
      ]
    },
    { "type": "attack_all", "amount": 10, "repeat": true, "recursion": 1 },
    { "type": "add_deck", "id": 2, "repeat": false, "recursion": 1 }
  ]
}
```

Omit the `conditions` entry (or use `"ability": []`) for a spirit with no summon requirements.

**Spirit combat:** Spirits can strike without a weapon (`attack` field or an `attack` trait). Click the spirit or its column to attack. If a weapon is in the same column, weapon attack is **added** to the spirit strike, plus any `attack_buff` on the monster. `attack_all` on spirit or weapon uses the same stacking rules.

---

## Weapons

Weapons sit in the weapon slot below a monster in the same column.

| Field | Purpose |
|-------|---------|
| `attack` | Strike damage shown in card **Summary** as `Attack: N` |
| `attackRecursion` | How many column attacks per turn (default `1`). Summary shows `Usage: N` when `N > 1` |
| `effectRecursion` | Cap for repeatable non-attack effects per turn (default `1`) |
| `ability` | Combat traits — attacks and effects (e.g. `self_buff`) |

### Attack vs effects

- **Attack** — column click damage. Driven by `attack` + optional `attack` trait with `repeat: true`. Uses `attackRecursion` for uses per turn.
- **Effects** — everything else in `ability` (`self_buff`, `heal`, `add`, etc.). Repeatable effects (`repeat: true`) fire at **player turn start** via `battle_RefreshWeaponRepeatableEffects()`, up to each trait's `recursion` (capped by `effectRecursion` where applicable).

### Card preview layout (weapons)

| Section | Shows |
|---------|-------|
| **Summary** | `Attack: N`, and `Usage: N` only when `attackRecursion > 1` |
| **Ability** | All traits (`Attack 5 (once per turn)`, `Self buff ATK +2 (once per turn)`, etc.) |

`Atk / turn` and `Effects` are **not** shown in Summary — those details live in Ability.

### Column attack total (monsters in battle)

When a buffed player monster is on the board, preview **Summary** shows:

```
ATK buff: +2
Attack: 7
```

`Attack` is the full column strike: **spirit/monster base strike + equipped weapon + attack buff**.

---

## Traits in JSON

Traits are entries inside **`ability`** (monster / weapon / spirit) or **`actionType`** (action).

### Trait entry format

```json
{
  "type": "heal",
  "amount": 3,
  "repeat": false,
  "recursion": 1
}
```

| Field | Purpose |
|-------|---------|
| `type` | Trait id (see table below) |
| `amount` | Numeric strength (player cards) |
| `value` | Alias for `amount` (enemies often use this) |
| `repeat` | `true` = can trigger again each turn (weapons at turn start; action slot once per play cycle) |
| `recursion` | Times per turn when `repeat` is `true` (minimum `1`) |
| `uses_per_turn` | **Legacy** — treated as `repeat: true` + `recursion: N` |
| `id` / `card_id` | For `add`, `add_deck`, `add_extra_deck` — target card id in DB |
| `tags` / `tag` | For tag-search traits — string or array of tag strings |
| `requirements` | For `conditions` only — array of summon requirement objects |
| `turns` | For `silence` — enemy turns silenced (alias for `amount`) |

### Repeat & recursion

| `repeat` | `recursion` | Meaning |
|----------|-------------|---------|
| `false` | `1` | Once when the card/ability fires (default for on-play monsters) |
| `true` | `1` | Once per turn |
| `true` | `3` | Up to 3 times per turn |

Preview text appends `(once per turn)` or `(Nx per turn)` automatically.

### Aliases (normalized in `SCR_Trait_Parse`)

| JSON alias | Canonical type |
|------------|----------------|
| `draw` | `draw_cards` |
| `healing` | `heal` |
| `add_to_hand` | `add` |
| `add_to_deck` | `add_deck` |
| `add_to_extra_deck` | `add_extra_deck` |
| `add_to_hand_tag`, `add_tag` | `add_hand_tag` |
| `buff_attack`, `attackIncrease` | `self_buff` |
| `destroy_target` | `destroy` |

### Supported trait types

| JSON `type` | What it does | Example JSON | Trait script |
|-------------|--------------|--------------|--------------|
| `draw` / `draw_cards` | Draw cards | `{ "type": "draw_cards", "amount": 2 }` | `SCR_Trait_Draw` |
| `attack` | Single-target attack | `{ "type": "attack", "amount": 4, "repeat": true, "recursion": 1 }` | `SCR_Trait_Attack` |
| `attack_all` | Hit all enemies (targeting step, not auto on play) | `{ "type": "attack_all", "amount": 2 }` | `SCR_Trait_AttackAll` |
| `heal` | Heal one ally | `{ "type": "heal", "amount": 5 }` | `SCR_Trait_Heal` |
| `heal_all` | Heal all allies | `{ "type": "heal_all", "amount": 2 }` | `SCR_Trait_HealAll` |
| `self_buff` | +ATK on the card's own monster slot | `{ "type": "self_buff", "amount": 2, "repeat": true, "recursion": 1 }` | `SCR_Trait_BuffAttack` |
| `buff` | +ATK on any player or enemy monster | `{ "type": "buff", "amount": 2 }` | `SCR_Trait_BuffAttack` |
| `destroy` | Destroy one enemy | `{ "type": "destroy", "amount": 1 }` | `SCR_Trait_Destroy` |
| `silence` | Silence enemy abilities | `{ "type": "silence", "amount": 2 }` | `SCR_Trait_Silence` |
| `add` | Add card id to **hand** | `{ "type": "add", "id": 7 }` | `SCR_Trait_AddHand` |
| `add_deck` | Add card id to **main deck** | `{ "type": "add_deck", "id": 1 }` | `SCR_Trait_AddDeck` |
| `add_extra_deck` | Add card id to **extra deck** | `{ "type": "add_extra_deck", "id": 11 }` | `SCR_Trait_AddDeck` |
| `add_hand_tag` | Tag search → pick card → **hand** | `{ "type": "add_hand_tag", "tags": ["Warrior"] }` | `SCR_Trait_AddTag` |
| `add_deck_tag` | Tag search → pick card → **main deck** | `{ "type": "add_deck_tag", "tags": ["Warrior"] }` | `SCR_Trait_AddTag` |
| `add_extra_deck_tag` | Tag search → pick card → **extra deck** | `{ "type": "add_extra_deck_tag", "tags": ["Wizard"] }` | `SCR_Trait_AddTag` |
| `conditions` | Spirit summon rules | See spirit example | `SCR_Conditions` |
| `none` | No ability (enemies) | `{ "type": "none" }` | — |

### Tag-search traits (`add_*_tag`)

Opens a scrollable picker listing all cards in `card_DB` that match **any** listed tag. Player clicks a card to add it to hand, main deck, or extra deck.

```json
{ "type": "add_deck_tag", "tags": ["Warrior"], "repeat": false, "recursion": 1 }
```

- **`tags`** — array of tag strings (or single string via `"tag": "Warrior"`)
- **`amount`** — optional; how many copies to add when a card is picked (default `1`)
- Matching is case-insensitive against each card's `tag` array

### `self_buff` vs `buff`

| Trait | Target | Typical use |
|-------|--------|-------------|
| `self_buff` | Own monster slot only | Weapon cultivated buff, monster self-buff on play |
| `buff` | Any living monster (player or enemy) | Support / curse effects; requires target pick |

Both increment `attack` and `attack_buff` on the target. Buff is shown as `ATK buff: +N` in battle preview; total column `Attack` includes weapon + buff + innate strike.

### Conditions requirements (spirit summon)

Used inside a `conditions` trait's `requirements` array:

| Requirement `type` | Fields | Meaning |
|--------------------|--------|---------|
| `min_turn` | `amount` | Can only summon on turn N+ |
| `sacrifice_monster` | `amount`, optional `slots` [1–5] | Sacrifice ally monsters |
| `sacrifice_tag` | `amount`, `tags` | Sacrifice monsters with matching tags |
| `destroy_weapons` | `amount` | Destroy equipped weapons |
| `discard_action` | `amount` | Discard action cards from hand |
| `discard_monster` | `amount` | Discard monster cards from hand |
| `discard_weapon` | `amount` | Discard weapon cards from hand |

**Aliases:** `sacrifice_ally` → `sacrifice_monster`, `destroy_weapon` → `destroy_weapons`, `turn_plus` / `turn_minimum` → `min_turn`, `sacrifice_tags` → `sacrifice_tag`.

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

Enemy preview with buff:
```
ATK buff: +2
Attack: 5
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
    { "collection": "enemySet_01", "enemyID": 2 }
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
│   ├── SCR_Trait_AddDeck      ← add_deck + add_extra_deck
│   └── SCR_Trait_AddTag       ← add_hand_tag + add_deck_tag + add_extra_deck_tag
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

1. Add JSON examples using a new `"type": "your_trait"` in `CardSet` / `MonsterSet`
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

Player ownership for deckbuilder is built in `SCR_TestCollection` from cards with `own` in the JSON at collection room start.

---

## Reference files

| Purpose | Example file |
|---------|----------------|
| Active player card set | `datafiles/CardSet01.json` |
| Legacy card formats | `datafiles/old/cardSet_01.json`, `cardSet_02.json` |
| Enemy set | `datafiles/MonsterSet01.json` |
| Elite enemies | `datafiles/MonsterSet03.json` |
| Battle wave | `datafiles/Battle01.json` |
| Load player cards | `scripts/LoadCollection/LoadCollection.gml` |
| Load enemies | `scripts/LoadMonsters/LoadMonsters.gml` |
| Load battle | `scripts/SCR_Battle_Load/SCR_Battle_Load.gml` |
| Trait parse / display | `scripts/SCR_Trait_Parse/SCR_Trait_Parse.gml` |
| Trait dispatch | `scripts/SCR_Trait_Execute/SCR_Trait_Execute.gml` |
| Tag-search traits | `scripts/SCR_Trait_AddTag/SCR_Trait_AddTag.gml` |
| Attack buff / preview totals | `scripts/SCR_Trait_BuffAttack/SCR_Trait_BuffAttack.gml` |
| Weapon attack rules | `scripts/SCR_Battle_Attack/SCR_Battle_Attack.gml` |
| Spirit conditions | `scripts/SCR_Conditions/SCR_Conditions.gml` |
| Collection / ownership | `scripts/SCR_TestCollection/SCR_TestCollection.gml` |
| Card preview UI | `scripts/SCR_DBD_Collection/SCR_DBD_Collection.gml` |
