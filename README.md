# ProjectCardGame

A card-battle deckbuilder built in GameMaker.

## Documentation

- **[Data & JSON guide](datafiles/README.md)** — card types, traits, weapons, spirits, enemies, battles, and how to add new trait types
- **Active card data:** `datafiles/CardSet01.json`

## Quick start

1. Open `ProjectCardGame.yyp` in GameMaker
2. Ensure JSON files in `datafiles/` are registered as **Included Files**
3. Player cards load from `LoadCollection.gml` → `CardSet01.json`
4. Enemies and battles load from `LoadMonsters.gml` and `SCR_Battle_Load` respectively

See the [data guide](datafiles/README.md) for full JSON field reference and trait examples.
