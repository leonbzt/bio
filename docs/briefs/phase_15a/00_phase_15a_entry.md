# Brief 00 — Phase 15a entry (felt income + maturation + cost scaling)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 14b smoke-tested (era teeth + biomes + visual polish in place).
- [ ] Save at `save_version: 14`.

## What Phase 15a is

The "felt progression" foundation. Players currently see numbers move but don't *feel* their lineage growing. Phase 15a fixes that with three additive layers:

1. **Per-resource multipliers** — separate multiplier chains per resource (Biomass ×2.3, Spores ×1.5, etc.) so upgrades have visible compounding impact.
2. **Cluster income floats** — every ~8s each connected cluster of owned tiles spawns a "+X biomass" floating label at its centroid. Tile pulse on tick reinforces aliveness.
3. **Tile maturation** — tiles age from Sprouting (50% yield) to Mature (100%) to Ancient (130% + fertilizer aura). Visual saturation grows with age.

Plus economic anchoring:
4. **Per-species tile cost scaling** — `cost = base × 1.05^n_owned` so monoculture is naturally bounded; ecosystems grow into *diversity* instead of one species filling the map.

## Decisions locked

From 2026-05-20 conversation:
1. **Resource-specific multipliers** (not global ×N). Each resource has its own chain.
2. **Cluster floats every ~8s** at cluster centroid, throttled per-cluster (stagger by cluster id hash).
3. **Cluster income reward weighting**: includes cluster size (not just count).
4. **Tile maturation** with three stages: Sprouting (0-15 ticks, 50% yield), Mature (15-60, 100%), Ancient (60+, 130% + small adjacency aura).
5. **Tile cost formula**: `cost = base × 1.05^n_owned` per species. Snapshot: 10th tile 1.63×, 25th 3.39×, 50th 11.5×, 100th 131×.
6. **Dual identity verb**: cultivate + architect.
7. **Tile pulse on production**: throttled visual (~10% of ticks per tile) to convey aliveness without flicker.
8. **Prestige "power went from ×X to ×Y" framing**: parked for a later phase (deferred from this scope).

## Contracts landing in Phase 15a

- **Save schema v14 → v15**:
  - `run.tile_ages: Dictionary[String, int]` — coord → tick when placed
  - `run.species_tile_counts: Dictionary[String, int]` — species_id → current owned count
  - `meta.lifetime_counters: Dictionary` — `species_played`, `discoveries_unlocked`, `eras_completed` etc. (some already exist; consolidate access)
- **`ResourceLedger`** gains a multiplier registry per resource id. New API:
  - `set_multiplier_source(resource_id, source_key, value)` — add/update one source's contribution
  - `get_multiplier(resource_id) -> float` — current product of all sources
  - `get_multiplier_breakdown(resource_id) -> Array[{source, value}]` — for HUD tooltips
- **`GrowthSystem._apply_yields`** multiplies in `ResourceLedger.get_multiplier(resource_id)` once per yield.
- **`TerritorySystem`** stamps `placed_tick = TickClock.tick_count` in tile data when adding occupant.
- **`TileGrid`** queries tile age + computes saturation/aura visual.
- **`ColonizationRulesRegistry.evaluate`** consults `species_tile_counts[species_id]` to scale `base_cost` by `1.05^n_owned`.
- **New scene**: cluster-income float label (single template, pooled).

## Brief routing

| # | Brief | Agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v14 → v15 migration | ChatGPT 5.2 | Claude (additive) |
| 02 | Per-resource multiplier chains + HUD chips | ChatGPT 5.2 | **Claude** (math correctness) |
| 03 | Cluster detection + income floats | ChatGPT 5.2 | Claude (perf) |
| 04 | Tile pulse on production tick | ChatGPT 5.2 | Claude |
| 05 | Tile maturation (life stages) | ChatGPT 5.2 | **Claude** (yield math) |
| 06 | Tile cost scaling per species owned | ChatGPT 5.2 | **Claude** (formula application) |
| 07 | Phase 15a smoke test | you on device | — |

## Order of work

1. **01** save migration first — everything reads/writes via new fields.
2. **02** multiplier chains — exposes the API for everything else.
3. **05** tile maturation + **06** cost scaling — economic foundation; both touch GrowthSystem + ColonizationRulesRegistry, ship together.
4. **03** cluster floats — uses multipliers + maturation to display correct numbers.
5. **04** tile pulse — pure visual; can land last.
6. **07** smoke test.

## Exit criteria

- HUD shows a multiplier chip per primary resource ("Biomass ×2.4 ↑"). Tooltip lists contributing sources.
- Placing 30 tiles of one species visibly costs more than the first (~3× by tile 25).
- A tile placed 60+ ticks ago looks visibly saturated, produces more than a fresh one.
- Cluster of 5+ tiles shows a "+N biomass" float every ~8s at cluster center.
- Tile occasionally pulses brightly on tick (not every tick).
- Save v14 → v15 lossless on existing runs.

## Out of scope

- Prestige screen "Power went from ×X to ×Y" framing (parked).
- New multiplier sources beyond what Phase 15a wires (Phase 15b/c add more).
- Per-cluster aggregate stats UI ("This cluster produces 12 biomass/sec") — Phase 15c+.
- Animations / particle effects (Phase 16+).
- Cluster outline color reflecting age — Phase 16+ polish.
