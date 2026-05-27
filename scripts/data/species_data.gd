class_name SpeciesData
extends Resource
##
## A species an organism can belong to.
## Instances live in data/species/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Latin binomial + era hint surfaced in tooltips.
@export var latin_name: String = ""

# Groups era-variants of the same biological lineage.
@export var lineage_id: StringName = &""

# Kingdom tag. Drives interaction predicates (herbivore eats plantae-tagged
# tiles), per-tile slot assignment (one species per kingdom per tile), and
# era filtering. NOT a run-state field — runs reference species directly.
@export var kingdom_id: StringName = &""

# Traits + numbers.
@export var sprite: Texture2D
@export var base_traits: Array[TraitData] = []
@export var tick_yield: Dictionary = {}   # {resource_id: float}

# Per-tile-per-tick input rates. Output throttles proportionally when the global pool
# can't satisfy total consumption (bottleneck mechanic).
@export var consume_input: Dictionary = {}

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

# Per-biome biomass yield multiplier; missing key defaults to 1.0 at use site.
@export var biome_affinity: Dictionary = {}

# Per-species tile sprite set. Four paths for the four maturity/density stages
# used by the scatter overlay (sprout / small cluster / dense cluster / mature).
# Empty = fall back to the kingdom-level default sprites.
@export var tile_sprite_paths: Array[String] = []
