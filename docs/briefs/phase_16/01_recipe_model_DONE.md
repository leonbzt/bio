# Brief 01 — Step 1: Recipe model in data (DONE 2026-05-27)

**Status**: Completed by Claude on 2026-05-27. Recorded for context.

## What landed

### `scripts/data/species_data.gd`
Added one field:

```gdscript
# Per-tile-per-tick input rates. Output throttles proportionally when the global pool
# can't satisfy total consumption (bottleneck mechanic).
@export var consume_input: Dictionary = {}
```

No other fields removed — per "unwired" strategy, existing fields remain in place so still-on-disk systems don't break parsing.

### `data/species/calamites.tres`
```
tick_yield = {
"biomass": 2.0,
"decay": 0.2
}
consume_input = {
"nutrients": 1.0
}
```
Calamites produces biomass (hero metric) + small detritus side-output (bootstrap path for fungi pre-arthropleura). Consumes nutrients.

### `data/species/mycorrhizal_network.tres`
```
tick_yield = {
"nutrients": 1.5
}
consume_input = {
"decay": 1.5
}
```
Pure decomposer: detritus → nutrients. No biomass side-output (was producing biomass + nutrients before — biomass production was removed).

### `data/species/arthropleura.tres`
```
tick_yield = {
"decay": 1.5
}
consume_input = {
"biomass": 1.5
}
```
Consumer: biomass → detritus. No biomass production (was producing biomass before — removed).

### `scripts/systems/growth_system.gd`
Added input throttling at the top of `_apply_yields`:

```gdscript
var input_throttle: float = _compute_input_throttle(species, coords.size())
if input_throttle <= 0.0:
    return
_spend_inputs(species, coords.size(), input_throttle)
base_mult *= input_throttle
```

Plus two helper methods (`_compute_input_throttle`, `_spend_inputs`) appended to the file. The throttle factor multiplies into `base_mult`, scaling all subsequent per-tile-yield computations proportionally. Inputs are consumed via `ResourceLedger.add(id, -spent)`.

Species with empty `consume_input` (all non-prototype species) get throttle = 1.0 and behave unchanged.

## Known carry-over to step 02

- The current biomass pool in `ResourceLedger.BIOMASS` is now consumed by Arthropleura via `consume_input`. **Step 02 must add a separate `hero_biomass_lifetime_produced` counter** to the run_save so the HUD shows monotonic plant production rather than the volatile global pool.
- `NutrientSystem` still injects per-biome NUTRIENTS + DECAY from `wetland.tres` etc. This means the bottleneck mechanic won't visibly bite — biomes free-produce the inputs. **Step 02 or 03 should disable the biome-side resource injection** for NUTRIENTS + DECAY (sunlight injection is fine; not used in v1 anyway).
- `mycorrhizal_network` and `arthropleura` still have `tick_effects` (`mycorrhizal_bond_apply`, `nitrogen_fix`, `frass_enrichment`). These fire from `_apply_tick_effects` after `_apply_yields` and are NOT throttled. Minor inconsistency; acceptable for now. They can be stripped when the `growth_system` bonus tower is simplified in a later step.

## Files touched

```
scripts/data/species_data.gd
scripts/systems/growth_system.gd
data/species/calamites.tres
data/species/mycorrhizal_network.tres
data/species/arthropleura.tres
```

5 files. No new signals, no new autoloads, no schema migration. Backwards-compatible for species that don't opt into `consume_input`.
