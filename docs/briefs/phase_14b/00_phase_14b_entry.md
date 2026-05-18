# Brief 00 — Phase 14b entry (era teeth: biomes, mass extinction, era nodes, visuals)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 14a complete + smoke-tested (species roster + biome affinity in place).
- [ ] Save at `save_version: 13`.

## What Phase 14b is

Era progression gains real mechanical and visual weight. **Content phase** — biomes, events, evolution nodes, mass extinction.

Six deliverables:

1. **New biomes**: tundra, mineral_vent, swamp + `BiomeData.chemosynthesis_per_tick`.
2. **Per-era visual identity**: tile palette tint + background tint via `EraData.tint_color`.
3. **Axis-scoped events**: `EventData.scope` + `scope_target` + 4 new scoped events.
4. **Mass extinction gameplay teeth**: post-extinction recovery debuff + Extinction Survivor EP bonus.
5. **Era-gated evolution nodes**: 5 new nodes with `requires_era` field.
6. **Discovery entries**: 10 new (biomes, events, nodes, milestones).

Translates the original `docs/briefs/phase_13_paused/` content into species-first language.

## Decisions locked

From Phase 13 paused-brief decisions + species-first model alignment:

1. **Tundra / mineral_vent / swamp biomes** are mechanically distinct via `chemosynthesis_per_tick` for mineral_vent; affinity-driven for the others. Brief 14a's species roster already references these biomes via `biome_affinity` dicts.
2. **Per-ecosystem biome generation** uses `EcosystemData.biome_recipe` (already landed in Phase 13). Phase 14b ensures the recipes reference the new biomes.
3. **Mass extinction debuff**: first run in a new era opens at 0.5× sunlight + biomass, linearly recovers over 120 ticks. On prestige: +25 EP "Extinction Survivor" bonus, one-shot per era.
4. **Axis-scoped events** with scopes `&"world"`, `&"kingdom"`, `&"niche"` (deprecated, retained for back-compat), `&"era"`, `&"ecosystem"`, `&"species_tag"`. Filter pre-applies before weighted roll. `kingdom_required` legacy field deprecated.
5. **Era-gated nodes** use new `EvolutionNodeData.requires_era`. Available only when current era matches; already-purchased nodes stay unlocked.
6. **Visuals tint-only** — `modulate` on TileGrid + background ColorRect. Music + transition VFX deferred to Phase 15.
7. **No new species** in Phase 14b — roster work already shipped in Phase 14a.

## Contracts landing in Phase 14b

- **Save schema v13 → v14**: `meta.post_extinction: Dictionary`, `meta.first_run_in_era_completed: Array[String]`, `meta.first_era_seen: String`.
- **`BiomeData` gains** `chemosynthesis_per_tick: float`.
- **`EventData` gains** `scope: StringName`, `scope_target: StringName`.
- **`EvolutionNodeData` gains** `requires_era: StringName`.
- **`AmbientModifierSystem` gains** `apply_post_extinction_debuff(ticks)` + recovery curve in `get_multiplier`. Also gains `&"biomass_multiplier"` channel.
- **`EraSystem.set_current_ecosystem`** triggers the post-extinction state on era transition.
- **`PrestigeSystem`** awards Extinction Survivor bonus + clears state on first prestige in the new era.
- **No new EventBus signals.**

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v13 → v14 migration | ChatGPT 5.2 | **Claude** (lossless) |
| 02 | New biome data (tundra, mineral_vent, swamp) + chemosynthesis_per_tick | ChatGPT 5.2 (schema) + Kilo (data) | Claude (balance) |
| 03 | Update species `biome_affinity` for new biomes | Kilo (data) | Claude |
| 04 | EventData.scope schema + EcologicalPressure filter + 4 new scoped events | ChatGPT 5.2 + Kilo | **Claude** (filter logic) |
| 05 | Mass extinction gameplay teeth | ChatGPT 5.2 | **Claude** (lifecycle) |
| 06 | EvolutionNodeData.requires_era + 5 new era-gated nodes | ChatGPT 5.2 + Kilo | Claude (balance) |
| 07 | Per-era visual identity (tile + background tint, biome textures) | ChatGPT 5.2 | Claude (mobile readability) |
| 08 | Discovery entries (~10) | **Claude voice text** | — |
| 09 | Phase 14b smoke test | you on device | — |

## Order of work

1. **02** (biomes) — species_affinity tables in brief 03 reference them.
2. **01** (save migration) — uses new schema fields for post-extinction state.
3. **03** (species affinity update) — populates new biome affinities on existing species.
4. **04** (event scope schema + content) — independent.
5. **06** (era-gated nodes) — independent.
6. **05** (mass extinction teeth) — depends on 01 (save) + 02 (biomes already shipped).
7. **07** (visuals) — late, after data settles.
8. **08** (discovery) — last content pass.
9. **09** (smoke test).

## Exit criteria

- Tundra / mineral_vent / swamp biomes render as distinct placeholder colors.
- Cryogenian polar_ice run dominated by tundra biome; volcanic_vent by mineral_vent; inland_swamp by swamp.
- Vent Archaeon yields measurably more on mineral_vent tiles (chemosynthesis + 1.8× affinity).
- Fungi runs never roll `herbivore_wave` (scope filter working).
- First post-extinction Devonian run opens at 0.5× yields, recovers over 120 ticks.
- Prestige after that run grants +25 EP Extinction Survivor bonus.
- Cryotolerance node purchasable only in Cryogenian; Vascular Network only in Devonian.
- Cryogenian = cool blue tint, Devonian = warm amber tint.
- 10 new discovery entries unlock per their triggers.
- Save v13 → v14 migration is lossless.

## Out of scope (Phase 15+)

- Per-era music tracks + crossfade.
- Era-transition VFX (particle / shader).
- Authored sprite art for biomes.
- Same-kingdom coinhabitation exceptions.
- Tile-level structures (Mycorrhizal Hub, Old-Growth Tree).
- Carboniferous + Permian eras.
- Animal HP system extensions (referenced by some Phase 14b events — payload field reserved for future).
