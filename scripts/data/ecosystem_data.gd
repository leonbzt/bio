class_name EcosystemData
extends Resource
##
## A biome region within an era. Has its own completion criterion and
## constrains the starting-species picker.
## Instances live in data/ecosystems/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Back-reference. Could derive from EraData.ecosystems but explicit is cleaner.
@export var era_id: StringName = &""

# Completion criterion uses the same taxonomy as PerRunGoalData.tracker.
# Recognized: &"tiles_colonized", &"biomass_earned", &"events_survived",
# &"herbivores_defeated", &"node_purchased".
@export var completion_criterion: StringName = &""
@export var completion_target: float = 0.0

# Biome recipe — weighted mix the procedural map generator samples.
# Format: {biome_id: weight_float}. Empty = legacy uniform random.
@export var biome_recipe: Dictionary = {}

# Cluster size for biome generation. 1.0 = scattered, larger = patchier.
@export var biome_cluster_size: float = 1.0

# Optional species gate. Empty = any species.
@export var completion_required_species: StringName = &""

# Optional biome gate. Empty = any biome.
@export var completion_required_biome: StringName = &""

# Starting-species picker constraint.
@export var starting_species_filter: Array[StringName] = []

# 1-3 sentence flavor for world-map card + completion fanfare.
@export var unlock_text: String = ""
@export var complete_text: String = ""

# Optional override for the per-run goal banner. When set, RunGoalSystem
# forces this goal id at run start instead of rolling from the random pool.
# Lets each ecosystem align its banner with its completion criterion
# (Coal Swamp wants "Fill the Coal Gauge", not "Earn 500 biomass").
@export var goal_id: StringName = &""

# Alpha gate. When false, the world map shows the ecosystem as a "Coming soon"
# card regardless of unlock-chain state. Lets us keep future ecosystems visible
# (so the player sees the roadmap) without making them playable before they're
# actually finished.
@export var playable: bool = true
