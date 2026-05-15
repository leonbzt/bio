# Brief 04 — Kingdom-aware GrowthSystem

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/systems/growth_system.gd` — currently hardcodes `pioneer_grass`.
2. `data/species/_index.tres` (created in brief 03).
3. `scripts/systems/territory_system.gd` — post-refactor, has `get_surface_owned_coords` / `get_subsurface_owned_coords`.

## Goal
On `run_started` (or `run_loaded`), load the appropriate species for the current kingdom, and tick the appropriate layer:
- Plantae: yield biomass per surface-owned tile.
- Fungi: yield decay + spores per subsurface-owned tile.

## Outputs (modify)
- `scripts/systems/growth_system.gd` — full rewrite.

## Implementation

### Constants
```gdscript
const SPECIES_INDEX_PATH := "res://data/species/_index.tres"

# Mapping from kingdom to starter species. Phase 5 has one each.
const STARTER_SPECIES_BY_KINGDOM := {
    &"plantae": &"pioneer_grass",
    &"fungi": &"mycelium_thread",
}
# TODO Phase 6+: kingdom config moves into KingdomData.
```

### State
```gdscript
var _all_species: Dictionary[StringName, SpeciesData] = {}
var _active_species: SpeciesData = null
var _trait_modifier_sum: Dictionary[StringName, float] = {}    # cached sum of all trait modifiers

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _nutrients: Node = get_node("../NutrientSystem")
```

### `_ready()`
1. Load `SPECIES_INDEX_PATH`; populate `_all_species` keyed by id.
2. Connect:
   - `EventBus.tick.connect(_on_tick)`
   - `EventBus.run_loaded.connect(_on_run_loaded)`
   - `EventBus.run_started.connect(_on_run_started)`
3. Catch-up per § 7a.

### `_on_run_loaded(_v)` and `_on_run_started(kingdom_id)`
Both call a helper `_select_active_species()` that:
1. Reads `GameState.current_kingdom_id`.
2. Looks up `STARTER_SPECIES_BY_KINGDOM[kingdom_id]`.
3. Sets `_active_species` and recomputes `_trait_modifier_sum`.
4. If kingdom_id is unknown, logs and clears `_active_species` (no growth this run).

### `_on_tick(_delta)`
```gdscript
if _active_species == null:
    return

var coords: Array[Vector2i]
var is_fungi: bool = _active_species.kingdom_id == &"fungi"
if is_fungi:
    coords = _territory.get_subsurface_owned_coords(&"fungi")
else:
    coords = _territory.get_surface_owned_coords(_active_species.kingdom_id)

if coords.is_empty():
    return

# Apply each resource in the species's tick_yield, scaled by biome + traits + meta modifiers.
var meta_mult: float = _get_meta_growth_multiplier()    # phase 4 efficient_photosynthesis still applies — plantae only
if is_fungi:
    meta_mult = 1.0    # phase 4 meta nodes are plantae-flavored; revisit when fungi gets its own nodes

for resource_id in _active_species.tick_yield.keys():
    var base_yield: float = float(_active_species.tick_yield[resource_id])
    var total: float = 0.0
    for coord in coords:
        var multiplier: float = 1.0
        if resource_id == &"biomass":
            var biome: BiomeData = _nutrients.get_biome_at(coord)
            if biome != null:
                multiplier *= biome.sunlight_per_tick
            multiplier *= (1.0 + _trait_modifier_sum.get(&"biomass_per_tile", 0.0))
            multiplier *= meta_mult
        elif resource_id == &"decay":
            multiplier *= (1.0 + _trait_modifier_sum.get(&"decay_per_tile", 0.0))
            # Phase 5+: corpse-bonus could be applied here per-coord by querying CorpseSystem
        elif resource_id == &"spores":
            multiplier *= (1.0 + _trait_modifier_sum.get(&"spore_per_tile", 0.0))
        total += base_yield * multiplier
    if total > 0.0:
        ResourceLedger.add(resource_id, total)
```

### `_trait_modifier_sum` rebuild
Whenever `_active_species` changes, walk `base_traits` and sum each modifier key into `_trait_modifier_sum`. Reset to empty before summing.

## Acceptance criteria
- [ ] Plantae run: per-tile biomass yield matches Phase 2/3 behavior exactly (verifies regression).
- [ ] Fungi run: surface tiles do NOT yield biomass. Subsurface-fungi tiles yield decay and spores. Plantae's own yield does not double-fire.
- [ ] Switching kingdom across a prestige (plantae → fungi via Phase 4 button) results in a clean transition with no leftover biomass yield from plantae after the fungi run starts.
- [ ] No yield from empty (unowned-at-the-right-layer) tiles.
- [ ] Existing meta nodes (`efficient_photosynthesis` etc.) still apply to plantae runs.

## Out of scope
- Decay-from-corpses bonus (corpse system in brief 05 stores a fund of decay; GrowthSystem doesn't need to coordinate yet — corpses pay out via their own ticker).
- Multiple species per run (selection UI is Phase 4+; for now hardcoded starter per kingdom).
- Symbiosis multipliers (Phase 6).
