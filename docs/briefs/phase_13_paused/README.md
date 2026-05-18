# Phase 13 (paused) — original content briefs

**Status**: Paused 2026-05-18 in favor of the species-first model migration.

These 11 briefs were written before the species-first reshape was locked. They cover:
- New biomes (tundra, mineral_vent, swamp)
- Per-ecosystem biome generation
- Axis-scoped events (`EventData.scope`)
- Mass extinction gameplay teeth
- Era-gated evolution nodes
- Per-era visual identity

**These goals are not abandoned** — they move to **Phase 14** after the migration phase (the new `docs/briefs/phase_13/`) lands the species-first model.

## What survives intact when these revive

- **Brief 02** (BiomeData schema + 3 new biomes) — `chemosynthesis_per_tick` field + tundra/mineral_vent/swamp .tres files survive as-is.
- **Brief 04** (EventData.scope + scope_target) — schema survives; the scope-filter implementation updates to the species-first kingdom-as-tag model.
- **Brief 06** (mass extinction teeth) — `post_extinction` meta state + recovery debuff lifecycle survive; the EraSystem hook points stay.
- **Brief 08** (per-era visual identity) — tile/background tint approach survives.
- **Brief 09** (discovery entries) — voice text survives; some entries re-categorize from `niche` to `species` per the new taxonomy.

## What needs rework when these revive

- **Brief 03** (per-ecosystem biome generation) — `biome_preference` field is replaced by `biome_recipe` weighted mix. Generation algorithm pivots from 70/30 split to weighted-with-cluster.
- **Brief 05** (event content pass) — backfill table changes: `herbivore_wave` becomes `scope: &"species_tag", scope_target: &"plantae"` (not `kingdom`), since kingdom is no longer a run-state field.
- **Brief 07** (era-gated nodes) — `EvolutionNodeData.requires_era` survives; the 5 new nodes have their effects re-expressed in species-tag/biome-tag predicates.
- **Brief 10** (smoke test) — entirely rewritten against Phase 14 content scope.

See `docs/SPECIES_MODEL.md` for the foundation that Phase 13 (revised) builds, and the current `docs/briefs/phase_13/` for the active migration phase.
