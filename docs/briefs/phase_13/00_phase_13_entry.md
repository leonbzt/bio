# Brief 00 — Phase 13 entry checklist (species-first migration)

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 12 smoke test passed (era + ecosystem flow, mass extinction narrative, world map UI).
- [ ] Fungi-only Cryogenian start can earn EP (commit `5a23aca`).
- [ ] `docs/SPECIES_MODEL.md` read and Locked Decisions 11-20 understood.
- [ ] Save at `save_version: 11`.

## What Phase 13 is

**An architectural reshape, not a content phase.** Phase 13 collapses the current kingdom/niche/species triple into a single first-class entity (species), with kingdom demoted to a tag and niche demoted to a runtime-derived label. The migration enables multi-species coinhabitation, in-run species introduction, and unblocks every Tier 2+ content phase.

**Exit criterion is behavior parity**: every Phase 12 gameplay path still works in the new model — no new visible content, just a cleaner foundation.

Six structural deliverables:

1. **`SpeciesData` extension** — placement_rule, introduce_cost, kingdom_id as tag, tags array, recipe_components, rendering hints.
2. **`EcosystemData` reshape** — biome_recipe + cluster_size replace biome_preference; species/biome completion gates replace niche/kingdom gates.
3. **`TerritorySystem` per-tile shape** — `occupants: Dictionary[StringName, StringName]` (kingdom → species) replaces `surface_owner` + `subsurface_owner`.
4. **`GrowthSystem` generalization** — ticks all introduced species in a run, not "the kingdom"; layered-species branch deleted.
5. **`ColonizationRulesRegistry` reorientation** — reads species directly; recipe rule added; niche dependency removed.
6. **Run flow rebuild** — world map → ecosystem → starting-species picker → in-run "Introduce species" panel; niche selector deleted.

Plus: save migration v11 → v12, niche-file deletion, rendering update (base color + animal border), discovery-entry re-categorization, smoke test.

## Decisions locked

See `docs/SPECIES_MODEL.md` Locked Decisions 1-20. Key items for implementation:

- **One species per kingdom per tile** (LD 11). Default rule; exceptions deferred.
- **Lichen as recipe** (LD 12). `lichen_common` species gains `placement_rule = &"recipe"` and `recipe_components = [&"pioneer_grass", &"mycelium_thread"]`. Layer fields deleted.
- **Introduction costs lean heavy** (LD 13). ≈10× per-tile cost, smoke-test for final tuning.
- **Diversity multiplier on prestige** (LD 14). ×1.0 / ×1.1 / ×1.2 for 1 / 2 / 3+ species cultivated.
- **Niche files deleted cleanly** (LD 15) — no inert metadata.
- **Atomic recipe placement** in v1 (LD 16). Recipe fails entirely if any component slot is occupied or any component rule rejects.
- **`species.tags: Array[StringName]`** (LD 17). Authored tags drive interaction predicates. Default empty.
- **Tile rendering**: plantae/fungi share base color (blended for both); animals border (LD 18).
- **Biological additions** (LD 20) — schema lands in Phase 13 (tags + tick_effects array); concrete predicates ship incrementally across Phases 13-15.

## Contracts landing in Phase 13

