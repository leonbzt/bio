class_name EcosystemData
extends Resource
##
## A biome region within an era. Has its own completion criterion.
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

# Optional niche gate. Empty = any niche.
@export var completion_required_niche: StringName = &""

# Optional kingdom gate. Empty = any kingdom in the era's available_kingdoms.
@export var completion_required_kingdom: StringName = &""

# 1-3 sentence flavor for world-map card + completion fanfare.
@export var unlock_text: String = ""
@export var complete_text: String = ""

# Biome preference (Phase 13 wires; Phase 12 stores).
@export var biome_preference: StringName = &""
