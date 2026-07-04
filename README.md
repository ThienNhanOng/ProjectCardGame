# ProjectCardGame

A card-battle deckbuilder built in GameMaker.

## Documentation

- **[Reference folder](reference/README.md)** — architecture UML, system summaries, how-to guides, content pipeline
- **[Data & JSON guide](datafiles/README.md)** — card types, traits, resources, weapons, spirits, enemies, battles, and how to add new trait types
- **[Map 1 markers guide](notes/Map1Markers%20guide/Map1Markers%20guide.txt)** — world map events, battles, replay pools, and card reward sets
- **Active card data:** `datafiles/Merc_starterdeck01.json`

## Quick start

1. Open `ProjectCardGame.yyp` in GameMaker
2. Ensure JSON files in `datafiles/` are registered as **Included Files**
3. Player cards load from `LoadCollection.gml` → `Merc_starterdeck01.json`
4. Enemies and battles load from `LoadMonsters.gml` and `SCR_Battle_Load` respectively

See the [data guide](datafiles/README.md) for full JSON field reference and trait examples.
