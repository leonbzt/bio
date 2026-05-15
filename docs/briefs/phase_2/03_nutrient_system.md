# Brief 03 — NutrientSystem (biome assignment + per-tick yields)

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` — sections 3 (`ResourceLedger`), 5 (NutrientSystem subscribes to `tick`, `organism_died`).
2. `scripts/data/biome_data.gd`.
3. `data/biomes/*.tres` (created in brief 02).
4. `scripts/systems/territory_system.gd` (created in brief 01) — for the live `_tiles` lookup.

## Goal
A `NutrientSystem` that:
1. Assigns one biome to every tile on the grid at run start (deterministic from `GameState.run_seed`).
2. Each tick, sums up the per-tick yield from owned tiles' biomes and credits `ResourceLedger`.

Biome assignment is fixed per run, so map "feel" is consistent.

## Outputs (create)
- `scripts/systems/nutrient_system.gd`
- Modification to `scenes/world/world.tscn` — add `NutrientSystem` node under `Systems`, after `TerritorySystem` (order matters for `_ready` execution).

## Implementation notes
- `Node`. Holds `var _biome_by_coord: Dictionary[Vector2i, BiomeData] = {}` and `var _biomes: Array[BiomeData] = []`.
- `_ready()`:
  - Load biomes from the **index file**, not via DirAccess (DirAccess does not work in exported Android builds — see `ARCHITECTURE.md` Content indices). Pattern:
    ```gdscript
    const BIOME_INDEX_PATH := "res://data/biomes/_index.tres"
    var index: BiomeIndex = load(BIOME_INDEX_PATH) as BiomeIndex
    if index == null:
        push_error("NutrientSystem: missing biome index")
        return
    _biomes = index.biomes
    _biomes.sort_custom(func(a, b): return a.id < b.id)
    ```
  - Connect `EventBus.run_loaded.connect(_on_run_loaded)`.
  - Connect `EventBus.tick.connect(_on_tick)`.
- `_on_run_loaded(_v)`:
  - Read or generate biome map. Layout: `GameState.run_save["biome_map"]` is a `Dictionary[String, String]` where keys are `"x,y"` strings and values are biome ids. If missing, generate from `run_seed` using a seeded `RandomNumberGenerator` and write back. **This adds a `biome_map` key to the save shape — see "Save schema bump" below.**
  - Populate `_biome_by_coord` from the map.
- `_on_tick(_delta)`:
  - For each coord in `TerritorySystem._tiles`, look up the biome and call `ResourceLedger.add(...)` for sunlight / nutrient / decay according to the biome's per-tick yields. Skip resources where yield is 0.
- Provide `func get_biome_at(coord: Vector2i) -> BiomeData` for other systems (UI tile inspect later).

## Save schema bump — needs a Claude review
This brief adds a new top-level key `biome_map` to `run_save`. That's a schema change. After implementation:

1. Bump `SaveSystem.SAVE_VERSION` from 1 to 2.
2. Add a migration arm in `SaveSystem.migrate()`:
   ```
   1:
       # v1 → v2: add empty biome_map; will be generated on first run_loaded.
       if old.has("run") and old["run"] is Dictionary:
           var run: Dictionary = old["run"]
           if not run.has("biome_map"):
               run["biome_map"] = {}
   ```
3. Add `"biome_map": {}` to `_build_default_save()` under `run`.

Once the patch is ready, paste the SaveSystem diff into Claude for review before merging. This is the second contract change to the save format.

## TerritorySystem access pattern
NutrientSystem needs to read `TerritorySystem._tiles`. Three options, in order of preference:
1. **Public read-only accessor** on TerritorySystem: `func get_owned_coords() -> Array[Vector2i]`. Add this.
2. ~~Direct private field access~~ — violates encapsulation, don't.
3. ~~Subscribe to `tile_colonized` / `tile_lost` and maintain a parallel set~~ — adds state-sync risk.

Use option 1. Add `get_owned_coords()` to TerritorySystem.

## Acceptance criteria
- [ ] Every tile on the grid has a biome after `run_loaded`.
- [ ] Biome assignment is identical across runs with the same `run_seed`.
- [ ] Owned tiles credit resources every tick according to their biome.
- [ ] No resource is credited for unowned tiles.
- [ ] HUD reflects sunlight/nutrients climbing once tiles are colonized.
- [ ] Save migration v1 → v2 passes (write a test in `tests/test_save_system.gd`: build a v1 save, run `migrate(_, 1)`, assert `biome_map` exists).
- [ ] No direct system imports beyond reading `TerritorySystem.get_owned_coords()`.

## Out of scope
- Biome variation by region (clustering, biome continents) — Phase 7 polish.
- Visual biome tinting on tiles — Phase 7.
