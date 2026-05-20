# Brief 06 — Tile cost scaling per species owned

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — formula application.

Read first:
1. `scripts/systems/colonization_rules_registry.gd` — cost computation per rule.
2. `scripts/systems/territory_system.gd.add_occupant / remove_occupant` — counts to maintain.
3. `docs/briefs/phase_15a/01_save_v15_migration.md` — `run.species_tile_counts`.

## Goal

Each species' per-tile placement cost scales exponentially with how many tiles of that species are currently owned:

```
cost = base_cost × 1.05 ^ n_owned
```

Snapshot:
| Owned | Multiplier |
|---|---|
| 0 (placing the first) | ×1.00 |
| 10 | ×1.63 |
| 25 | ×3.39 |
| 50 | ×11.5 |
| 100 | ×131.5 |

This prevents monoculture — the *N*th tile of mycelium_thread costs as much as 100+ first-tile placements combined. Players are pushed to diversify instead of filling the map with one species.

## TerritorySystem keeps the counter

```gdscript
func add_occupant(coord: Vector2i, kingdom_id: StringName, species_id: StringName) -> bool:
    # ... existing checks + assignment ...
    _bump_species_count(species_id, 1)
    # ... existing TileGrid + signal ...


func remove_occupant(coord: Vector2i, kingdom_id: StringName, cause: StringName) -> void:
    # ... existing checks ...
    var prev_species: StringName = StringName(occupants[kingdom_id])
    # ... existing remove ...
    _bump_species_count(prev_species, -1)


func _bump_species_count(species_id: StringName, delta: int) -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var counts: Dictionary = run.get("species_tile_counts", {}) as Dictionary
    var sp_key: String = String(species_id)
    counts[sp_key] = maxi(0, int(counts.get(sp_key, 0)) + delta)
    run["species_tile_counts"] = counts


func get_species_tile_count(species_id: StringName) -> int:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var counts: Dictionary = run.get("species_tile_counts", {}) as Dictionary
    return int(counts.get(String(species_id), 0))
```

## ColonizationRulesRegistry applies the multiplier

Single scaling step centralized in `_resolve_cost(species)` or wherever each rule builds its cost dict:

```gdscript
const COST_GROWTH_FACTOR: float = 1.05

func _scaled_cost(species: SpeciesData) -> Dictionary:
    var base: Dictionary = species.colonize_cost.duplicate()
    var n: int = _get_territory().get_species_tile_count(species.id)
    var mult: float = pow(COST_GROWTH_FACTOR, float(n))
    var scaled: Dictionary = {}
    for resource_id in base.keys():
        scaled[resource_id] = float(base[resource_id]) * mult
    return scaled
```

Each rule (`_rule_adjacent_empty`, `_rule_fungi_substrate`, `_rule_parasitic_plantae`, `_rule_mycorrhizal_fungi`, `_rule_animal_anchor`, `_rule_recipe`) should use `_scaled_cost(species)` instead of reading `species.colonize_cost` directly.

For the recipe rule: scale each component's cost via the same formula based on that component's current count, then sum.

## First-tile-free behavior

The current rules give the first tile free when `owned.is_empty()`. Preserve that:

```gdscript
if owned.is_empty():
    cost = {}
```

This means n=0 → first placement free; n=1 onward → `base × 1.05^n`. Good — eases entry.

## Species panel UI: show current cost

When rendering "Introduced" rows in the species panel's bottom bar, the button tooltip should reflect the *current* scaled cost so players can see costs rising:

```gdscript
# In species_panel.gd._build_introduced_row:
var scaled: Dictionary = _territory_or_lookup_scaled_cost(species)
btn.tooltip_text = "%s\n%s\nCost: %s" % [
    species.display_name, species.latin_name,
    _format_cost(scaled)
]
```

Tooltip refresh on tick (the panel already refreshes on `resource_changed` — extend to `tick` if needed) so the displayed cost stays current.

## Acceptance criteria

- [ ] `TerritorySystem.get_species_tile_count(species_id)` returns the current owned count.
- [ ] Counts increment on `add_occupant`, decrement on `remove_occupant`, never go negative.
- [ ] Save round-trip preserves `species_tile_counts`.
- [ ] Placing the 1st tile of a species is free (preserved first-tile behavior).
- [ ] Placing the 10th tile of `pioneer_grass` costs ~1.6× base.
- [ ] Placing the 25th tile costs ~3.4× base.
- [ ] Placing the 50th tile costs ~11.5× base.
- [ ] Cost scaling applies on ALL rules: adjacent_empty, fungi_substrate, parasitic_plantae, mycorrhizal_fungi, animal_anchor, recipe.
- [ ] Species panel tooltip shows the current scaled cost (updates as you place tiles).
- [ ] Removing tiles decreases the counter and lowers subsequent placement cost.

## Out of scope

- Per-resource cost scaling rates (e.g., only biomass scales, spores stays flat) — uniform across resources for v1.
- "Diminishing returns on cost" past a threshold — pure exponential always for v1.
- Discount nodes (e.g., a hypothetical "Economy of Scale" node that flattens the curve) — Phase 15c+ or later.
- Per-niche / per-biome cost modifiers stacking with the scaling.
- Visual indicator on species panel rows ("Cost rising!" badge).
