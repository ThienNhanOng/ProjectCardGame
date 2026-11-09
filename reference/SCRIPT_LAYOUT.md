# Script Layout

60 scripts, grouped by system. Each script groups related functions (no one-function-per-file scripts).

```
scripts/
├── Core/            scr_data_json (data_ReadJsonFile), scr_debug, scr_room_goto
├── Data/            scr_card_data       card DB loading, definitions, runtime copies, card_Is*Type / card_HasAnyTag / card_IsAstral
│                    scr_monster_data    enemy DB loading, monster_CreateInstance
│                    scr_player_collection  owned cards, rewards
├── CardSystem/      shared by player AND enemy
│   ├── Core/     scr_trait_parse (JSON → trait {type, effect, target}), scr_trait_execute (trait_Execute),
│   │             scr_card_targeting (unit_* / targets_*)
│   ├── Effects/  scr_card_effects (card_Damage / Heal / Destroy / BuffAttack / Silence / Shroud / DrawCards / AddCard),
│   │             scr_combat, scr_status_effects, scr_card_resources (counters, zones, board turns, add_cost chain)
│   └── Cards/    scr_card_costs, scr_card_conditions, scr_card_search_picker, scr_card_draw
├── Battle/          player-side flow (runs on OBJ_BattleManager)
│   ├── scr_battle_manager     Create / Step / Draw entry points
│   ├── scr_battle_session     deck sources between fights, battle wave configs
│   ├── scr_battle_turn        player turn, end turn, enemy phase sequencing, board lifespan
│   ├── scr_battle_play        playing cards: on-play traits, action cards, pending targeted trait
│   ├── scr_battle_targeting   click targeting (target_mode)
│   ├── scr_battle_attack      column (monster + weapon) attacks
│   ├── scr_battle_resources, scr_battle_player_health, scr_battle_spirit_shuffle, scr_battle_log, scr_battle_ui
│   ├── Board/  scr_board_setup, scr_board_slots, scr_board_draw, scr_board_dragdrop
│   ├── Deck/   scr_deck, scr_deck_draw, scr_deck_extra, scr_deck_picker
│   └── Hand/   scr_hand, scr_hand_draw
├── Enemy/           scr_enemy_ai (decisions + target choice), scr_enemy_abilities (execution via shared effects),
│                    scr_enemy_picker (player choices during enemy turn), scr_monster_manager (wave queue),
│                    scr_monster_draw, scr_monster_anim
├── Collection/      deck builder room: scr_deckbuilder_setup / _collection / _draw / _input / _extradeck, scr_collection_cardslot
├── WorldMap/        scr_worldmap_config / _controller / _progress / _events, scr_worldmap_graph (node travel + random side branches)
└── Dialog/          scr_dialog_system / _builder / _text, Content/ scr_dialog_map1, scr_dialog_map2
```

## Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| Script asset | `scr_<area>_<topic>` | `scr_card_effects` |
| Function | `<area>_<Action>` | `card_Heal`, `unit_Get`, `status_Apply`, `battle_EndTurn` |
| Object-event entry point | `SCR_<Object>_<Event>` | `SCR_Battle_Step`, `SCR_Hand_Draw` |
| Side constants | `SIDE_PLAYER`, `SIDE_ENEMY`, `UNIT_HERO` | |

## How player and enemy share logic

```
player click ─┐                                   ┌─ combat_DamageUnit / combat_RemoveUnit
              ├─> trait_Execute(trait, context) ──> card_* effect ─┤
enemy AI ─────┘    context = source + targets       └─ status_Apply / unit_Get ...
```

- **Who acts** is `effect_Source(side, slot)`; **who is hit** is a list of `unit_Ref(side, slot)`.
- Heal and heal_all are the same `card_Heal` with one target or `targets_AllAllies(source)`.
- Attack and attack_all are the same `card_Damage` with one target or `targets_AllOpponents(source)`;
  every hit — weapon, action card, spirit, enemy — ends in `combat_DamageUnit`.
- Enemy AI only picks abilities and targets (`scr_enemy_ai`); it never applies effects itself.

## Adding content

- **New card** — JSON only (`datafiles/`), using existing trait types.
- **New ability** — usually JSON only: an effect plus a `"target"` (see `datafiles/README.md` → *Targets*).
- **New trait type** — effect + default target in `trait_GetTypeRule`, a `case` in `trait_Execute`, display text in `scr_trait_parse`.
- **New effect** — one `card_<Effect>(source, targets, amount)` in `scr_card_effects`.
- **New status** (poison, burn, regen …) — one case in each switch in `scr_status_effects`, ticked from its turn hooks.
- **New enemy** — JSON only; a custom animation fills in a hook in `scr_monster_anim`.
- **New enemy ability with special targeting** — a target picker in `scr_enemy_ai`, used from `monsterAbility_RunEffect`.
