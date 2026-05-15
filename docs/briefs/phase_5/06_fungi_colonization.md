# Brief 06 — FungiColonization

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/systems/territory_system.gd` (post-brief-02) — `add_subsurface`, `get_subsurface_owner`, `get_surface_owner`.
2. `scripts/systems/plant_colonization.gd` (brief 02) — mirror its structure.
3. `scripts/systems/corpse_system.gd` (brief 05) — `is_corpse_at(coord)`.
4. `scripts/data/species_data.gd` and `data/species/mycelium_thread.tres` — for `colonize_cost`.

## Goal
Tap-based fungi colonization with substrate rules distinct from plantae's strict adjacency.

A fungi colonization at `coord` is valid when:
1. The tile's `subsurface_owner` is empty (fungi can't double-claim subsurface).
2. **AND** at least one of:
   - **Bootstrap**: this is the player's first fungi tile this run (no fungi tiles owned yet).
   - **Parasitic spread**: the tile's `surface_owner == &"plantae"` (fungi exploits the plant).
   - **Saprophytic spread**: a corpse is currently active on this tile (CorpseSystem says so).
   - **Mycelium network**: at least one 4-adjacent tile has `subsurface_owner == &"fungi"`.

Cost: paid in spores, not biomass. Pulled from the active species's `colonize_cost`.

## Outputs (create)
- `scripts/systems/fungi_colonization.gd`
- Modification to `scenes/world/world.tscn` — add `FungiColonization` node under `Systems`, near `PlantColonization`.

## Implementation

```gdscript
extends Node

const KINGDOM_ID: StringName = &"fungi"
const SPECIES_PATH: String = "res://data/species/mycelium_thread.tres"

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _corpses: Node = get_node("../CorpseSystem")

var _species: SpeciesData


func _ready() -> void:
    _species = load(SPECIES_PATH) as SpeciesData
    if _species == null:
        push_error("FungiColonization: missing %s" % SPECIES_PATH)
    EventBus.tile_tapped.connect(_on_tile_tapped)


func _on_tile_tapped(coord: Vector2i) -> void:
    if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
        return
    if GameState.current_kingdom_id != KINGDOM_ID:
        return
    if _species == null:
        return
    if _territory.get_subsurface_owner(coord) != &"":
        return  # already fungi-claimed below
    if not _is_substrate_valid(coord):
        return

    # First fungi tile is free, like plantae's bootstrap.
    var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
    if owned.size() > 0:
        var cost: Dictionary = _get_cost()
        if not ResourceLedger.spend_bundle(cost):
            return

    var ok: bool = _territory.add_subsurface(coord, KINGDOM_ID)
    if ok:
        SaveSystem.save_now()


func _is_substrate_valid(coord: Vector2i) -> bool:
    var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
    # Bootstrap: first fungi tile of the run is allowed anywhere.
    if owned.is_empty():
        return true
    # Parasitic spread.
    if _territory.get_surface_owner(coord) == &"plantae":
        return true
    # Saprophytic spread.
    if _corpses.has_method("is_corpse_at") and _corpses.is_corpse_at(coord):
        return true
    # Mycelium network adjacency.
    var owned_set: Dictionary = {}
    for c in owned:
        owned_set[c] = true
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        if owned_set.has(coord + offset):
            return true
    return false


func _get_cost() -> Dictionary:
    var cost: Dictionary = _species.colonize_cost.duplicate()
    # Apply saprophytic_efficiency trait modifier if present in the species's traits.
    var discount: float = 0.0
    for t in _species.base_traits:
        discount += float(t.modifiers.get("colonize_cost", 0.0))
    if discount != 0.0:
        for key in cost.keys():
            cost[key] = maxf(0.0, float(cost[key]) * (1.0 + discount))
    return cost
```

## Acceptance criteria
- [ ] Plantae run: tapping does NOT trigger fungi colonization.
- [ ] Fungi run, first tap: tile becomes subsurface-fungi at any location, no cost.
- [ ] Fungi run, subsequent tap on empty tile not adjacent / not on plant / not on corpse: no-op.
- [ ] Fungi run, tap on plant-surface tile: fungi colonizes subsurface (tile renders BOTH overlays).
- [ ] Fungi run, tap on corpse tile: fungi colonizes subsurface (corpse continues to decay separately).
- [ ] Fungi run, tap adjacent to existing fungi tile: spreads.
- [ ] Cost is in spores, deducted via `spend_bundle`.
- [ ] Insufficient spores → no-op.

## Out of scope
- Fungi taking over surface (corruption / overgrowth) — Phase 6+.
- Cost scaling by network size. Tune in Phase 7.
- Spore wind / passive spread without taps. The infection event (brief 07) covers passive spread.
