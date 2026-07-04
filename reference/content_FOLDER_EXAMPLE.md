# content/ — Example Folder Template

Copy this structure when authoring a new map region. Engine code stays in `scripts/`; everything player-facing goes here.

```
content/
└── maps/
    └── grasslands/
        ├── map_config.json
        ├── battleset.json
        └── events/
            ├── event_01_trail_start/
            │   ├── meta.json              ← order, label, replay_pool
            │   ├── dialog_pre.gml         ← source for script asset
            │   ├── dialog_post.gml
            │   ├── rewards.json
            │   ├── portraits/
            │   │   ├── hero.png
            │   │   └── guide.png
            │   └── backgrounds/
            │       └── grass_scene.png
            ├── event_02_crossroads/
            └── event_03_rocky_pass/
```

## meta.json example

```json
{
  "order": 1,
  "label": "Trail Start",
  "battle": "battle01",
  "battleset": "Grasslands_Battleset01_starter.json",
  "replay_pool": ["battle01", "battle02", "battle03"]
}
```

## Wiring today (until auto-import exists)

1. Copy dialog source → GameMaker script `dialog_Map1_Marker01_PreBattle`
2. Import PNGs → `sprites/Map/map1art/`, `sprites/characters/`
3. Copy JSON → `datafiles/` + Included Files
4. Marker Create → `eventmarker_*` calls

See [CONTENT_PIPELINE.md](CONTENT_PIPELINE.md) and [guides/HOWTO_Content_Pipeline.md](guides/HOWTO_Content_Pipeline.md).
