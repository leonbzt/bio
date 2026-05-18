# Brief 02 — SpeciesData schema extension

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — contracts.

Read first:
1. `scripts/data/species_data.gd` — current schema (post-Phase-10 layered fields).
2. `docs/SPECIES_MODEL.md` §Species — target schema.
3. `data/species/lichen_common.tres`, `data/species/mycelium_thread.tres` — examples.

## Goal

Extend `SpeciesData` to be the first-class entity that absorbs niche + layer-species responsibility. Schema only — content folding lives in brief 08.

## Output

### `scripts/data/species_data.gd`

```gdscript
class_name SpeciesData
extends Resource
##
## A species an organism can belong to.
## Instances live in data/species/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# The kingdom tag. Drives interaction predicates (herbivore eats plantae-tagged
# tiles), per-tile slot assignment (one species per kingdom per tile), and
# era filtering. NOT a run-state field — runs reference species directly.
@export var kingdom_id: StringName = &""

# Traits + numbers.
@export var sprite: Texture2D
@export var base_traits: Array[TraitData] = []
@export var tick_yield: Dictionary = {}   # {resource_id: float}

# Costs.
@export var introduce_cost: Dictionary = {}   # one-shot per-run cost (Locked Decision 13).
@export var colonize_cost: Dictionary = {}    # per-tile placement cost.

# Placement rule — dispatch key for ColonizationRulesRegistry.
# Values: &"adjacent_empty", &"fungi_substrate", &"parasitic_plantae",
#         &"mycorrhizal_fungi", &"animal_anchor", &"recipe".
@export var placement_rule: StringName = &"adjacent_empty"

# Optional rule parameters — used by parasitic_plantae (target kingdom ids),
# successor (required prior-occupation tag), etc.
@export var placement_targets: Array[StringName] = []

# Tags for interaction predicates (Locked Decision 17).
# Recognized values: &"herbivore", &"predator", &"parasite", &"pioneer",
#                    &"successor", &"nitrogen_fixer", &"allelopath",
#                    &"mycoheterotroph", &"pollinator", &"scavenger".
# Extensible — add new tags as new predicates ship.
@export var tags: Array[StringName] = []

# Per-species tick effects — runs alongside tick_yield on every tile this
# species owns. Recognized: &"parasite_steal", &"corpse_decay",
# &"mycorrhizal_bond_apply", &"frass_enrichment", &"nitrogen_fix".
# Decouples generic-system code (parasite_steal_system, etc.) into per-species
# opt-in handlers. Brief 05 wires the dispatcher.
@export var tick_effects: Array[StringName] = []

# Meta unlock.
@export var unlock_ep_cost: int = 0
@export var unlock_prerequisites: Array[StringName] = []   # other species ids

# Era gate. Empty = always available (subject to kingdom availability via
# EraData.available_kingdoms).
@export var era_requires: StringName = &""

# Recipe species (Locked Decision 12). Non-empty = this species's placement
# atomically places each listed species into its respective kingdom slot.
# placement_rule must equal &"recipe" if this is non-empty.
@export var recipe_components: Array[StringName] = []

# Rendering hints (Locked Decision 18).
@export var tile_marker_color: Color = Color(1, 1, 1, 1)
@export var tile_marker_shape: StringName = &"square"  # square|circle|cross|leaf|spore|root|border
```

### Removed fields

- `layer_count` — deleted. Layered species become recipes.
- `layer_species` — deleted. Replaced by `recipe_components`.

### Backward compatibility

The schema additions are all default-valued, so existing `data/species/*.tres` files load without error. Brief 08 edits each species file to add the new fields explicitly. Until then:

- `placement_rule` defaults to `&"adjacent_empty"` — wrong for fungi/lichen but harmless until brief 06 actually uses it.
- `tags` defaults to `[]` — predicates that need tags (e.g., herbivore eat) won't fire until tags are filled in. Acceptable during the migration window.
- `tile_marker_color` defaults to white — rendering until brief 09 lands keeps the existing atlas-tile lookup.

The two deleted fields (`layer_count`, `layer_species`) cause loader warnings on existing lichen .tres files. Brief 08 rewrites lichen_common.tres with the new fields; until then the warning is informational only.

## Inspector + serialization sanity

After changing the script, open `data/species/pioneer_grass.tres` in the inspector. Confirm all new fields visible with defaults; confirm existing field values (kingdom_id, tick_yield, base_traits) intact. Repeat for `mycelium_thread.tres` and `lichen_common.tres`.

## ARCHITECTURE.md updates

- §4 schema — replace `SpeciesData` entry with the new shape (delete `layer_count` / `layer_species` rows; add new fields).
- §6 systems — note the planned migration of `parasite_steal_system` / `parasite_decay_system` into per-species `tick_effects` (full implementation in brief 05).

## Acceptance criteria

- [ ] `SpeciesData` schema matches the target above.
- [ ] All existing `data/species/*.tres` load in inspector without error (layer-field warnings OK).
- [ ] No runtime behavior change yet (consumers don't read the new fields until later briefs).
- [ ] `layer_count` and `layer_species` are not present in the script.

## Out of scope

- Filling in new fields on existing species files (brief 08).
- Reading the new fields from systems (briefs 05, 06, 07).
- Rendering with tile_marker_color (brief 09).
- Recipe placement logic (brief 06).
- Tick-effects dispatcher (brief 05).
