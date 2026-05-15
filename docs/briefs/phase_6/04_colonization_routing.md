# Brief 04 — Colonization routing for symbiosis runs

**Suggested agent**: ChatGPT 5.2 via Copilot. Small, surgical patches.

Read first:
1. `scripts/systems/plant_colonization.gd` — current `_on_tile_tapped` gating.
2. `scripts/systems/fungi_colonization.gd` — same.

## Goal
Replace the strict `current_kingdom_id == KINGDOM_ID` guard with a check that ALSO permits symbiosis runs where the player has the appropriate `placement_target` selected.

## Patches

### `plant_colonization.gd`

Replace:
```gdscript
if GameState.current_kingdom_id != KINGDOM_ID:
    return
```

With:
```gdscript
if not _is_active():
    return
```

Add:
```gdscript
func _is_active() -> bool:
    if GameState.current_kingdom_id == KINGDOM_ID:
        return true
    if GameState.current_kingdom_id == &"symbiosis" and GameState.placement_target == KINGDOM_ID:
        return true
    return false
```

### `fungi_colonization.gd`
Same patch — mirror the helper.

## Why the gate not the kingdom check directly
The helper isolates the logic so future kingdoms (or future symbiosis tweaks) only need to update one spot. Don't inline.

## Acceptance criteria
- [ ] Plantae run: tapping colonizes surface (regression).
- [ ] Fungi run: tapping colonizes subsurface (regression).
- [ ] Symbiosis run, placement_target = plantae: tapping colonizes surface only; FungiColonization doesn't fire.
- [ ] Symbiosis run, placement_target = fungi: tapping colonizes subsurface only; PlantColonization doesn't fire.
- [ ] Toggling placement_target mid-run swaps which system handles the next tap.
- [ ] All existing rules apply per layer: plant adjacency, fungi substrate, bootstrap, cost, input_mode gating.

## Out of scope
- Cross-kingdom cost subsidies. Costs stay as-is — biomass for plants, spores for fungi. The interesting bit is that a symbiosis run produces both, so the player has a self-sustaining feedback loop.
