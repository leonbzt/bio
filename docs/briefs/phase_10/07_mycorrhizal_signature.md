# Brief 07 — Mycorrhizal fungi signature mechanic (substrate-claim)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — UX + colonization flow change.

Read first:
1. `scripts/systems/colonization_rules_registry.gd:111` — current `_rule_mycorrhizal_fungi` (placement needs plant adjacency).
2. `scripts/systems/fungi_colonization.gd` — colonization handler.
3. `scripts/systems/growth_system.gd:196` — current mycorrhizal yield bonus (1.3×).
4. `data/niches/mycorrhizal_fungi.tres`.

## Goal

Change mycorrhizal fungi's signature from "place adjacent to fungi or plantae" (currently almost identical to decomposer) to **substrate-claim**: the player **taps an existing plantae tile** to *bond* with it. The bond gives mutual yield boost (plantae gets +20% biomass, fungi gets +20% decay per bonded tile), and the bond persists for the rest of the run.

The niche identity becomes: **find and bond with plants, don't just spread**. Visually: bonded tiles get a teal underlay; mechanically: yields compound where bonds are dense.

## Mechanic specifics

| Behavior | Detail |
|---|---|
| Placement target | Tap a tile with `surface_owner == &"plantae"` to bond. Free-tile taps (empty subsurface, no plant on top) are invalid. |
| Cost | `cost_override.spores = 4.0` (slightly above the decomposer base of 3 to make the bond feel deliberate). |
| Bond effect on yields | Plantae's biomass yield on that tile × 1.20. Fungi's decay yield on that tile × 1.20. Stacks with existing buffs (mutualism, wood_wide_web) multiplicatively. |
| Bond persistence | Once bonded, the tile has `tile.data.mycorrhizal_bond = true`. Persists for the run; cleared on prestige. |
| Tile data update | `set_tile_data(coord, "mycorrhizal_bond", true)` when subsurface fungi added on a plant tile. |
| Visual | Teal subsurface tint (per Phase 8 mycorrhizal tile variant — already exists). The bond doesn't need its own variant. |

## Implementation

### Update `_rule_mycorrhizal_fungi` in `colonization_rules_registry.gd`

Replace the current rule with a substrate-claim rule:

```gdscript
func _rule_mycorrhizal_fungi(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null:
        return {"valid": false, "cost": {}, "data": {}}
    if territory.get_subsurface_owner(coord) != &"":
        return {"valid": false, "cost": {}, "data": {}}

    # Substrate-claim: must place ON an existing plantae tile.
    if territory.get_surface_owner(coord) != &"plantae":
        return {"valid": false, "cost": {}, "data": {}}

    var cost: Dictionary = _resolve_cost(species, niche)
    return {"valid": true, "cost": cost, "data": {"mycorrhizal_bond": true}}
```

### Update `data/niches/mycorrhizal_fungi.tres`

```
cost_override = {"spores": 4.0}
```

### Update yield bonus in `growth_system.gd`

Current:
```gdscript
if _is_tile_mycorrhizal_boosted(coord):
    per_tile *= 1.30
```

Replace with per-tile bond check:
```gdscript
if _is_tile_mycorrhizal_bonded(coord, kingdom_id):
    per_tile *= 1.20    # 20% boost (per spec)
```

Define:
```gdscript
func _is_tile_mycorrhizal_bonded(coord: Vector2i, kingdom_id: StringName) -> bool:
    if kingdom_id != &"plantae" and kingdom_id != &"fungi":
        return false
    return bool(_territory.get_tile_data(coord, "mycorrhizal_bond", false))
```

Remove the old `_is_tile_mycorrhizal_boosted` function — it was scoped to "current niche is mycorrhizal", but with the bond model, the boost lives on the *tile*, applicable in any run that visits the tile mid-run. (In Phase 10, bonds are per-run only, so this distinction is moot; but cleaner contract.)

### Discoverability

When the player has the Mycorrhizal niche selected, the HUD should hint that taps must land on plantae tiles. Two options:
- A subtle "place on plants" instruction strip below the niche badge.
- Highlight valid placement candidates (plantae tiles) when no ability is active — overlay a faint teal outline on tappable plant tiles.

For v1: option 1 (text hint). Option 2 is polish.

In `hud.gd`, add a `MycorrhizalHint` Label that's visible only when `current_niche_id == &"mycorrhizal_fungi"`:
```
"Tap plant tiles to bond"
```

### Discovery log voice

The `disc_niche_mycorrhizal_fungi` entry already reads:
> The Underground Market — Sugar from the roots above, in exchange for water and phosphorus from the dark below.

This reads well against the new mechanic. No content update needed.

## Acceptance criteria
- [ ] Tap an empty tile in a Mycorrhizal Fungi run → does nothing (invalid placement).
- [ ] Tap a tile that has a plant on it → fungi tile placed in subsurface; `tile.data.mycorrhizal_bond == true`.
- [ ] Tap a tile that has only fungi (no plant) → does nothing.
- [ ] Cost: 4 spores (not 3).
- [ ] On a bonded tile: plantae biomass yield × 1.20, fungi decay yield × 1.20.
- [ ] HUD hint visible only on mycorrhizal runs.
- [ ] Regression: decomposer fungi still places fine (its rule is unchanged).
- [ ] Bond persists for the run; resets on prestige (no need to test — it's tile state which already resets).
- [ ] Smoke: a Lichen run where the player builds plant tiles first then taps Plantae layer off → toggles to fungi (subsurface) and tries to bond → DOES NOT WORK here because Lichen niche is not mycorrhizal niche. (Verifies the bond mechanic is niche-scoped.)

## Out of scope
- Bond persistence across prestige (would require tile_history; parked design).
- Mycorrhizal bond visual flair (just uses existing teal subsurface; no new sprite).
- Bond-cluster effects ("3 bonded tiles in a row become a Mycorrhizal Hub structure" — that's the structures design, Phase 13–14).
- A "wood wide web" visual that draws lines between bonded tiles (polish).
