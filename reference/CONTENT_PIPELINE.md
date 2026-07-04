# Content Pipeline — Levels, Dialog, and Event Assets

## Purpose

Separate **game content** (what players experience per level/event) from **engine tools** (everything else in this project). The engine loads and runs content; authors produce content in a dedicated folder tree.

## Recommended `content/` layout

```
content/
├── maps/
│   ├── grasslands/
│   │   ├── map_config.json          ← unlock order, fallback labels
│   │   ├── battleset.json           ← battle01, battle02, waves
│   │   ├── room/                    ← optional: room export notes / layout refs
│   │   └── events/
│   │       ├── event_01_trail_start/
│   │       │   ├── dialog_pre.gml   ← or .txt script source → compiled script
│   │       │   ├── dialog_post.gml
│   │       │   ├── portraits/       ← event-specific dialog art
│   │       │   ├── backgrounds/     ← dialog scene images
│   │       │   └── rewards.json     ← card reward pool for first clear
│   │       ├── event_02_crossroads/
│   │       └── …
│   └── map2_region/
├── cards/
│   └── merc_starterdeck01.json
├── enemies/
│   └── grasslands_enemies.json
└── shared/
    ├── ui/
    └── placeholders/
```

## What is content vs tool

| Content (authoring) | Tool (engine — this repo) |
|---------------------|---------------------------|
| Dialog scripts per event | `SCR_Dialog_System`, `SCR_Dialog_Builder` |
| Marker config per map | `SCR_EventMaker`, `SCR_WorldMap_Config` |
| Battle wave JSON | `SCR_Battle_Load`, `SCR_Monster_Init` |
| Card / enemy JSON | `LoadCollection`, `LoadMonsters`, trait scripts |
| Map background PNGs | Room background layers, sprite assets |
| Event portrait images | `SPR_Dialog_*` sprites, draw pipeline |

## How content connects to engine today

1. **Map markers** — `OBJ_Map1_MarkerXX` Create events call `eventmarker_apply_config()` with battleset + battle ids.
2. **Dialog** — marker Create calls `eventmarker_set_dialog_pre(my_dialog_func)`.
3. **JSON** — `datafiles/` holds included files; GameMaker copies them to output at build.
4. **Sprites** — imported into `sprites/` per map folder (`map1art`, `characters`).

## Migration path (future)

- Point `worldmap_LoadMapConfig()` at `content/maps/grasslands/map_config.json`
- Auto-generate marker Create code from `content/maps/.../events/event_XX/`
- Import dialog `.gml` / text scripts from content folder into script assets
- Keep `datafiles/` as runtime bundle or symlink from `content/`

## Dependencies

- World map system (`SCR_WorldMap_*`, `SCR_EventMaker`)
- Dialog system (`SCR_Dialog_*`)
- Data layer (`LoadCollection`, `LoadMonsters`)
- GameMaker Included Files + sprite import

## Common pitfalls

- Putting battle logic in content JSON instead of trait definitions
- Duplicating dialog in both `content/` and script assets without a single source of truth
- Forgetting to register new JSON/sprites as Included Files in the `.yyp`

## Future expansion

- Hot-reload content folder in dev builds
- Editor tool that scaffolds `content/maps/.../events/event_XX/` from a template
- Per-event asset bundles loaded only when the player enters that map region
