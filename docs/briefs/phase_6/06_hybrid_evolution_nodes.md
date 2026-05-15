# Brief 06 — Hybrid evolution nodes (mutualism + wood_wide_web)

**Suggested agent**: Kilo for the .tres, ChatGPT for the GrowthSystem modifier wiring.

Read first:
1. `data/evolution_tree/unlock_symbiosis.tres` (created in brief 01).
2. `scripts/utils/meta_modifiers.gd` — `is_unlocked(node_id)` helper.
3. `scripts/systems/growth_system.gd` (post-brief-05) — where SYMBIOSIS_BONUS lives.

## Goal
Two hybrid evolution nodes that meaningfully reward symbiotic play. Both require `unlock_symbiosis` as a prereq.

| Node | Effect |
|---|---|
| `mutualism` | Symbiosis bonus rises from +30% to +50%. |
| `wood_wide_web` | Tiles adjacent to a symbiotic tile (4-neighbor) get a small +15% bonus to their yields, even if they're not symbiotic themselves. |

## Outputs (create)

### `data/evolution_tree/mutualism.tres`
- `id = &"mutualism"`
- `display_name = "Mutualism"`
- `description = "Symbiotic tiles yield +50% to each layer (up from +30%)."`
- `prerequisites = [&"unlock_symbiosis"]`
- `meta_cost = {"evolution_points": 12}`

### `data/evolution_tree/wood_wide_web.tres`
- `id = &"wood_wide_web"`
- `display_name = "Wood Wide Web"`
- `description = "Tiles next to a symbiotic tile gain +15% to their yields."`
- `prerequisites = [&"mutualism"]`
- `meta_cost = {"evolution_points": 18}`

### Update `data/evolution_tree/_index.tres`
Append `mutualism.tres` and `wood_wide_web.tres` to the array.

## GrowthSystem wiring

### Mutualism — bump the constant via a helper

Replace the `const SYMBIOSIS_BONUS: float = 0.30` with a getter:

```gdscript
func _get_symbiosis_bonus() -> float:
    if MetaModifiers.is_unlocked(&"mutualism"):
        return 0.50
    return 0.30
```

Use `_get_symbiosis_bonus()` inside `_apply_yields` where the bonus is applied.

### Wood Wide Web — add an adjacency bonus

Inside `_apply_yields`, after the symbiosis bonus check, add:

```gdscript
if MetaModifiers.is_unlocked(&"wood_wide_web") and not _is_tile_symbiotic(coord):
    if _is_adjacent_to_symbiotic(coord):
        per_tile *= 1.15
```

Helper:
```gdscript
func _is_adjacent_to_symbiotic(coord: Vector2i) -> bool:
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        if _is_tile_symbiotic(coord + offset):
            return true
    return false
```

## Acceptance criteria
- [ ] Without `mutualism`: symbiotic tile yields = base × 1.30.
- [ ] With `mutualism`: symbiotic tile yields = base × 1.50.
- [ ] Without `wood_wide_web`: non-symbiotic tiles next to symbiotic ones yield normally.
- [ ] With `wood_wide_web`: those neighbors yield × 1.15 (additive on top of biome/trait multipliers).
- [ ] Modifiers stack across all yield resources (biomass, decay, spores).
- [ ] In a single-kingdom run (no symbiotic tiles possible), neither modifier has any effect.

## Out of scope
- More than two hybrid nodes. Phase 7 polish can add a fourth + fifth tier.
- Per-kingdom variation of bonuses (e.g. plant gets +50%, fungi gets +30%). Keep symmetric for MVP.