- **Save schema v11 → v12** with `species_unlocked`, `species_played`, `starting_species_id`, `unlocked_species_in_run`, reshaped `tiles[].occupants` dict.
- **`SpeciesData` schema** gains: `placement_rule`, `placement_targets`, `introduce_cost`, `unlock_ep_cost`, `unlock_prerequisites`, `era_requires`, `recipe_components`, `tags`, `tile_marker_color`, `tile_marker_shape`. Loses: `layer_count`, `layer_species`.
- **`EcosystemData` schema** gains: `biome_recipe`, `biome_cluster_size`, `starting_species_filter`, `completion_required_species`, `completion_required_biome`. Loses: `biome_preference`, `completion_required_niche`, `completion_required_kingdom`.
- **`TerritorySystem`** per-tile state shape changes; public API (`add_surface`, `get_surface_owner`, etc.) deprecated → replaced by `add_occupant(coord, kingdom_id, species_id)` / `get_occupant(coord, kingdom_id)`.
- **`EventBus` signals**: `niche_changed` deleted. `species_introduced(species_id: StringName)` added.
- **`GameState` fields**: `current_niche_id` deleted. `current_kingdom_id` kept as denormalized read-only mirror of `starting_species.kingdom_id` for backward-compat during the migration; flagged for deletion in Phase 14.
- **`MultiLayerPlacement` autoload removed**. Recipe placement lives in `ColonizationRulesRegistry`.
- **`parasite_steal_system.gd` + `parasite_decay_system.gd` deleted**. Their behavior moves into a generic per-species `tick_effects` framework on `GrowthSystem`.
- **All `data/niches/*.tres` files deleted**. Their contents fold into the matching species (typically the first entry in their `species_options`).

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v11 → v12 migration | ChatGPT 5.2 | **Claude** (lossless tile transform) |
| 02 | SpeciesData schema extension | ChatGPT 5.2 | Claude (contracts) |
| 03 | EcosystemData reshape + biome recipe data | ChatGPT 5.2 (schema) + Kilo (data) | Claude |
| 04 | TerritorySystem per-tile shape rewrite | ChatGPT 5.2 | **Claude** (state correctness) |
| 05 | GrowthSystem generalization + tick_effects | ChatGPT 5.2 | **Claude** (yield math) |
| 06 | ColonizationRulesRegistry reorientation + recipe rule | ChatGPT 5.2 | Claude |
| 07 | Run flow rebuild (world map + species picker + introduce panel) | ChatGPT 5.2 | Claude (mobile layout) |
| 08 | Niche deletion + species content folding | Kilo (data) | Claude (audit) |
| 09 | Tile rendering update (base color + animal border) | ChatGPT 5.2 | Claude (mobile readability) |
| 10 | Discovery entry re-categorization + diversity prestige | Kilo (data) + ChatGPT (prestige multiplier) | Claude |
| 11 | Phase 13 smoke test (behavior parity) | you on device | — |

## Order of work

The dependency chain is strict — get briefs in this order:

1. **02** (SpeciesData schema) — everything else needs the new fields.
2. **03** (EcosystemData reshape + biome data) — independent, but better land before 07's world map.
3. **01** (save migration) — needs both new schemas to know what to migrate to. Runs the v11 transform.
4. **08** (niche → species folding) — needs the new species fields to fold niche content into. Deletes the niche data files.
5. **04** (TerritorySystem shape) — needs the new species data so tile state references known species.
6. **06** (ColonizationRulesRegistry) — needs new TerritorySystem API + new species placement rules.
7. **05** (GrowthSystem generalization) — needs new TerritorySystem + new species data.
8. **07** (run flow rebuild) — needs everything upstream to be in place to wire UI to.
9. **09** (rendering) — independent after 04; can interleave.
10. **10** (discovery + prestige diversity) — after 07.
11. **11** (smoke test) — last.

## Exit criteria

- All gameplay paths from Phase 12 work identically (see Phase 13 smoke test).
- Save migration is lossless for the common Phase 12 cases.
- `data/niches/` is empty (folder removed). `MultiLayerPlacement` autoload removed. `parasite_steal_system.gd` + `parasite_decay_system.gd` deleted.
- `GameState.current_niche_id` does not exist. `GameState.current_kingdom_id` is read-only-derived.
- No new visible content (Phase 14 owns content).
- The "Introduce species" UI panel exists and works mechanically, even if the per-run progression curve isn't fully balanced.

## Out of scope (Phase 14+)

- New biomes (tundra, mineral_vent, swamp) — Phase 14.
- Per-era visual tinting — Phase 14.
- Mass extinction gameplay teeth — Phase 14.
- Era-gated evolution nodes — Phase 14.
- New species beyond folding existing niches into species — Phase 14.
- Concrete biological-interaction predicates (nitrogen fixation, allelopathy, etc.) — Phase 14-15.
- 3-component recipes (Coral, Termite Mound) — Phase 15.
- Multi-tile structures (Mycorrhizal Hub, Old-Growth Tree) — Phase 15+.
- Same-kingdom-tile coinhabitation exceptions (tree + vine on one tile) — future tier.
