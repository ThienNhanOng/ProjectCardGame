# How to Use — Card System (traits, effects, targeting, status)

## Purpose

One pipeline turns `ability` / `actionType` / `enemyability` JSON into effects, and the **same effect functions run for
player cards and enemy monsters**. Nothing in the effect layer cares which side is acting.

## Main scripts (Scripts → CardSystem)

| Script | Role |
|--------|------|
| `scr_trait_parse` | `trait_NormalizeEntry`, `trait_GetFromCard` / `trait_GetFromMonster`, display text, trait classification |
| `scr_trait_execute` | `trait_Execute(trait, context)` — one switch for every trait type; add_cost chain |
| `scr_card_effects` | `card_Damage`, `card_Heal`, `card_Destroy`, `card_BuffAttack`, `card_Silence`, `card_Shroud`, `card_DrawCards`, `card_AddCard(source, zone, id)` |
| `scr_card_resources` | openzone / add_counter / remove_counter / board-turn effects, add_cost trait chain |
| `scr_card_targeting` | `unit_*` (a monster = side + slot) and `targets_*` lists |
| `scr_combat` | `combat_DamageUnit`, `combat_RemoveUnit` (every hit and death), attack stats, weapon data |
| `scr_status_effects` | `status_Apply / Has / Tick / Remove` — silence, shroud, timed attack buffs |
| `scr_card_costs` | play costs and tributes |
| `scr_card_conditions` | spirit summon requirements (sacrifice, discard, min turn, astral) |
| `scr_card_search_picker` | `add_*_tag` search picker |

Enemy-only scripts (Scripts → Enemy): `scr_enemy_ai` decides *what* and *who*; `scr_enemy_abilities` executes it
through `trait_Execute` / `card_*`; `scr_enemy_picker` is the "choose a card to discard" UI.

## Effects and target rules

Each normalized trait has `type` (the JSON name), `effect` and `target`:

```gml
var _t = trait_NormalizeEntry({ type: "heal", amount: 3, target: "all_allies" });
// _t.type == "heal_all", _t.effect == "heal", _t.target == "all_allies"
```

Target rules: `self`, `single_ally`, `all_allies`, `single_enemy`, `all_enemies`, `single_any`, `none`.
Single-target rules are picked by the player (click) or by `monsterAbility_PickTargets` (enemy AI); the others are
resolved inside `trait_Execute` (`trait_ResolveTargets`). `trait_GetOnPlayPick` / `trait_GetActionPick` say what the
player has to click. Full table: `datafiles/README.md` → *Targets*.

## Units, sources and targets

```gml
unit_Get(SIDE_ENEMY, 1);                 // living card in enemy slot 1, or undefined
unit_GetAliveSlots(SIDE_PLAYER);         // [0, 2, ...]
unit_PickRandom(SIDE_PLAYER);            // random living slot or -1

var _src = effect_Source(SIDE_PLAYER, _slot);     // who acts (slot -1 for action cards)
targets_Single(SIDE_ENEMY, 2);                     // one target
targets_AllAllies(_src);                           // every living unit on the source's side
targets_AllOpponents(_src);                        // every opposing unit (empty player board → the player)
targets_AttackDefender(SIDE_PLAYER, _preferred);   // attack rules: dead target → random monster → player
```

The player's own life total is the unit `unit_Ref(SIDE_PLAYER, UNIT_HERO)`.

## Using effects directly

```gml
card_Heal(_src, targets_Single(SIDE_PLAYER, 0), 3);     // heal
card_Heal(_src, targets_AllAllies(_src), 3);            // heal_all
card_Damage(_src, targets_Single(SIDE_ENEMY, 1), 4);    // attack
card_Damage(_src, targets_AllOpponents(_src), 2);       // attack_all
status_Apply(unit_Get(SIDE_ENEMY, 0), STATUS_SILENCE, 2);
```

## Running a JSON trait

```gml
var _trait = trait_NormalizeEntry({ type: "heal", amount: 3 });
var _ctx = trait_CreateContext(effect_Source(SIDE_ENEMY, _slot), targets_Single(SIDE_ENEMY, _ally));
trait_Execute(_trait, _ctx);
```

`trait_ExecuteOnPlay(trait, slot)` runs the traits that need no target when a player card is played.

## Runtime flow

```
JSON ability → trait_NormalizeEntry → (player: click targeting | enemy: scr_enemy_ai picks targets)
             → trait_Execute(trait, context) → card_* effect → combat_* / status_*
```

Player targeting: `scr_battle_targeting` sets `target_mode`; a click calls `battle_ResolvePendingTrait`, which runs the
pending trait from whichever card started it (monster on-play, weapon on-play or action card).

## Adding things

- **New ability from existing effects** — JSON only: an effect type plus a `"target"`.
- **New trait type** — its effect + default target in `trait_GetTypeRule`, a `case` in `trait_Execute`, and display
  text in `trait_GetBaseDisplayText`. No new script needed.
- **New effect** — one `card_YourEffect(source, targets, amount)` in `scr_card_effects`.
- **New status** (poison, burn, regen…) — one case in each switch of `scr_status_effects`.
- **New enemy ability target rule** — a picker in `scr_enemy_ai`, used from `monsterAbility_RunEffect`.

## Common pitfalls

- A trait type in JSON with no `case` in `trait_Execute` silently does nothing.
- `trait_Execute` only executes; it never chooses targets. Pass targets in the context.
- Board-position effects (`openzone`, `add_counter`, `no_board_expire`, …) use `context.source.slot`.
