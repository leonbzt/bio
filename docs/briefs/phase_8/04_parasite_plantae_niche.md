# Brief 04 — Parasite plantae niche (the test-bed)

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/NICHES.md` — the parasite plantae design notes.
2. `scripts/systems/colonization_rules_registry.gd` (post brief 03).
3. `scripts/systems/territory_system.gd` — `set_tile_data`, surface accessors.
4. `scripts/systems/growth_system.gd` — how it iterates owned coords for yield.

## Goal
Add **Parasite** as the first new plantae niche. Design intent: a glass-cannon parasite playstyle. Cheaper colonization, higher per-tile yield, but parasitic tiles wither when isolated (network dependence).

This brief is the **test-bed** for the niche system — if Parasite plantae works cleanly, the rest of the niches (Mycorrhizal fungi in brief 05, future niches in later phases) can follow the same pattern.

## Design summary

| Property | Parasite plantae | Default plantae |
|---|---|---|
| Colonization | First tile: free anywhere. Subsequent: adjacent to owned (any tile, surface or subsurface). | Adjacent to owned surface only. |
| Cost | 3 biomass | 5 biomass |
| Yield per tile | 1.0 biomass/tick (vs 0.5) | 0.5 |
| Tile durability | Withers after 30 ticks if not adjacent to ≥ 2 other parasite tiles | Permanent |
| Visual | Crimson surface overlay instead of green | Bright green |

Withering means: each tick, parasite tiles with < 2 parasite neighbors decrement a `parasite_decay_ticks` counter. At 0, tile is lost (TerritorySystem.remove_surface).

Tiles adjacent to ≥ 2 parasite neighbors reset their counter to the max (30). Parasitic network stays alive only when dense; isolated outposts die.

## Outputs

### `data/niches/parasitic_plantae.tres` *(rename of the type — actual niche id stays simpler)*
```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/pioneer_grass.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"parasite_plantae"
display_name = "Parasitic"
description = "Spread cheap, grow fast, wither alone. Strength is in the network."
kingdom_id = &"plantae"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"parasitic_plantae"
cost_override = {"biomass": 3.0}
unlock_node_id = &"unlock_parasitic_plantae"
```

Add to `data/niches/_index.tres`.

### `data/evolution_tree/unlock_parasitic_plantae.tres`
```
[gd_resource type="Resource" script_class="EvolutionNodeData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/evolution_node_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"unlock_parasitic_plantae"
display_name = "Mistletoe Heritage"
description = "Discover the parasitic way. Plants that live off other plants."
prerequisites = [&"thrifty_growth"]
meta_cost = {"evolution_points": 8}
grants_traits = []
grants_kingdoms = []
```

Append to `data/evolution_tree/_index.tres`.

### `ColonizationRulesRegistry._rule_parasitic_plantae`

```gdscript
func _rule_parasitic_plantae(coord, kingdom_id, species, niche) -> Dictionary:
    var territory: Node = _get_territory()
    if territory.get_surface_owner(coord) != &"":
        return {"valid": false, "cost": {}, "data": {}}

    var owned: Array[Vector2i] = territory.get_surface_owned_coords(kingdom_id)

    # Bootstrap: first parasite tile is free anywhere.
    if owned.is_empty():
        return {
            "valid": true,
            "cost": {},
            "data": {"parasite_decay_ticks": 30}
        }

    # Subsequent: must be adjacent to ANY owned tile (surface OR subsurface).
    var has_neighbor: bool = false
    for n in neighbors(coord):
        if territory.get_surface_owner(n) != &"" or territory.get_subsurface_owner(n) != &"":
            has_neighbor = true
            break
    if not has_neighbor:
        return {"valid": false, "cost": {}, "data": {}}

    var cost: Dictionary = niche.cost_override.duplicate() if not niche.cost_override.is_empty() else species.colonize_cost.duplicate()
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        for k in cost.keys():
            cost[k] = maxf(0.0, float(cost[k]) - 1.0)

    return {
        "valid": true,
        "cost": cost,
        "data": {"parasite_decay_ticks": 30}
    }
```

### New system: `scripts/systems/parasite_decay_system.gd`
Watches parasite-niche runs. Each tick:
1. For every owned plantae surface tile, count parasite-niche neighbors.
2. If ≥ 2 neighbors: reset `parasite_decay_ticks` to 30.
3. Else: decrement by 1. If 0 or negative: `_territory.remove_surface(coord, &"parasite_wither")`.

This system only runs when the current niche is `parasite_plantae`. Otherwise it returns early.

```gdscript
extends Node

const PARASITE_NICHE_ID: StringName = &"parasite_plantae"
const NEIGHBOR_THRESHOLD: int = 2
const MAX_DECAY_TICKS: int = 30

@onready var _territory: Node = get_node("../TerritorySystem")
var _is_replaying: bool = false


func _ready() -> void:
    EventBus.tick.connect(_on_tick)
    EventBus.replay_started.connect(func(_n): _is_replaying = true)
    EventBus.replay_finished.connect(func(): _is_replaying = false)


func _on_tick(_delta: float) -> void:
    if _is_replaying:
        return
    if GameState.current_niche_id != PARASITE_NICHE_ID:
        return

    var owned: Array[Vector2i] = _territory.get_surface_owned_coords(&"plantae")
    if owned.size() <= 1:
        return  # bootstrap tile alone never withers (gives the player time to expand)

    var owned_set: Dictionary = {}
    for c in owned: owned_set[c] = true

    var to_remove: Array[Vector2i] = []
    for coord in owned:
        var neighbor_count: int = 0
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            if owned_set.has(coord + offset):
                neighbor_count += 1

        var ticks: int = int(_territory.get_tile_data(coord, "parasite_decay_ticks", MAX_DECAY_TICKS))
        if neighbor_count >= NEIGHBOR_THRESHOLD:
            if ticks < MAX_DECAY_TICKS:
                _territory.set_tile_data(coord, "parasite_decay_ticks", MAX_DECAY_TICKS)
        else:
            ticks -= 1
            if ticks <= 0:
                to_remove.append(coord)
            else:
                _territory.set_tile_data(coord, "parasite_decay_ticks", ticks)

    for coord in to_remove:
        _territory.remove_surface(coord, &"parasite_wither")
```

Add `ParasiteDecaySystem` to `world.tscn` under `Systems`.

### `TerritorySystem.get_tile_data(coord, key, default)`
New public method:
```gdscript
func get_tile_data(coord: Vector2i, key: String, default = null) -> Variant:
    if not _tiles.has(coord):
        return default
    var data: Dictionary = _tiles[coord].get("data", {})
    return data.get(key, default)
```

### `GrowthSystem` patch
Add the parasite yield override. When the current niche is `parasite_plantae`, the per-tile yield is 1.0 (vs 0.5). Simplest: multiply by a niche multiplier in `_apply_yields`. Add to `_tick_single_kingdom` / `_tick_symbiosis`:

```gdscript
func _get_niche_yield_multiplier() -> float:
    if GameState.current_niche_id == &"parasite_plantae":
        return 2.0    # 0.5 base * 2.0 = 1.0 per tile
    return 1.0
```

Apply inside `_apply_yields` to the per-tile multiplier.

### Visual: parasite-tile color
`tile_grid.gd` adds a fourth atlas tile (crimson `#a8425f`) at `Vector2i(3, 0)`. New constant `ATLAS_PARASITE_PLANTAE`. `set_surface_owner` checks niche-derived state:

Actually simpler — pass a kingdom *variant* string. Update the surface setter:
```gdscript
func set_surface_owner(coord: Vector2i, kingdom_id: StringName, variant: StringName = &"") -> void:
    if String(kingdom_id) == "":
        erase_cell(LAYER_SURFACE, coord)
    elif kingdom_id == &"plantae":
        var atlas: Vector2i = ATLAS_PARASITE_PLANTAE if variant == &"parasite" else ATLAS_PLANTAE
        set_cell(LAYER_SURFACE, coord, SOURCE_ID, atlas)
```

`TerritorySystem.add_surface` accepts an optional variant arg and passes it through. PlantColonization, when running the parasite niche, calls `add_surface(coord, KINGDOM_ID, &"parasite")`.

## Acceptance criteria
- [ ] After buying `unlock_parasitic_plantae` (8 EP), the niche appears in the prestige screen's plantae niche selection (when brief 06 ships) — but the underlying GameState can be set manually for now via dev shortcut.
- [ ] Parasite run: first tile free, subsequent cost 3 biomass.
- [ ] Parasite tiles render in crimson (distinguishable from photosynthesizer green).
- [ ] A parasite tile with ≥ 2 parasite neighbors lives indefinitely.
- [ ] An isolated parasite tile (< 2 neighbors) withers in 30 ticks.
- [ ] Per-tile yield is 1.0 biomass/tick (vs 0.5 for photosynthesizer) — verify against HUD.
- [ ] Killing app mid-run preserves each tile's `parasite_decay_ticks`.
- [ ] No regression in photosynthesizer plantae.

## Out of scope
- Parasitism across kingdoms (e.g. parasite plant on fungi tile gains bonus). Possible Phase 9.
- Mycorrhizal fungi (brief 05).
- Niche selection UI (brief 06).
