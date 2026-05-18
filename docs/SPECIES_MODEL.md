# Species-First Model

> Architectural reshape locked 2026-05-18. Collapses kingdom/niche/species into a single first-class entity (**species**), with **kingdom** demoted to a tag and **niche** demoted to an emergent label. Enables multi-species coinhabitation on the map and in-run species unlocks. Foundation for Tier 2+ content.

## Why this exists

The current model has three tensions the gameplay can't grow past:

1. **Niche overlaps with ecosystem.** "Parasitic plantae" describes how a species behaves in a network-rich biome — i.e., a species-biome interaction, not a kingdom subtype.
2. **Layered species is special-cased.** Lichen needed bolt-on fields (`layer_count`, `layer_species`) and a dedicated autoload (`MultiLayerPlacement`). Coral and Termite Mound would each need their own bolts.
3. **One run = one kingdom** fights the long-arc ecological identity. Cross-species interactions can't emerge because a run only contains one species.

The species-first model collapses these into a single concept and makes cross-species interaction the *default* state of the world.

## Locked decisions

From conversation 2026-05-17 → 2026-05-18:

1. **Adapt the existing codebase**, do not restart. Behavior parity is the migration exit criterion.
2. **Species is the first-class entity.** Kingdom is a tag; niche is an emergent label.
3. **Multi-species per tile is the default.** Rendered via color blending / stacked borders / opacity per occupant — exact visual treatment chosen during implementation.
4. **EP unlocks species permanently; existing in-run resources (biomass, spores, decay, nutrients) pay per-tile colonization costs.** No new currency.
5. **Identity anchor = starting species.** The run is "about" the species you picked at start. New species introduced mid-run extend the ecosystem but don't displace the run's identity.
6. **World choice enforces identity** — picking a world filters which starting species are eligible. A polar-ice world lets you start as fungi or cold-adapted plantae; not as a predator.
7. **Ecosystems are biome recipes**, not single-biome zones. Each ecosystem authors a weighted biome mix + cluster-size hint; biomes emerge from generation deterministically per `run_seed`.
8. **Kingdom interactions retain mechanical teeth.** Herbivore-tagged species eat plantae-tagged tiles. Plantae+fungi on one tile is symbiosis. These stay species-tag-driven, not pure-emergent.
9. **Goals stay biome/interaction-keyed**, not niche-keyed. ("Survive 2 events on swamp tiles" works; "complete via parasite niche" doesn't survive.)
10. **Active interventions** (Irrigate, Bundle, Cull, etc.) tied to ecosystem-level events, not niche-level state.

From conversation 2026-05-18 (Q1-Q7 + inline notes):

11. **One species per kingdom per tile** (Q1) — exceptions may be authored in a future tier (e.g., tree + vine coinhabiting), opt-in via a species flag. Default keeps tile state simple.
12. **Lichen-as-recipe** (Q2, proposal B) — recipe species place all components atomically in one input.
13. **Introduction costs lean heavy** (Q3) — ≈10× per-tile cost. Each species introduction is a deliberate run-shaping commitment, not a casual addition.
14. **Diversity multiplier on prestige** (Q4) — ×1.0 / ×1.1 / ×1.2 for 1 / 2 / 3+ cultivated species.
15. **Niche files deleted cleanly** in the migration phase (Q5) — no inert-metadata half-state.
16. **Atomic recipe placement** in v1 (Q6) — partial placement (one component lands, the other doesn't) deferred as a future-tier emergent mechanic.
17. **`species.tags: Array[StringName]` field** (Q7) — authored tags (herbivore, predator, parasite, pioneer, nitrogen_fixer, etc.) used by interaction predicates. Default empty.
18. **Tile rendering** (user note in §Rendering) — plantae/fungi share the **base tile color** (or a blended third color when both occupy); animals render as a **border** around the tile, not a fill.
19. **Future tree split** (user note on proposal E) — single evolution tree in v1; species-unlock branch can split into its own UI in a later tier as the tree grows.
20. **Biological realism pass** (user note in §Interactions) — interaction matrix expanded to include nitrogen fixation, allelopathy, succession, seed dispersal, decomposer cascade, and apex-predator cascade. See expanded matrix below. Additions ship incrementally across Phases 13–15, not all at once.

## Proposed in this doc (resolved 2026-05-18 — see Locked Decisions 11-20)

These are not yet locked — call out anything to change:

A. **One species per kingdom per tile.** A tile state is a dict `{kingdom_id → species_id}`. Two plantae species can't share a tile (one ecological role per layer); plantae + fungi can; plantae + fungi + animals can. 
Notes: this makes a lot of sense, but maybe there could be exceptions, or roles that exclude each other (but tree and vine can both be there.) propbably easiest to make one per tile

B. **Lichen becomes a recipe, not a species.** "Common Lichen" is a one-tap shortcut that places `pioneer_grass` on the plantae slot AND `mycelium_thread` on the fungi slot. No `layer_count` field needed.
good


C. **Per-species `introduce_cost`** — a one-shot per-run resource cost to "invite" an unlocked species into the current run. Pays for nothing visible; gates *adding the species to your placeable pool this run*. Then normal per-tile costs apply. The starting species has `introduce_cost = {}`.
notes: i like the idea, but its not an urgent addition object to balancing

D. **Each kingdom has a free default starter species** (plantae=pioneer_grass, fungi=mycelium_thread, animals=common_grazer). Other species in that kingdom are unlocked via EP. Era filters which kingdoms (and therefore which starters) are eligible. 
good

E. **Single evolution tree** still — species unlocks fold into `EvolutionNodeData` via existing `grants_kingdoms`-style field renamed to `grants_species`. No second UI tree.
I think it makes sense that in the future the evolution tree gets more organized, and unlockable species make sense to sperate in a way. 

F. **Niche as a runtime-derived label**, surfaced only in HUD/discovery for flavor. Computed by querying current state: "this run's dominant decomposer is mycelium_thread." Not a selection, not a save field.


## Core concepts

### Species — first-class

```gdscript
class_name SpeciesData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# The kingdom tag. Mechanically meaningful: drives interaction predicates
# (herbivore eats plantae-tagged tiles), per-tile slot assignment (one
# species per kingdom per tile), and era filtering. NOT a run-state field.
@export var kingdom_id: StringName = &""

# Traits + numbers — unchanged from current SpeciesData.
@export var sprite: Texture2D
@export var base_traits: Array[TraitData] = []
@export var tick_yield: Dictionary = {}   # {resource_id: float}

# Costs.
@export var introduce_cost: Dictionary = {}      # one-shot per run, in run resources
@export var colonize_cost: Dictionary = {}       # per-tile placement cost

# Placement rule (moved off NicheData). Values:
# &"adjacent_empty", &"fungi_substrate", &"parasitic_plantae",
# &"mycorrhizal_fungi", &"animal_anchor", &"recipe" (Lichen-style).
@export var placement_rule: StringName = &"adjacent_empty"

# Optional placement-rule parameters (replaces niche.parasitic_targets).
@export var placement_targets: Array[StringName] = []

# Unlock cost in EP (replaces evolution-node grants_kingdoms approach).
@export var unlock_ep_cost: int = 0
@export var unlock_prerequisites: Array[StringName] = []   # other species ids

# Era gate. Empty = always available (subject to kingdom availability).
@export var era_requires: StringName = &""

# Recipe species: places these other species in their respective kingdom
# slots in a single tap. Empty = normal species.
@export var recipe_components: Array[StringName] = []

# Visual rendering hint when multiple species share a tile.
@export var tile_marker_color: Color = Color(1, 1, 1, 1)
@export var tile_marker_shape: StringName = &"square"   # square|circle|cross|leaf|spore
```

`layer_count` and `layer_species` are **removed**. Recipes replace them.

### Kingdom — a tag, not a runstate

Mechanical roles for `kingdom_id`:
- **Tile slot assignment**: a tile has at most one species per kingdom occupying it.
- **Interaction predicates**: herbivore-tagged species eat plantae-tagged tiles; plantae+fungi co-occupancy fires the symbiosis bonus.
- **Era filtering**: `EraData.available_kingdoms` filters which kingdoms appear in the species picker for that era.
- **UI grouping**: species picker groups by kingdom.

What kingdom is NOT anymore:
- A field in `GameState` (no more `current_kingdom_id`).
- A selection step (you pick a species; its kingdom is data).
- A unit of save tracking (no more `kingdoms_played`; replaced by `species_played`).

### World & Ecosystem — the map you play on

Renamed mental model: **a run takes place on a *world*, which is an instance of an *ecosystem* with a seed.** The world map UI shows ecosystem cards within era tabs (mostly unchanged from Phase 12).

`EcosystemData` reshapes:

```gdscript
class_name EcosystemData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var era_id: StringName = &""

# Biome recipe — weighted mix + cluster-size hint for procedural generation.
@export var biome_recipe: Dictionary = {}        # {biome_id: weight_float}
@export var biome_cluster_size: float = 1.0      # 1.0 = scattered, higher = patchier

# Eligible starting species. Players pick from filter ∩ unlocked species.
# Empty = all unlocked species eligible (default for permissive ecosystems).
@export var starting_species_filter: Array[StringName] = []

# Completion criterion (Phase 12 fields preserved).
@export var completion_criterion: StringName = &""
@export var completion_target: float = 0.0
# Phase 13 reshape: completion gates by species/biome/interaction, not niche.
@export var completion_required_species: StringName = &""
@export var completion_required_biome: StringName = &""

@export var unlock_text: String = ""
@export var complete_text: String = ""
```

Removed: `biome_preference` (replaced by `biome_recipe`), `completion_required_niche` and `completion_required_kingdom` (replaced by `completion_required_species` + `completion_required_biome`).

### Biome — per-tile, emergent within an ecosystem

`BiomeData` schema unchanged (`sunlight_per_tick`, `nutrient_per_tick`, `decay_per_tick`, `chemosynthesis_per_tick`). What changes is generation:

```
NutrientSystem._generate_biome_map(ecosystem, seed):
  rng = seed
  for each cell:
    if rng.randf() < cluster_threshold and neighbor has biome:
      copy neighbor biome  # cluster bias
    else:
      pick weighted from ecosystem.biome_recipe
```

Higher `biome_cluster_size` produces patchier maps (large contiguous biome regions); lower produces scattered mixes. The ecosystem still has identity ("Cryogenian volcanic vent feels like a vent") but biomes within it emerge per-seed.

### Era — temporal gate

`EraData` mostly unchanged. `available_kingdoms` filters which kingdoms' species are eligible in this era. Optional per-species `era_requires` field overrides for fine-grained gating (a species that only appears in Devonian regardless of its kingdom).

### Niche — derived runtime label

No `NicheData` resource. No `current_niche_id` save field. No niche selector in the UI.

The word "niche" still appears in:
- **Discovery log labels**: "You played as a decomposer" — computed from runtime state ("the dominant fungi species in this run produced mostly decay → decomposer").
- **Goal flavor text**: "Cull the parasites" — describes interactions, not selections.
- **Player-facing tooltips**: "Mycelium Thread tends to fill the decomposer niche in nutrient-rich biomes."

Implementation: a `NicheClassifier` helper (utility, not autoload) that examines a species + its current biome and returns a descriptor StringName. Used purely for UI and discovery flavor.

## Per-tile state

### Kingdom-slot model

```gdscript
# Per-tile state in TerritorySystem
{
    "occupants": {                       # kingdom_id → species_id
        &"plantae": &"pioneer_grass",
        &"fungi": &"mycelium_thread"
    },
    "data": {                            # arbitrary tile metadata (mycorrhizal_bond, etc.)
        "mycorrhizal_bond": true
    }
}
```

A tile is **occupied** if `occupants` is non-empty. A tile is **owned by kingdom X** if `occupants` contains key X. A tile is **owned by species Y** if `occupants` contains a value equal to Y.

Replaces: `surface_owner`, `subsurface_owner`. The 3-layer TileMap rendering survives — surface layer renders the topmost kingdom's species, subsurface renders fungi's species, the new "animals" layer renders animal species. Within a layer, the species' `tile_marker_color` and `tile_marker_shape` provide visual identity.

For rendering coexisting kingdoms on the same tile, the layered TileMap already supports stacking; species variants are picked by atlas tile + modulate per species.

### Placement rules — on species, not niches

`SpeciesData.placement_rule` is the dispatch key. Same registry (`ColonizationRulesRegistry.evaluate`), same five rules:

- `adjacent_empty` — default plant/animal style; first tile free, subsequent tiles adjacent to own.
- `fungi_substrate` — adjacent to own OR on plantae slot OR on corpse.
- `parasitic_plantae` — adjacent to *any* owned tile (own or other species').
- `mycorrhizal_fungi` — must place on or adjacent to a plantae-occupied tile.
- `animal_anchor` — first tile free; subsequent adjacent to any owned.

New rule:
- `recipe` — for recipe species (Lichen, Coral). Places the components into their kingdom slots simultaneously; valid iff each component's own rule validates against its target slot.

The registry stops reading `NicheData` (deleted). Each rule reads species + tile + territory only.

### Coinhabitation rules

A species can be placed on a tile iff:
- Its kingdom slot is **empty** on that tile, AND
- Its own placement rule validates, AND
- No occupant on the tile has a `blocks_coinhabit: Array[StringName]` listing this species' kingdom or id.

This blocks *exceptional* cases (e.g., a predator that locks its tile to itself) while keeping the default permissive.

For Tier 3 we may add inter-species *competition* mechanics (placing a second plantae onto a tile evicts the first if it has higher fitness). Out of scope for the migration phase.

## Run flow

### Start

1. **World map** (existing UI, light reshape): era tabs → ecosystem cards. Same as Phase 12.
2. **Pick ecosystem** — confirms era + locks the world's `seed`. Procedural generation hasn't run yet.
3. **Starting species picker** — shows species in `ecosystem.starting_species_filter ∩ unlocked_species`. Defaults to first unlocked species in the filter if the player taps "Begin".
4. **Confirm** → `run_save.starting_species_id = picked`; `run_save.unlocked_species_in_run = [picked]`; `NutrientSystem._generate_biome_map(ecosystem, seed)` runs.

`run_save.kingdom_id` is **derived** from the starting species's `kingdom_id`, kept as a denormalized field for fast lookup. Not used as a selection input.

### Mid-run

1. Place starting species tiles using starting resources (e.g., the existing `starting_resources` flow).
2. Tick: species produces resources per `tick_yield` × per-tile interaction bonuses (symbiosis, mycorrhizal bond, parasite steal, biome multipliers, ambient modifiers).
3. Resources accumulate. **Species introduction**: when the player has enough resources to afford another unlocked species's `introduce_cost`, the UI shows that species as "Introduce" in the species panel.
4. Player taps "Introduce X" → pays `introduce_cost` from current ledger → species added to `run_save.unlocked_species_in_run`. Player can now place tiles of X.
5. New species tiles placed → cross-species interactions emerge per the interaction matrix.
6. Optional: introduce more species, build out the ecosystem.

### End

Prestige: EP reward computed from **total biomass earned this run across all species combined** (existing math: `sqrt(total_biomass / 10)`), with a diversity multiplier:
- `× 1.0` for 1 species cultivated.
- `× 1.1` for 2 species.
- `× 1.2` for 3+ species.

The starting species is highlighted on the prestige summary ("You cultivated 4 species from a beginning of pioneer_grass.").

### Run identity in UI

- HUD top-left always shows: starting species name + ecosystem name. ("Pioneer Grass — Devonian Forest Edge.")
- Discovery entries fire on first introduction of each new species in a run.
- Prestige screen records `starting_species_id` per past run.

## Progression

### Species unlock tree (folded into evolution tree)

`EvolutionNodeData` gains a `grants_species: Array[StringName]` field. Existing `grants_kingdoms` is **deprecated** but kept for backward compatibility during migration — unlocking a kingdom now means "auto-unlocks that kingdom's default starter species."

Most existing "unlock_X" nodes translate cleanly:
- `unlock_fungi` → grants_species `[mycelium_thread]` (the default fungi starter).
- `unlock_animals` → grants_species `[common_grazer]`.
- `unlock_mycorrhizal_fungi` → currently grants the niche; becomes `grants_species: [mycelium_thread_mycorrhizal_variant]` (a new species that's a mycorrhizal-leaning mycelium with `placement_rule: &"mycorrhizal_fungi"`).
- `unlock_parasitic_plantae` → grants_species `[bramble]` (the parasitic plantae species — already authored as a species).
- `unlock_symbiosis` (already redirected to lichen) → grants_species `[lichen_common]` as a recipe species.

Other evolution nodes (trait grants, ability unlocks, ambient modifiers) stay unchanged.

### Per-run species introduction

The "introduce" cost is the **gameplay teeth of the in-run progression loop**. Suggested costs (tunable):

| Species | introduce_cost (per run) |
|---|---|
| pioneer_grass (default starter) | `{}` (always free) |
| mycelium_thread (default starter) | `{}` |
| common_grazer (default starter) | `{}` |
| bramble (parasite plantae) | `{biomass: 80}` |
| mycelium_thread_mycorrhizal | `{spores: 50, biomass: 30}` |
| lichen_common (recipe) | `{biomass: 120, spores: 50}` |
| common_predator | `{biomass: 100, protein: 30}` |

Introduce cost ≈10× per-tile cost (Locked Decision 13). Introducing a species is a deliberate run-shaping decision — players commit a meaningful chunk of accumulated resources to expand their ecosystem, not a casual button press. Final balancing is a smoke-test pass.

The starting species has `introduce_cost = {}` (you don't pay to use what you started with).

### Per-tile placement costs

Unchanged in shape: `SpeciesData.colonize_cost: Dictionary`. Each per-tile placement pays this from the run ledger. `MetaModifiers.is_unlocked(&"thrifty_growth")` and similar discounts still apply.

The legacy `niche.cost_override` field disappears (niche data is deleted). If a species needs context-specific costs by biome, that's a future-tier extension.

## Interactions
Research and add more biological realistic interactions

### Kingdom-tagged (mechanical teeth)

| Interaction | Predicate | Effect |
|---|---|---|
| Symbiosis | tile has plantae-slot occupant AND fungi-slot occupant | biomass yield × (1 + symbiosis_bonus) for plantae and fungi |
| Wood-wide-web | tile adjacent to a symbiosis tile (with `wood_wide_web` node) | adjacent biomass × 1.15 |
| Endophytic bridge | tile of kingdom A adjacent to tile of kingdom B (`endophytic_bridge` node) | +0.2 biomass to A's tile |
| Herbivore consumption | animal species tagged "herbivore" tag adjacent to plantae-slot tile | herbivore drains plantae biomass tick-over-tick |
| Predator consumption | animal species tagged "predator" tag adjacent to herbivore-tagged tile | predator hunts herbivore (Phase 14 polish) |

The `species.kingdom_id` plus optional `species.tags: Array[StringName]` (a new field — herbivore/predator/parasite/etc.) drive predicate matching.

### Species-specific

| Mechanic | Where it lives | Trigger |
|---|---|---|
| Parasite steal | per species with `placement_rule: &"parasitic_plantae"` AND `placement_targets` set | per tick: each owned tile gains `0.2 × neighbor_count_in_targets` biomass |
| Mycorrhizal bond | per species with `placement_rule: &"mycorrhizal_fungi"` | bond flag stamped on tile data when placed on plantae slot; tile yields × 1.20 |
| Spore-distribution charge | meta node `spore_distribution` | per-run charges for non-adjacent fungi placement |
| Corpse substrate | `placement_rule: &"fungi_substrate"` + corpse_system check | fungi can colonize corpse tiles |

These move off niche-keyed systems (`parasite_steal_system.gd`, `parasite_decay_system.gd`) onto a generic per-species per-tick effect framework. Implementation hint: each species declares `tick_effects: Array[StringName]` (e.g., `[&"parasite_steal", &"corpse_decay"]`); a per-effect handler runs each tick over the species's owned tiles.

### Emergent

When two species coinhabit a tile without any specific predicate firing, **no special effect by default**. The kingdom-tagged matrix above handles the cases that *should* be emergent (symbiosis, predation). Avoid invisible bonus stacking.

### Biologically grounded additions

Each addition below maps to a named real-world ecological phenomenon. All are tag-driven (`species.tags`) so authoring a new interaction is one tag + one predicate handler. Additions ship **incrementally** across Phases 13–15 (migration phase only lands the tag schema; concrete predicates land alongside the species that use them).

| Interaction | Biological reference | Predicate | Effect |
|---|---|---|---|
| Nitrogen fixation | Legume + rhizobium | species tagged `nitrogen_fixer` placed | +0.1 nutrient_per_tick on adjacent tiles |
| Allelopathy | Eucalyptus, walnut | species tagged `allelopath` placed | adjacent non-self species yields × 0.9 |
| Pioneer succession | Lichen, moss, alder | species tagged `pioneer` placed | ignores normal adjacency rule; can colonize bare biome from anywhere |
| Successor requirement | Climax-forest species | species tagged `successor` placed | requires tile to have prior occupation history (corpse, decay, or `colonization_history > 0`) |
| Seed dispersal | Frugivorous birds + mammals | plantae species placed within range of own animal tile | ignores adjacency requirement (animal carried the seed) |
| Decomposer cascade | Saprotrophic fungi enriching soil | fungi-slot tile present | slow buildup of `nutrient_per_tick` on the biome under the tile (cap +0.5) |
| Frass enrichment | Insect / animal droppings | animal-slot tile present | slow buildup of `nutrient_per_tick` (cap +0.3) |
| Apex predator cascade | Wolf reintroduction trophic cascade | predator-tagged species in run AND herbivore pressure > 50% | plantae yields × 1.10 (predator suppresses overgrazing) |
| Pollination | Bee / butterfly + flowering plant | insect-tagged tile adjacent to plantae | +15% biomass on the plantae tile (requires Phase 14 insect agents) |
| Mycoheterotrophy | Ghost plants stealing from mycorrhizae | plantae tagged `mycoheterotroph` adjacent to mycorrhizal_bond tile | drains 0.1 biomass/tick from the bonded plantae, gains it |

Migration-phase deliverable: tag schema only. Concrete predicate handlers land with the species that need them.

## Goals, events, interventions

### Goals (re-keyed)

`PerRunGoalData.tracker` taxonomy stays: `tiles_colonized`, `biomass_earned`, `events_survived`, `herbivores_defeated`, `node_purchased`. Plus new keys for the species-first model:

- `species_introduced` — number of distinct species placed this run (drives diversity goals).
- `biome_tiles_colonized` — tiles colonized on a specific biome type.
- `cross_kingdom_interactions` — count of symbiosis bonuses + mycorrhizal bonds + etc. fired this run.

Goal filter conditions become biome/interaction-scoped instead of niche-scoped:
- Old: "if niche == parasitic_plantae, goal: steal 200 biomass."
- New: "if any cultivated species has `placement_rule == parasitic_plantae`, goal: steal 200 biomass via parasite_steal interactions."

### Events (axis-scoped)

Phase 13 brief 04's design **survives intact**. `EventData.scope` + `scope_target` filter events to the right context. Add `&"species"` as a recognized scope (for events that fire only when a specific species is present), already wired in the brief 04 schema.

Backfill table from brief 05 also survives, with one adjustment: `herbivore_wave` scope changes from `&"kingdom":&"plantae"` to `&"species_tag":&"plantae"` — i.e., the event fires when the player has any plantae-tagged species cultivated, not when their (gone) `current_kingdom_id` matches.

### Active interventions (ecosystem-scoped)

Phase 11's `Irrigate`, `Bundle`, `Cull` abilities re-anchor to ecosystem state, not niche:
- Irrigate: usable during Drought (event-tied).
- Bundle: usable during Cool Spell / Cold Snap (event-tied).
- Cull: usable during Spore Infection (event-tied).

These were already event-scoped, so the migration is mostly cleaning up niche-keyed unlock paths in `AbilitySystem`. Future interventions can be unlocked per-ecosystem (e.g., "Vent Drain" only usable on `cryo_volcanic_vent`).

## Rendering

### Multi-species tile visualization

Per Locked Decision 18: plantae/fungi use the **base tile color** (or a blended third color when both occupy); animals render as a **border** around the tile, not as a fill.

Rendering rules:

- **Empty tile** → biome color only (no overlay).
- **Plantae only** → base tile painted with the plantae species' `tile_marker_color` (green family by convention; per-species variation allowed).
- **Fungi only** → base tile painted with the fungi species' `tile_marker_color` (purple family by convention).
- **Plantae + fungi** → base tile painted with a **blended third color** (warm yellow-green by default — the symbiosis cue at a glance). The exact blend formula is a single helper in `tile_grid.gd`; per-species tints modulate the blend.
- **Animal present** → a 2px **border** drawn around the tile in the animal species' `tile_marker_color`. Border draws regardless of what's underneath; an animal can stand on plantae, fungi, plantae+fungi, or bare biome.

Three layers are still used in the TileMap: layer 0 = biome ground, layer 1 = surface fill (plantae/fungi blended), layer 2 = animal border. The TileMap API supports the border as a separate atlas tile with transparent interior.

This treatment keeps the playfield readable on portrait 360×640: kingdom occupation is one glance away (fill = plants and/or fungi; border = animal).

### Recipe placement UX

For recipe species (Lichen, Coral): tapping "Place Lichen" places both components in one input, paying the combined cost. The UI shows a single icon ("Lichen") with a small badge indicating the kingdoms involved.

If only one component slot is valid (e.g., the fungi slot is already occupied), the recipe fails — atomic placement, no partial. 

## What this replaces / deletes

### Deletes outright

- `scripts/data/niche_data.gd` and `data/niches/_index.tres` (NicheIndex too).
- `data/niches/*.tres` files (content migrated to species).
- `scripts/autoloads/multi_layer_placement.gd` — replaced by recipe placement in `ColonizationRulesRegistry`.
- `scripts/systems/parasite_steal_system.gd` and `parasite_decay_system.gd` — generalized into per-species tick effects.
- `GameState.current_kingdom_id` and `GameState.current_niche_id` fields.
- `SpeciesData.layer_count` and `SpeciesData.layer_species` fields — replaced by recipe components on a new species.
- `EventBus.niche_changed` signal.

### Migrates in place

- `NicheData` → fields fold into the corresponding species (`placement_rule`, `parasitic_targets`/`placement_targets`, `cost_override` discarded — costs live on species only, `conditional_start_bonus_requires` discarded — handled per-species or per-ecosystem).
- `SpeciesData.layer_count > 1` species → become recipe species with `recipe_components` set.
- `EvolutionNodeData.grants_kingdoms` → reinterpreted as "unlock the default starter species of these kingdoms"; backward-compatible.
- `EvolutionNodeData` gains `grants_species: Array[StringName]`.
- Discovery entries with `category: &"niche"` → re-categorized as `&"species"` or `&"interaction"` depending on what they describe.
- `EcosystemData.completion_required_niche` / `completion_required_kingdom` → `completion_required_species` / `completion_required_biome`.
- `EcosystemData.biome_preference` → `biome_recipe` dictionary.
- `TerritorySystem` per-tile state: `surface_owner`/`subsurface_owner` → `occupants: Dictionary[StringName, StringName]`.
- `GrowthSystem._tick_kingdom` → `_tick_run` that iterates all introduced species (no more "the kingdom" — there's no kingdom).
- `ColonizationRulesRegistry` — accepts species directly, not niche.

### Survives untouched

- SaveSystem migration chain (just adds v11 → v12).
- EventBus (minus `niche_changed`).
- ResourceLedger, TickClock, AmbientModifierSystem, AbilitySystem.
- CorpseSystem, SporeInfectionHandler, HerbivoreManager.
- AudioManager, theme/HUD scaffolding, save backup rotation, offline progress.
- All BiomeData files.
- All EventData files (re-scoped via brief 04 design, content unchanged).
- All DiscoveryEntry bodies (re-tagged where category changes).
- EraData + era files (`available_kingdoms` semantics unchanged).
- Phase 12 world map UI bones (ecosystem cards, era tabs).
- Most evolution tree nodes (trait grants, ability unlocks, ambient modifiers).

## Save shape (v11 → v12)

```
{
  "version": 12,
  "meta": {
    // RENAMED
    "kingdoms_played": [...] → unchanged (still tracks which kingdoms a starter species was first played from)
    "niches_played": [...] → DELETED
    "species_unlocked": Array[String]  // NEW: replaces kingdom-based unlocks
    "species_played": Array[String]    // NEW: starter species of each completed run

    // PRESERVED from v11
    "discovery_log": {...}
    "current_era_id": String
    "current_ecosystem_id": String
    "ecosystem_completions": {...}
    "eras_unlocked": [...]
    "statistics": {...}
  },
  "run": {
    // RENAMED / RESHAPED
    "kingdom_id": String → starting_species_kingdom_id (denormalized for fast lookup)
    "niche_id": String → DELETED
    "starting_species_id": String   // NEW
    "unlocked_species_in_run": Array[String]   // NEW: species the player has paid the introduce_cost for

    // RESHAPED
    "tiles": Array[{coord, occupants: {kingdom_id: species_id}, data}]
    // (was: tiles: Array[{coord, surface_owner, subsurface_owner, data}])

    // PRESERVED
    "biome_map": {...}
    "active_events": [...]
    "event_first_fires_seen": [...]
    "statistics": {...}
  }
}
```

Migration `_migrate_v11_to_v12(save)`:
1. **Meta**: copy `kingdoms_played` content into `species_unlocked` (mapping kingdom → default starter species id); init `species_played` from past prestige history if possible, else empty.
2. **Run state**: if `kingdom_id` set, set `starting_species_id` to that kingdom's default starter; populate `unlocked_species_in_run` with `[starting_species_id]`. Drop `niche_id`.
3. **Tiles**: transform each tile's `{surface_owner, subsurface_owner}` into `{occupants: {plantae: <surface_owner>'s starter, fungi: <subsurface_owner>'s starter}}` using the run's starter species for the kingdom.
   - Edge case: a v11 lichen run has surface=plantae + subsurface=fungi; v12 maps to `{plantae: pioneer_grass, fungi: mycelium_thread}` (the recipe components).
4. Bump version.

The migration is one-shot, lossless for normal runs, lossy only for legacy niche-specific variant data (e.g., a parasite plantae tile becomes a generic plantae tile with bramble as the starter species — close enough; player's existing tiles are preserved visually but lose the niche flavor).

## Migration phase exit criterion (Phase 13-revised)

**Behavior parity.** Every gameplay path that worked in Phase 12 still works in the new model:

- [ ] Plantae photosynthesizer run plays as before (now: starting species = pioneer_grass, no niche selector).
- [ ] Plantae parasite run plays as before (now: introduce bramble during the run for parasite gameplay).
- [ ] Fungi decomposer run plays as before.
- [ ] Fungi mycorrhizal run plays as before (via mycorrhizal mycelium species).
- [ ] Lichen run plays as before (recipe places pioneer_grass + mycelium_thread atomically).
- [ ] Animal herbivore + predator runs play as before.
- [ ] All 6 Phase 12 ecosystems still complete with their (re-keyed) criteria.
- [ ] Mass extinction era transition still fires narrative + (Phase 13's now-deferred) gameplay teeth.
- [ ] Save migration v11 → v12 is lossless for the common cases.
- [ ] No new visible content; the model rework is invisible to the player except for: the niche selector being replaced by a starting-species picker, and the "Introduce species" UI panel during a run.

**Out of scope for the migration phase** (defer to Phase 14-revised):
- New biomes (tundra, mineral_vent, swamp) — Phase 14.
- Per-era visual tinting — Phase 14.
- Mass extinction gameplay teeth — Phase 14 (architecture from brief 06 translates).
- Era-gated evolution nodes — Phase 14.
- Cross-species emergent interactions beyond what's currently authored — Phase 15+.

## Resolved decisions (Q1-Q7, answered 2026-05-18)

1. **Q1 — Coinhabitation default for same-kingdom species.** Locked as proposed: one species per kingdom per tile. Confirm? (If yes, two plantae species can never share a tile.)
yes for now, but i want to allow exceptions or add more complex rules possibly

2. **Q2 — Lichen as recipe vs as a species.** Recipe is the proposed approach (composable, generalizes to Coral/Termite Mound). Confirm? (Alternative: keep a `recipe_species` shadow class that's almost a species but renders as a single entity. More code, less data.)
recipe

3. **Q3 — Introduce-cost defaults.** Are the cost ranges in §Per-run species introduction (≈3-5× per-tile cost) the right ballpark, or do you want introduction to feel heavier (10× tile cost) — more decisive, fewer species per run? Or lighter (1-2× tile cost) — more species per run, more cluttered worlds?
more decisive

4. **Q4 — Diversity multiplier on prestige.** The `× 1.1 / 1.2` for cultivating multiple species is a soft incentive to introduce more species. Keep this? Or leave prestige flat and let in-run resource gain be the only reason to diversify?
keep

5. **Q5 — Existing niche file deletion vs preservation.** The migration phase deletes `data/niches/`. We could instead leave them as inert metadata until Phase 14 and delete then. Cleaner code now vs. easier rollback later. Recommendation: delete cleanly during migration, no half-state.
delete

6. **Q6 — Recipe placement granularity.** A recipe species places both components in one tap. If a component slot is already occupied, the recipe **fails atomically** (proposed). Alternative: place only the available components. Strict atomic is simpler; partial placement enables interesting "lichen tile next to a tile that already had grass — only the fungus part of the lichen lands" emergent moments. Lean atomic for v1? atomic for v1

7. **Q7 — `species.tags: Array[StringName]` field.** Proposed for herbivore/predator/parasite classification. Alternative: derive from `placement_rule` + `kingdom_id`. Tags are clearer for authoring; derivation has less duplication. Lean tags?  add tags

All answered. See Locked Decisions 11-20 above for the consolidated outcome.

---

**Next step**: Phase 13 brief set rewritten as the migration phase (`docs/briefs/phase_13/` — pre-rewrite briefs archived to `docs/briefs/phase_13_paused/`). Original Phase 13 content (biomes, mass extinction teeth, era nodes, per-era visuals) moves to Phase 14 with light re-expression in species-first language.
