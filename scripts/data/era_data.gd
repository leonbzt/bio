class_name EraData
extends Resource
##
## A geological era. Defines which kingdoms are playable and contains
## the ecosystems the player completes to advance to the next era.
## Instances live in data/eras/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# Which kingdoms can be played in this era. Players who unlocked a kingdom
# via the evolution tree still can't play it if the era forbids it.
# Empty = all unlocked kingdoms allowed.
@export var available_kingdoms: Array[StringName] = []

# The ecosystems contained in this era. Player must complete all to advance.
@export var ecosystems: Array[EcosystemData] = []

# UI tint for the world-map background.
@export var tint_color: Color = Color(1.0, 1.0, 1.0, 0.1)

# 4-8 sentence mythic-scientific passage shown during transition INTO this era.
# Empty for the first era (Cryogenian).
@export var transition_narrative: String = ""

# id of the era that must be fully complete for this era to unlock.
# Empty = always unlocked.
@export var unlock_requires_prev_era: StringName = &""
