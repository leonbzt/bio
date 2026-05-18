# Brief 00 — Phase 14a entry (species roster + biome affinity foundation)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 13 (species-first migration) complete + smoke-tested.
- [ ] `docs/SPECIES_MODEL.md` and `docs/SPECIES_ROSTER.md` read.
- [ ] Save at `save_version: 12`.

## What Phase 14a is

The species-first model unlocked the *capability* for a meaningful roster. Phase 14a builds it. **Content phase, not architectural** — adds new species, schema fields for biological grounding, and the biome-affinity yield system.

Five deliverables:

1. **Schema additions**: `SpeciesData.biome_affinity`, `latin_name`, `lineage_id`.
2. **Species roster**: 5 new species (4 Cryogenian + 3 Devonian — see SPECIES_ROSTER.md). Existing 7 gain Latin tooltips + lineage ids + biome affinity values.
3. **Biome affinity yield integration**: `GrowthSystem` multiplies in per-tile affinity.
4. **Pioneer tag predicate**: `pioneer`-tagged species can colonize bare tiles without adjacency (Cyanobacterial Mat, Vent Archaeon need this).
5. **Discovery entries**: 5 new species + 3 lineage-milestone entries.

Phase 14b separately delivers era teeth (biomes, mass extinction, era nodes, per-era visuals).

## Decisions locked

From conversation 2026-05-18:

1. **Layered tier rollout** — Tier 1 ships ~15 species; future eras add to 40-60 (Phase 15+).
2. **Hybrid era gating** — most species span eras (`era_requires = &""`); a few signature species are era-locked.
3. **Soft biome preference** — yield multiplier per biome, not hard placement gate. Default 1.0.
4. **Hybrid naming** — `display_name` poetic + `latin_name` shown in tooltip.
5. **Real paleo anchoring** — Cryogenian + Devonian roster ties to actual lineages (see SPECIES_ROSTER.md).
6. **`lineage_id` as a tag, not a separate resource** — string grouping, surfaces in discovery log.

## Contracts landing in Phase 14a

- **`SpeciesData` gains** `biome_affinity: Dictionary`, `latin_name: String`, `lineage_id: StringName`.
- **`GrowthSystem._apply_yields`** multiplies in `species.biome_affinity.get(biome.id, 1.0)`.
- **`ColonizationRulesRegistry`** recognizes `pioneer` tag (skips adjacency requirement on bare tiles).
- **Save schema v12 → v13** — adds `meta.lineages_played: Array[String]` for the lineage milestone tracker.
- **`EventBus.species_introduced`** carries lineage info via lookup (no new signal).
- **5 new `.tres` species files**: cyanobacterial_mat, vent_archaeon, cryo_lichen, tree_fern_stem, wood_rot_bracket.
- **Existing 7 species files** updated with latin_name, lineage_id, biome_affinity.
- **Existing 6 ecosystem files** updated: `starting_species_filter` expanded with new species per the SPECIES_ROSTER.md table.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v12 → v13 migration | ChatGPT 5.2 | Claude (lossless) |
| 02 | SpeciesData schema additions | ChatGPT 5.2 | Claude |
| 03 | Existing species update (latin/lineage/affinity) | Kilo (data) | Claude (audit) |
| 04 | 5 new species files | Kilo (data) + Claude voice text | Claude |
| 05 | Biome affinity yield integration | ChatGPT 5.2 | **Claude** (yield math) |
| 06 | Pioneer tag predicate in ColonizationRulesRegistry | ChatGPT 5.2 | Claude |
| 07 | Discovery entries: 5 species + 3 lineage milestones | **Claude voice text** | — |
| 08 | Phase 14a smoke test | you on device | — |

## Order of work

1. **02** (schema) — everything else needs the new fields.
2. **01** (save migration) — uses the new schema.
3. **03** (existing species update) — populates lineage_id + biome_affinity on what's already there.
4. **04** (new species files) — adds the 5 newcomers.
5. **05** (yield integration) — wires biome_affinity into the tick loop.
6. **06** (pioneer tag) — enables new species placement rules.
7. **07** (discovery) — content for unlocks.
8. **08** (smoke test).

## Exit criteria

- All 12 species (existing 7 + 5 new) load with latin_name + lineage_id + biome_affinity populated.
- Picker shows new species in their eligible ecosystems.
- Cyanobacterial Mat on tundra yields measurably more than Cyanobacterial Mat on swamp (biome affinity working).
- A `pioneer`-tagged species can place on a bare tile without an adjacent owned tile (rule wired).
- Cryo-Lichen recipe places cyanobacterial_mat + mycelium_thread atomically.
- Lineage milestone discovery fires after cultivating species from 2 ecosystems sharing a lineage.
- Save v12 → v13 migration is lossless.

## Out of scope (Phase 14b)

- New biomes (tundra, mineral_vent, swamp) — Phase 14b.
- Mass extinction gameplay teeth — Phase 14b.
- Era-gated evolution nodes — Phase 14b.
- Per-era visual identity (tile tint, background tint) — Phase 14b.
- Axis-scoped events + new event content — Phase 14b.
- Predator cascade / nitrogen fixation / allelopathy predicates — Phase 15.
- Carboniferous + Permian species — Phase 15+.
