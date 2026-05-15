# Brief 05 — Wire evolution node effects into gameplay

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `data/evolution_tree/*.tres` (brief 03) — to confirm node ids and intended effects.
2. `scripts/systems/territory_system.gd` — COLONIZE_COST.
3. `scripts/systems/ability_system.gd` — TOXIN_BLOOM_DAMAGE.
4. `scripts/systems/ecological_pressure.gd` — MIN_TILES_BEFORE_EVENTS.
5. `scripts/systems/growth_system.gd` — `_biomass_per_tile_modifier`.

## Goal
Three small patches so the unlocked nodes actually do something. No new files.

## Approach
Each affected system reads `GameState.meta_save.evolution_tree` directly through a tiny helper that returns booleans. Avoid pulling in PrestigeSystem (would couple world systems to it).

Add a shared helper at `scripts/utils/meta_modifiers.gd`:
```gdscript
class_name MetaModifiers

static func is_unlocked(node_id: StringName) -> bool:
    var tree: Dictionary = GameState.meta_save.get("evolution_tree", {})
    return bool(tree.get(String(node_id), false))
```

## Patches

### 1. `territory_system.gd` — Thrifty Growth
Replace the static `COLONIZE_COST` const with a dynamic getter:

```gdscript
# Remove: const COLONIZE_COST: Dictionary = {ResourceLedger.BIOMASS: 5.0}

func _get_colonize_cost() -> Dictionary:
    var cost: float = 5.0
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        cost = 4.0
    return {ResourceLedger.BIOMASS: cost}
```

Then in `_on_tile_tapped`, replace `COLONIZE_COST` with `_get_colonize_cost()`.

### 2. `ecological_pressure.gd` — Pioneer Resilience
Replace the static `MIN_TILES_BEFORE_EVENTS` const usage with a getter:

```gdscript
func _get_min_tiles_before_events() -> int:
    if MetaModifiers.is_unlocked(&"pioneer_resilience"):
        return 5
    return 3
```

Use `_get_min_tiles_before_events()` instead of the const in `_maybe_trigger`.

### 3. `ability_system.gd` — Toxin Potency
Same dynamic-getter pattern:

```gdscript
func _get_toxin_damage() -> float:
    if MetaModifiers.is_unlocked(&"toxin_potency"):
        return 5.0
    return 3.0
```

Use it when building the `payload` dict.

### 4. `growth_system.gd` — Efficient Photosynthesis
The current formula is:
```
total += base_yield * biome.sunlight_per_tick * (1.0 + _biomass_per_tile_modifier)
```

Apply a meta-multiplier:
```gdscript
func _get_meta_growth_multiplier() -> float:
    if MetaModifiers.is_unlocked(&"efficient_photosynthesis"):
        return 1.2
    return 1.0
```

Then:
```
total += base_yield * biome.sunlight_per_tick * (1.0 + _biomass_per_tile_modifier) * _get_meta_growth_multiplier()
```

## Re-evaluation on unlock
None of the changes above need re-evaluation logic — they're per-call getters. The next colonization, next tick, or next ability use picks up the new value automatically. Don't add caching or "re-init on `evolution_node_unlocked`" handlers; they'd be dead weight.

## Acceptance criteria
- [ ] With no nodes unlocked: behaviors match Phase 3 exactly (5 biomass per colonize, 3 tile threshold, 3 damage toxin, 1.0× growth).
- [ ] After unlocking `thrifty_growth`: colonize cost is 4.
- [ ] After unlocking `pioneer_resilience`: events don't fire until 5 tiles owned.
- [ ] After unlocking `toxin_potency`: Toxin Bloom deals 5 damage.
- [ ] After unlocking `efficient_photosynthesis`: per-tile biomass yield is ~20% higher.
- [ ] Effects activate immediately after `purchase_node` — no relaunch required.

## Out of scope
- Per-run vs permanent modifiers (all node effects are permanent across runs).
- Trait grants from nodes (none of the Phase 4 nodes use `grants_traits` directly; left for Phase 5+).
