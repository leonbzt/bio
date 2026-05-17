class_name NicheData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var kingdom_id: StringName = &""
@export var species_options: Array[SpeciesData] = []

# Identifies the colonization rule this niche uses.
@export var colonization_rule: StringName = &""

# Cost override. If empty, falls back to species.colonize_cost.
@export var cost_override: Dictionary = {}

# Which evolution-tree node grants this niche. Empty = default niche.
@export var unlock_node_id: StringName = &""

# Optional visual variant key used by tile rendering.
@export var tile_variant: StringName = &""

# Layered niches allow multi-layer placement (surface + subsurface).
@export var expects_layered: bool = false

# Optional parasitic targeting list (for parasitic_plantae niche).
@export var parasitic_targets: Array[StringName] = []

# Optional conditional start bonus applied by PrestigeSystem.
@export var conditional_start_bonus: Dictionary = {}
@export var conditional_start_bonus_requires: StringName = &""
