# Brief 04 — Author 12 new cross-kingdom evolution nodes

**Suggested agent**: Kilo for the mechanical `.tres` creation + `_index.tres` regeneration. Claude reviews cross-wing balance.

Read first:
1. `docs/PROGRESSION_WEB.md` — wing structure, sample chains, ~30% cross-wing target.
2. `docs/briefs/phase_9/02_schema_extensions.md` (schema additions must be live).
3. `docs/briefs/phase_9/03_tag_existing_nodes_and_gate.md` (existing nodes tagged).
4. `data/evolution_tree/` — existing 10 nodes, each `.tres` is the template.

## Goal
Add 12 new evolution nodes filling out the plantae / fungi / hybrid wings with cross-kingdom dependencies. Animal-wing nodes are deferred to Phase 10 (when the kingdom itself unlocks).

After this brief: total = 22 nodes. Cross-wing prereqs on mid+ tier nodes: 7 of ~14 mid+ nodes = 50% (slightly above the 30% floor in `PROGRESSION_WEB.md`, intentional to make the web feel dense).

## The 12 new nodes

Each is one `.tres` in `data/evolution_tree/<id>.tres`. Append all 12 to `_index.tres` in the order below.

### Plantae wing (3 new)

**`insectivory.tres`** — tier 1 plantae
- id: `&"insectivory"`, display: "Insectivory", desc: "You learn to eat what would eat you. Carnivore plantae niche becomes available in Phase 10."
- prerequisites: `[&"toxin_potency"]`
- meta_cost: `{"evolution_points": 6}`
- wing: `&"plantae"`, tier: `2`
- Note: scaffolds the carnivore niche slot. In Phase 9 the node just exists and is purchasable; its grant is a no-op until Phase 10 wires the niche.

**`soil_memory.tres`** — tier 2 plantae, cross-wing
- id: `&"soil_memory"`, display: "Soil Memory", desc: "Biomes that hosted past fungal runs yield 15% more biomass on plant colonization."
- prerequisites: `[&"efficient_photosynthesis"]`
- requires_kingdom_played: `[&"fungi"]`
- meta_cost: `{"evolution_points": 8}`
- wing: `&"plantae"`, tier: `2`
- Grant: handled via `MetaModifiers.is_unlocked(&"soil_memory")` — biomass-yield system multiplies by 1.15 when the flag is set. Hook lives in `scripts/systems/plantae_biomass_system.gd` (or wherever colonization yield resolves). Note in commit: "soil_memory yield hook landed in this brief alongside the node."

**`drought_resilience.tres`** — tier 3 plantae capstone
- id: `&"drought_resilience"`, display: "Drought Resilience", desc: "Plant tiles no longer wither during Drought events. The water that isn't there teaches you not to need it."
- prerequisites: `[&"pioneer_resilience"]`
- meta_cost: `{"evolution_points": 12}`
- wing: `&"plantae"`, tier: `3`
- Grant: handled via `MetaModifiers.is_unlocked(&"drought_resilience")` — drought event handler skips plantae-tile damage when set.

### Fungi wing (3 new)

**`saprophytic_efficiency_ii.tres`** — tier 2 fungi
- id: `&"saprophytic_efficiency_ii"`, display: "Saprophytic Efficiency II", desc: "Decomposition yields 20% more biomass from each consumed corpse."
- prerequisites: `[&"unlock_fungi"]`
- meta_cost: `{"evolution_points": 7}`
- wing: `&"fungi"`, tier: `2`
- Grant: `MetaModifiers` flag, multiplies the existing decomposition yield.

**`cordyceps_mastery.tres`** — tier 2 fungi, cross-wing
- id: `&"cordyceps_mastery"`, display: "Cordyceps Mastery", desc: "Fungi can parasitize what moves. The cordyceps niche becomes available in Phase 10."
- prerequisites: `[&"unlock_fungi"]`
- requires_kingdom_played: `[&"plantae"]`
- meta_cost: `{"evolution_points": 9}`
- wing: `&"fungi"`, tier: `2`
- Note: scaffolds the cordyceps niche slot. Like `insectivory`, the grant is a no-op until Phase 10.

**`spore_distribution.tres`** — tier 3 fungi capstone, cross-wing
- id: `&"spore_distribution"`, display: "Spore Distribution", desc: "Fungi colonization succeeds at range — adjacency no longer required. Three tiles per run may be 'seeded' anywhere within line-of-sight of an owned tile."
- prerequisites: `[&"saprophytic_efficiency_ii"]`
- requires_kingdom_played: `[&"plantae"]`
- meta_cost: `{"evolution_points": 14}`
- wing: `&"fungi"`, tier: `3`
- Grant: `MetaModifiers` flag + `RunState` per-run counter `spore_distribution_charges: int = 3`. The colonization-rule registry honors the flag for fungi rules. Implementation hook lives in `colonization_rules_registry.gd`'s `_rule_fungi_substrate` and a new alternate path. Note in commit: spore-charge bookkeeping shipped alongside this node.

### Hybrid wing (4 new)

**`endophytic_bridge.tres`** — tier 2 hybrid
- id: `&"endophytic_bridge"`, display: "Endophytic Bridge", desc: "Mycorrhizal fungi and plantae tiles share resources when adjacent. Both gain +0.2 biomass/tick from the partnership."
- prerequisites: `[&"unlock_mycorrhizal_fungi"]`
- requires_kingdom_played: `[&"plantae"]`
- meta_cost: `{"evolution_points": 10}`
- wing: `&"hybrid"`, tier: `2`
- Grant: `MetaModifiers` flag — read by both plantae and fungi biomass-yield resolution.

