class_name SpeciesData
extends Resource
##
## A species an organism can belong to.
## Instances live in data/species/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Kingdom tag. Drives interaction predicates (herbivore eats plantae-tagged
# tiles), per-tile slot assignment (one species per kingdom per tile), and
# era filtering. NOT a run-state field — runs reference species directly.
@export var kingdom_id: StringName = &""

# Traits + numbers.
@export var sprite: Texture2D
@export var base_traits: Array[TraitData] = []
@export var tick_yield: Dictionary = {}   # {resource_id: float}

# Costs.
@export var introduce_cost: Dictionary = {}   # one-shot per-run cost (Locked Decision 13)
@export var colonize_cost: Dictionary = {}    # per-tile placement cost

# Placement rule — dispatch key for ColonizationRulesRegistry.
# Values: &"adjacent_empty", &"fungi_substrate", &"parasitic_plantae",
#         &"mycorrhizal_fungi", &"animal_anchor", &"recipe".
@export var placement_rule: StringName = &"adjacent_empty"

# Optional placement-rule parameters (parasite target kingdoms, etc.).
@export var placement_targets: Array[StringName] = []

# Authored tags for interaction predicates (Locked Decision 17).
# Recognized: &"herbivore", &"predator", &"parasite", &"pioneer",
#             &"successor", &"nitrogen_fixer", &"allelopath",
#             &"mycoheterotroph", &"pollinator", &"scavenger".
@export var tags: Array[StringName] = []

# Per-species tick effects (Phase 13 brief 05 dispatcher).
# Recognized: &"parasite_steal", &"corpse_decay",
#             &"mycorrhizal_bond_apply", &"frass_enrichment", &"nitrogen_fix".
@export var tick_effects: Array[StringName] = []

# Meta unlock.
@export var unlock_ep_cost: int = 0
@export var unlock_prerequisites: Array[StringName] = []

# Era gate. Empty = always available (subject to era's available_kingdoms).
@export var era_requires: StringName = &""

# Recipe species (Locked Decision 12). Non-empty + placement_rule == &"recipe"
# means tapping this species atomically places each listed species into its
# respective kingdom slot.
@export var recipe_components: Array[StringName] = []

# Rendering hints (Locked Decision 18).
@export var tile_marker_color: Color = Color(1, 1, 1, 1)
@export var tile_marker_shape: StringName = &"square"  # square|circle|cross|leaf|spore|root|border
