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



**Active set:** `datafiles/Merc_starterdeck01.json` (loaded in `LoadCollection.gml`)

Test sets (`MonsterTestset`, `TestActionset`, `TestWeaponset`) remain in the project but are not loaded unless you add them back to `LoadCollection.gml`.



### Card types



| `type` | Where traits go | Notes |

|--------|-----------------|-------|

| `monster` | `ability` | Placed on player monster board slots |

| `weapon` | `ability` | Needs `attack`; see [Weapons](#weapons) |

| `action` | `actionType` | Placed in the action slot; play cost on card root — see [Ability — card cost & tributes](#ability--card-cost--tributes) |

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

| `cost` | Any playable card | Single play cost (resources or tribute). See [Ability — card cost & tributes](#ability--card-cost--tributes) |

| `costs` | Any playable card | Array of cost entries (resources + tributes combined). See [Ability — card cost & tributes](#ability--card-cost--tributes) |

| `attack` | Weapon, spirit | Weapon strike value; spirit innate single-target strike (optional) |

| `equip` | Weapon | `true` for equippable weapons |

| `attackRecursion` | Weapon | Attacks allowed per turn in a column (default `1`). See [Weapons](#weapons) |

| `effectRecursion` | Weapon | Non-attack repeatable effects per turn (default `1`) |

| `ability` | Monster, weapon, spirit | Trait array (see [Traits](#traits-in-json)). Cost/tribute traits: [Ability — card cost & tributes](#ability--card-cost--tributes) |

| `actionType` | Action | Trait array (see [Traits](#traits-in-json)) |



### Ownership & deck limits



- **Card pool (`card_DB`)** — all card definitions from loaded JSON files. Every card in the game lives here.

- **Player collection (`global.player_collection`)** — cards the player owns (`owned` count). Deckbuilder only lists these.

- **`own`** — at first game boot, `collection_GrantFromDatabase()` grants that many copies into the player collection. Omit `own` for cards that must be earned (map markers, traits, etc.).

- Cards **without** `own` exist in the card pool only until earned via map marker rewards or other grants.

- **Deck copy caps** (even if `own` is higher):

  - `monster`, `weapon`, `action` → max **4** per deck

  - `spirit` — extra deck only (no main-deck cap)

- **Deck shuffle** — each card added in deckbuilder shuffles `selected_deck`; each `deck_AddCard` during battle shuffles the draw pile

- **Deck list UI** — the collection **YOUR DECK** panel scrolls with the mouse wheel when entries pass **y = 550**



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



**Monster (resource & zone effects)**

```json

{

  "id": 1021,

  "own": 2,

  "name": "TestMonster17_(OpenZone)",

  "type": "monster",

  "tag": ["Test"],

  "sprite": "SPR_Monsterplaceholder",

  "health": 10,

  "ability": [

    { "type": "openzone", "amount": 1, "repeat": false, "recursion": 1 }

  ]

}

```



**Monster (play cost on card)**

```json

{

  "id": 1024,

  "own": 2,

  "name": "TestMonster20_(Cost2)",

  "type": "monster",

  "tag": ["Test"],

  "sprite": "SPR_Monsterplaceholder",

  "health": 10,

  "cost": 2,

  "ability": []

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



**Weapon (on-equip effect + attack)**

```json

{

  "id": 3011,

  "own": 4,

  "name": "TestWeapon11_(AddDeck)",

  "type": "weapon",

  "tag": ["Test"],

  "sprite": "SPR_Weaponplaceholder",

  "equip": true,

  "attack": 1,

  "ability": [

    { "type": "add_deck", "id": 1001, "repeat": false, "recursion": 1 }

  ]

}

```



`add_deck` fires when equipped; click the column to attack.



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



Omit the `conditions` entry (or use `"ability": []`) for a spirit with no summon requirements. Spirit **play/summon costs** and tribute discards use the same `cost` / `costs` rules as other cards — see [Ability — card cost & tributes](#ability--card-cost--tributes).



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



- **Effects (on equip)** — non-attack traits in `ability` fire when the weapon is placed, same as monster on-play: instant effects first, then targeting if needed (`heal`, `destroy`, `buff`, tag pickers, etc.). `add_cost` is instant and does not use targeting.

- **Effects (repeatable)** — traits with `repeat: true` also fire at **player turn start** via `battle_RefreshWeaponRepeatableEffects()`, up to each trait's `recursion` (capped by `effectRecursion` where applicable).

- **Attack** — click the column (monster or weapon slot) to strike. Uses `attack` + optional `attack` trait. Uses `attackRecursion` for uses per turn.



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



## Resources & costs



Battle **Resources** are shown on the HUD (red counter). Default pool is **10 / 10**.



| Behavior | Detail |

|----------|--------|

| Turn start | Current resources refill to max |

| Turn end | Temporary `add_counter` boosts are cleared |

| Monster destroyed | That slot's `add_counter` and `remove_counter` effects are removed |



Card **play cost** (`cost` / `costs` on the card JSON), **tribute discards**, and ability traits that modify generated card cost (`add_cost`, `add_hand_with_cost`) are documented under [Ability — card cost & tributes](#ability--card-cost--tributes) in the Traits section.



### Resource traits (battle pool)



| JSON `type` | Function | Notes |

|-------------|----------|-------|

| `add_counter` | `add_counter(amount, slot)` | Temporary **current** boost this turn (can exceed max, e.g. 16/10). Cleared at turn end and when source leaves board |

| `remove_counter` | `remove_counter(amount, slot)` | Reduces **max** while source monster stays on board. Restored when source is destroyed |



**Aliases:** `increase_counter` → `add_counter`, `decrease_counter` → `remove_counter`



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

| `amount` | Numeric strength (player cards). See [Ability — card cost & tributes](#ability--card-cost--tributes) for `add_cost` |

| `value` | Alias for `amount` (enemies often use this) |

| `repeat` | `true` = can trigger again each turn (weapons at turn start; action slot once per play cycle) |

| `recursion` | Times per turn when `repeat` is `true` (minimum `1`) |

| `uses_per_turn` | **Legacy** — treated as `repeat: true` + `recursion: N` |

| `id` / `card_id` | For `add`, `add_deck`, `add_extra_deck` — target card id in DB |

| `tags` / `tag` | For tag-search traits — string or array of tag strings |

| `indeckTag` / `indeckTags` | For tag-search traits — search **current battle deck** (or extra deck) instead of full `card_DB` |

| `cost` | On `add_hand_with_cost` — cost applied to the picked card |

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

| `increase_counter` | `add_counter` |

| `decrease_counter` | `remove_counter` |

| `addtohandwithcost`, `add_hand_with_cost` | `add_hand_with_cost` |



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

| `add_hand_with_cost` | Tag search → pick card → **hand** + apply cost | `{ "type": "add_hand_with_cost", "cost": 3 }` | `SCR_Trait_AddTag` |

| `openzone` | Unlock hidden monster slots 3–4 while source is on board | `{ "type": "openzone", "amount": 1 }` | `SCR_Trait_OpenZone` |

| `add_counter` | +current resources this turn | `{ "type": "add_counter", "amount": 2 }` | `SCR_Trait_Resources` |

| `remove_counter` | −max resources while source lives | `{ "type": "remove_counter", "amount": 3 }` | `SCR_Trait_Resources` |

| `add_cost` | Append cost to cards added in the same ability chain | `{ "type": "add_cost", "amount": -2 }` — see [Ability — card cost & tributes](#ability--card-cost--tributes) | `SCR_Trait_Resources` |

| `conditions` | Spirit summon rules | See spirit example | `SCR_Conditions` |

| `none` | No ability (enemies) | `{ "type": "none" }` | — |



### Ability — card cost & tributes



Play cost is declared on the **card root** (`cost` / `costs`). **Ability** traits can add cards or change the cost on cards created during that ability (`add`, `add_*_tag`, etc.).



#### Play cost (`cost` / `costs`)



Any card played from hand (monster, weapon, action) can declare costs. Payment runs on drag-drop play (`SCR_Card_Cost`, `SCR_DragDrop_Init`).



```json

{ "cost": 2 }

```



```json

{

  "costs": [

    { "amount": 2 },

    { "tag": "Warrior", "amount": 1 },

    { "id": 1001, "amount": 1 },

    { "type": "monster", "amount": 1 }

  ]

}

```



| Cost entry | At play time |

|------------|--------------|

| `{ "amount": N }` only | Spend **N resources** from the HUD pool |

| `{ "amount": -N }` | Reduces resource cost (usually from `add_cost` on a generated card). Total resource cost is clamped to **0** |

| `{ "tag": "X", "amount": N }` | **Discard** (tribute) **N** hand cards whose `tag` includes `X` |

| `{ "id": N, "amount": M }` | **Discard** **M** hand cards with that card **id** |

| `{ "type": "monster", "amount": N }` | **Discard** **N** hand cards of that card type (`monster`, `weapon`, `action`, …) |



Legacy single `"cost": N` is normalized into the `costs` array at load time. Multiple entries in `costs` are all paid together (resources + discards).



#### Example — discount cards added by `ability`



**Inspired Adventurer** adds two copies of Basic Strike, then applies a cost reduction via `add_cost`:



```json

{

  "id": 5,

  "name": "Inspired Adventurer",

  "type": "monster",

  "health": 5,

  "ability": [

    { "type": "self_buff", "amount": 1, "repeat": false, "recursion": 1 },

    { "type": "add", "id": 7, "repeat": false, "recursion": 1 },

    { "type": "add", "id": 7, "repeat": false, "recursion": 1 },

    { "type": "add_cost", "amount": -2, "repeat": false, "recursion": 1 }

  ]

}

```



Basic Strike has `"cost": 2`. Each copy added to hand gets `{ "amount": -2 }` appended, so both play for **0 resources**. No target picker — `add_cost` only affects cards from earlier traits in the same `ability` / `actionType` list.



#### `add_cost` (chain modifier)



| JSON `type` | Script | Summary |

|-------------|--------|---------|

| `add_cost` | `SCR_Trait_Resources` | Append a cost entry to cards added in the same ability chain |



`add_cost` does **not** open a target picker. It modifies cards created by other traits on the **same card** during the same ability resolution (monster on-play, weapon on-play, or action slot).



**Applies to cards from:**



- `add` — cards added directly to hand

- `add_deck` / `add_extra_deck` — cards added to deck piles (cost applies when drawn into hand)

- `add_hand_tag` / `add_deck_tag` / `add_extra_deck_tag` — cards chosen from the tag/search picker



**Order:** Traits run top-to-bottom in `ability` / `actionType`. `add_cost` applies to all chain-added cards from **earlier** traits. If it appears **before** a search/add trait, the cost is **queued** and applied when the picker finishes or the later add resolves.



```json

{ "type": "add_cost", "amount": -2 }

{ "type": "add_cost", "tag": "Mercenary", "amount": 1 }

{ "type": "add_hand_tag", "tags": ["Warrior"] },

{ "type": "add_cost", "amount": 1 }

```



| Field | Meaning |

|-------|---------|

| `amount` | Resource cost change. Positive adds resources required; **negative reduces** resource cost |

| `tag` / `tags` | Optional — append a **tribute discard** cost (`amount` × cards matching tag) |

| `id` / `card_id` | Optional — append a tribute discard for a specific card id |



#### `add_hand_with_cost`



Tag search → pick one card → add to **hand** and apply a fixed positive resource cost using the trait's **`cost`** field (not `amount`). Separate from `add_cost`; see trait table above.



**Alias:** `addtohandwithcost` → `add_hand_with_cost`



### Tag-search traits (`add_*_tag`)



Opens a scrollable picker listing all cards in `card_DB` that match **any** listed tag. Player clicks a card to add it to hand, main deck, or extra deck.



```json

{ "type": "add_deck_tag", "tags": ["Warrior"], "repeat": false, "recursion": 1 }

```



- **`tags`** — array of tag strings (or single string via `"tag": "Warrior"`)

- **`amount`** — optional; how many copies to add when a card is picked (default `1`)

- Matching is case-insensitive against each card's `tag` array



### `indeckTag` search



Same picker UI as `add_*_tag`, but the card list is built from cards **already in your battle deck** (main deck for hand/deck destinations; extra deck for `add_extra_deck_tag`).



```json

{ "type": "add_deck_tag", "indeckTag": ["Test"], "repeat": false, "recursion": 1 }

```



Use `tags` to search the full card database; use `indeckTag` to search only what is in the current run deck.



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

| `discard_tag` | `amount`, `tags` or `tag`, optional `types` / `card_types` / `card_type` | Discard hand cards with matching tag(s); optional type filter (`monster`, `action`, `weapon`, `any`, or a mix) |

| `astral` | *(none)* | Metadata only — not saved to extra deck after battle (temporary spirit) |



**Aliases:** `sacrifice_ally` → `sacrifice_monster`, `destroy_weapon` → `destroy_weapons`, `turn_plus` / `turn_minimum` → `min_turn`, `sacrifice_tags` → `sacrifice_tag`, `discard_tags` → `discard_tag`.



**`discard_tag` — discard tagged cards from hand**



Discard cards from the player's hand that match one or more tags. Optionally restrict by card type (`monster`, `action`, `weapon`, or a mix). Omit the type fields (or use `"any"`) to allow any card type with the tag.



```json

{ "type": "discard_tag", "amount": 2, "tags": ["Mercenary"], "types": ["monster", "action"] }

{ "type": "discard_tag", "amount": 1, "tag": "Warrior", "card_type": "weapon" }

{ "type": "discard_tag", "amount": 1, "tags": ["Spirit"] }

**`astral` — temporary extra-deck spirit**

```json
{ "type": "astral" }
```

Also allowed as a top-level card flag: `"astral": true`. Astral cards can be added mid-battle (e.g. `add_extra_deck`) but are **removed when the battle ends** — they are not written to `battle_extra_deck_source`. If an astral spirit dies on board, it does **not** reduce your collection owned count.

```



| Field | Purpose |

|-------|---------|

| `tags` / `tag` | Tag(s) the discarded card must have (same matching rules as `sacrifice_tag`) |

| `types` / `card_types` / `card_type` | Optional type filter; array or single string. `special_monster` counts as `monster`. Omit for any type. |



During summon the player clicks matching hand cards to discard them. This step cannot be cancelled (same as `discard_action`, `discard_monster`, and `discard_weapon`).



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

│   ├── SCR_Trait_AddTag       ← add_hand_tag + add_deck_tag + add_extra_deck_tag + add_hand_with_cost

│   ├── SCR_Trait_OpenZone     ← openzone

│   └── SCR_Trait_Resources    ← add_counter + remove_counter + add_cost

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



Player ownership for deckbuilder is built in `SCR_PlayerCollection` from cards with `own` in the JSON at collection room start.



---



## Map marker card rewards (world map)



Earnable cards can be granted when the player **first clears** a world-map battle marker. Replays do not grant cards again (only battles from the marker's replay pool).



Configure rewards in each marker object's **Create** event (after `eventmarker_apply_config`). Full walkthrough: [`notes/Map1Markers guide/Map1Markers guide.txt`](../notes/Map1Markers%20guide/Map1Markers%20guide.txt).



### API



```gml
eventmarker_apply_reward(gift_count, randomize, rewardset?);
eventmarker_reward_add(card_id, chance, collection?, once?);
```



| Function / param | Meaning |

|------------------|---------|

| `gift_count` | How many cards to grant (number of picks from the set) |

| `randomize` | `true` = weighted roll each pick · `false` = entries in order |

| `rewardset` | Optional array or `"id:chance,..."` string; omit to use `reward_add` lines |

| `card_id` | Card id from `card_DB` |

| `chance` | Weight / percent (`20` = 20% when entries sum to ~100) |

| `collection` | Optional JSON collection name if ids overlap across files |

| `once` | `true` = one-time reward — removed from all reward pools after obtained once |



**One-time reward (never drops again after obtained):**

```gml
eventmarker_apply_reward(1, true);
eventmarker_reward_add(8, 100, "", true);
// or JSON: { "id": 8, "chance": 100, "once": true }
// or string: "8:100::once"
```



### Examples



**Manual lines (recommended):**

```gml
eventmarker_apply_reward(2, true);
eventmarker_reward_add(8, 20);
eventmarker_reward_add(9, 10);
eventmarker_reward_add(12, 70);
```

Grants **2** cards. Each pick rolls 20% / 10% / 70% from the set.



**Fixed card #7, once:**

```gml
eventmarker_apply_reward(1, true);
eventmarker_reward_add(7, 100);
```



**One-liner string:**

```gml
eventmarker_apply_reward(1, true, "8:20,9:80");
```



**Array preset:**

```gml
eventmarker_apply_reward(3, true, [
    { id: 1, chance: 25 },
    { id: 2, chance: 25 },
    { id: 3, chance: 25 },
    { id: 4, chance: 25 }
]);
```

Grants **3** cards — each pick rolls independently.



**Non-random (list order):**

```gml
eventmarker_apply_reward(2, false);
eventmarker_reward_add(8, 100);
eventmarker_reward_add(9, 100);
```

First pick → card 8, second → card 9 (chance values ignored).



### Rules



- Card ids must exist in `card_DB`.

- `gift_count = 0` or empty reward set → battle-only marker (no card).

- **First clear only** — not on replays.

- Implementation: `scripts/SCR_EventMaker/SCR_EventMaker.gml`, `scripts/SCR_WorldMap_Progress/SCR_WorldMap_Progress.gml`



---



## Reference files



| Purpose | Example file |

|---------|----------------|

| Active merc starter set | `datafiles/Merc_starterdeck01.json` |

| Monster effect test set | `datafiles/test set/MonsterTestset.json` |

| Active action test set | `datafiles/test set/TestActionset.json` |

| Active weapon test set | `datafiles/test set/TestWeaponset.json` |

| Legacy player card set | `datafiles/CardSet01.json` |

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

| Map marker rewards | `scripts/SCR_EventMaker/SCR_EventMaker.gml` |

| Resources HUD & pool | `scripts/SCR_Battle_Resources/SCR_Battle_Resources.gml` |

| Card play costs | `scripts/SCR_Card_Cost/SCR_Card_Cost.gml` |

| Resource traits | `scripts/SCR_Trait_Resources/SCR_Trait_Resources.gml` |

| Collection / ownership | `scripts/SCR_PlayerCollection/SCR_PlayerCollection.gml` |

| Card preview UI | `scripts/SCR_DBD_Collection/SCR_DBD_Collection.gml` |


