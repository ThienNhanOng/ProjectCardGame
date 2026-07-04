# How to Use — Content Pipeline

## Purpose

Organize **game content** separately from **engine tools**. You author levels in `content/`; the engine in `scripts/`/`objects/` stays reusable.

## Main scripts / folders

| Path | Role |
|------|------|
| `content/maps/<region>/` | Per-map events, dialog sources, art |
| `datafiles/` | Runtime JSON bundle (today) |
| `sprites/Map/`, `sprites/characters/` | Imported PNGs |
| Marker `Create_0.gml` | Wires content → engine |

## Responsibilities

- One folder per event with dialog, portraits, backgrounds, rewards
- Battlesets and enemy collections per region
- No battle logic in content — only data + script text

## Dependencies

World map, dialog, bootstrap data systems.

## Public API (authoring contract)

```
content/maps/grasslands/events/event_01_trail_start/
  dialog_pre.gml      → import as script function
  dialog_post.gml
  portraits/
  backgrounds/
  rewards.json
```

## Initialization order

1. Create content folder for event
2. Import sprites + register JSON in GameMaker
3. Write script function returning `dialog_*` entry array
4. Wire marker Create event

## Runtime flow

```
content → GameMaker assets → marker Create → player interacts → engine runs
```

## Example usage

```gml
// OBJ_Map1_Marker01/Create_0.gml  (wiring layer)
eventmarker_apply_config(1, "Trail Start", "battle01",
    "Grasslands_Battleset01_starter.json", "battle01,battle02,battle03");
eventmarker_set_dialog_pre(dialog_Map1_Marker01_PreBattle);
eventmarker_set_dialog_pre_once(true);
eventmarker_apply_reward(1, true);
eventmarker_reward_add(8, 100, "", true);
```

Content source for `dialog_Map1_Marker01_PreBattle` should eventually live in:
`content/maps/grasslands/events/event_01_trail_start/dialog_pre.gml`

## Common pitfalls

- Duplicating content in `datafiles/` and `content/` without a sync process
- Hardcoding story strings inside `SCR_Battle_*` instead of dialog/marker scripts

## Future expansion

- CLI tool: `scaffold event --map grasslands --id 02`
- Single manifest JSON per map listing all events and asset paths

## Parent / child

Content folders are not GameMaker objects. Marker objects inherit from `OBJ_EventMarker` — see World Map guide.