**`photosynthetic_network.tres`** — tier 3 hybrid
- id: `&"photosynthetic_network"`, display: "Photosynthetic Network", desc: "Light is shared across the wood-wide web. Plantae tiles connected via mycorrhizal substrate gain photosynthesis pooling."
- prerequisites: `[&"wood_wide_web"]`
- requires_kingdom_played: `[&"plantae", &"fungi"]`
- meta_cost: `{"evolution_points": 15}`
- wing: `&"hybrid"`, tier: `3`
- Grant: `MetaModifiers` flag.

**`symbiotic_generosity.tres`** — tier 2 hybrid
- id: `&"symbiotic_generosity"`, display: "Symbiotic Generosity", desc: "Symbiosis runs start with +10 biomass and +5 nutrients. The world remembers your partnerships."
- prerequisites: `[&"unlock_symbiosis"]`
- meta_cost: `{"evolution_points": 8}`
- wing: `&"hybrid"`, tier: `2`
- Grant: starting-resource bonus applied in `prestige_system.start_run` when `kingdom_id == &"symbiosis"`.

**`lichen_heritage.tres`** — tier 3 hybrid capstone
- id: `&"lichen_heritage"`, display: "Lichen Heritage", desc: "You may now play as Lichen — a single organism that is both plant and fungus. Unlocks in Phase 10."
- prerequisites: `[&"mutualism"]`
- requires_kingdom_played: `[&"plantae", &"fungi"]`
- meta_cost: `{"evolution_points": 18}`
- wing: `&"hybrid"`, tier: `3`
- Note: pure scaffolding for Phase 10. Purchasable in Phase 9 but produces no in-run effect yet. The player sees it as a "Phase 10 teaser" — intentional.

### Animals wing (2 new, both pure scaffolds)

**`unlock_animals.tres`** — tier 3 hybrid → animals gateway
- id: `&"unlock_animals"`, display: "Animal Genesis", desc: "Something climbed out of the water with a structure that could hold itself up. The animal kingdom unlocks in Phase 10."
- prerequisites: `[&"insectivory", &"cordyceps_mastery"]`
- requires_kingdom_played: `[&"plantae", &"fungi"]`
- meta_cost: `{"evolution_points": 20}`
- wing: `&"animals"`, tier: `1`
- grants_kingdoms: `[]` — Phase 10 changes this to `[&"animals"]`. For Phase 9 the node is purchasable but unlocks nothing.

(Only 1 animal-wing node in Phase 9. The wing exists in the UI as a placeholder column; Phase 10 fills it in.)

## `_index.tres` update

Add 11 new `ext_resource` lines (ids 12–22) and extend the `nodes` array. Order doesn't matter for runtime but keep it alphabetical-ish within each wing for human scanability.

Verify after: `EvolutionTreeIndex.nodes.size() == 22`.

## Balance review checklist (for Claude diff review)

- [ ] Mid+ tier nodes with cross-wing prereqs: `soil_memory`, `cordyceps_mastery`, `spore_distribution`, `endophytic_bridge`, `photosynthetic_network`, `lichen_heritage`, `unlock_animals` = 7. Total mid+ tier nodes after this brief: 4 (existing) + 10 (new) = 14. Cross-wing share: **50%** — above 30% floor, deliberately busy.
- [ ] Every wing has at least one entry-tier and one capstone-tier node.
- [ ] Highest cost is `unlock_animals` at 20 EP. With current `calculate_prestige_reward(biomass) = sqrt(biomass / 10)`, that's ~5–10 runs of grinding — appropriate for a kingdom unlock.
- [ ] No node grants a content unlock that doesn't exist (kingdoms/niches gated by `MetaModifiers` flags read by systems that exist).
- [ ] Pure-scaffold nodes (`insectivory`, `cordyceps_mastery`, `lichen_heritage`, `unlock_animals`) are clearly marked in their description as "Phase 10" to set player expectations.

## Acceptance criteria
- [ ] 12 new `.tres` files exist with correct schema.
- [ ] `_index.tres` references all 22.
- [ ] `MetaModifiers.is_unlocked(&"<id>")` returns the right flag for each purchased node (regression: the registry should pick up new flags automatically since it reads `meta.evolution_tree`).
- [ ] System hooks land in the same brief commit as the data: `soil_memory` yield bonus, `drought_resilience` damage skip, `saprophytic_efficiency_ii` yield bonus, `spore_distribution` ranged colonization + charge counter, `endophytic_bridge` mutual bonus, `photosynthetic_network` flag-only (no system hook needed in Phase 9; placeholder), `symbiotic_generosity` start_run bonus.
- [ ] Smoke: cold load → buy `thrifty_growth` → confirm 22 nodes render (UI rebuild in brief 05; pre-brief-05 the old grid will just show them stacked).

## Out of scope
- Tree-visualization UI (brief 05).
- Wiring `insectivory` / `cordyceps_mastery` / `unlock_animals` to actual gameplay (Phase 10).
- Lichen species (Phase 10).
- Animal kingdom content (Phase 10).
- Discovery entries for these nodes (brief 07 authors them).
