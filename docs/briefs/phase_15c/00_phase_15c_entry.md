# Brief 00 — Phase 15c entry (run-progression core)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 15a smoke-tested (income feel + cost scaling).
- [ ] Phase 15b smoke-tested (fog + obstacles + structures).
- [ ] Save at `save_version: 16`.

## What Phase 15c is

The strategic mid-run layer: a parallel currency (**Adaptation**) you accumulate while playing, spent on **per-run species evolution levels** that ramp up yields mid-run. Plus three new placement rules for species variety.

This phase explicitly **defers**:
- Stackable per-run goals (3 active) — saved for a later phase
- Tier-up threshold banners — saved for a later phase
- Balance pass on Phase 15 systems — saved for after content stabilizes

These were originally in the 15c scope but deferred per the 2026-05-20 decision to keep this phase tight and ship the mid-run layer first.

## Decisions locked

1. **Three temporal layers** (Resources / Adaptation / EP) — Adaptation is the *strategic this-run* currency, distinct from per-tick resources and per-prestige EP.
2. **Adaptation earn formula** (shape locked, numbers tunable):
   - +N per total cluster-tile-count (cluster *size* matters, not count) per minute
   - +M per distinct biome present on the map
   - +K per active species (species in `unlocked_species_in_run`)
3. **Per-run species evolution**: 3 levels per species per run. Each level +10% yield to that species. Costs Adaptation.
4. **3 new placement rules**: `diagonal_only`, `gap_jumper`, `corpse_only` + 3 variant species using them.
5. **Adaptation persists for the run, resets on prestige.**

## Contracts landing in Phase 15c

- **Save schema v16 → v17**:
  - `run.adaptation: float` — current pool
  - `run.species_levels: Dictionary[String, int]` — species_id → current level (1-3)
- **`AdaptationSystem`** new autoload (or system child): tick-driven accumulation; exposes API to query + spend.
- **`ResourceLedger`** doesn't own Adaptation (different lifecycle, different earning rules). Lives in its own system.
- **`GrowthSystem._apply_yields`** multiplies in `species_level_multiplier(species_id)` after maturation + biome.
- **HUD**: Adaptation chip showing current pool + per-min rate.
- **Species panel**: introduced rows gain a "Level [N]/[3]" indicator + "Evolve" tap shortcut.
- **New scene**: per-species evolve modal — shows current/next level + cost + confirm.
- **3 new placement rules** in `ColonizationRulesRegistry.evaluate`.
- **3 variant species**: e.g., `spore_drift` (gap_jumper fungi), `creeping_vine` (diagonal_only plantae), `scavenger_swarm` (corpse_only animal).

## Brief routing

| # | Brief | Agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v16 → v17 migration | ChatGPT 5.2 | Claude |
| 02 | Adaptation currency + system | ChatGPT 5.2 | **Claude** (formula + accumulation) |
| 03 | Per-run species evolution UI + yield wiring | ChatGPT 5.2 | **Claude** (yield math) |
| 04 | 3 new placement rules + variant species | ChatGPT 5.2 + Kilo (data) | Claude |
| 05 | Phase 15c smoke test | you on device | — |

## Order of work

1. **01** save migration.
2. **02** Adaptation currency.
3. **03** species evolution (depends on 02).
4. **04** placement rules + variant species (independent; can land in parallel).
5. **05** smoke test.

## Exit criteria

- HUD shows Adaptation chip with current pool + per-minute rate.
- Adaptation accumulates passively while playing (rate visible in chip).
- "Introduced" species rows show level indicator (e.g., "Lvl 1/3"); tapping opens evolve modal.
- Spending Adaptation levels a species; that species' yields go up by +10% per level.
- Save round-trip preserves Adaptation pool + species levels.
- 3 new variant species available (after unlock) using the 3 new placement rules.
- Diagonal_only species: can place on diagonal-of-own only; cardinal placements rejected.
- Gap_jumper: can place up to N tiles in cardinal line-of-sight.
- Corpse_only: requires corpse tile at target.

## Out of scope (deferred to later phase)

- Stackable per-run goals (3 active)
- Tier-up threshold banners
- Balance pass on Phase 15 systems
- Branching evolution choices (level-up gives flat +10% per level for v1)
- Hybrid evolution costs (Adaptation + resources)
- Cross-species evolution interactions
- New permanent evolution-tree nodes for the new species (Phase 16+ when designed)
