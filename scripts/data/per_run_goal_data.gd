class_name PerRunGoalData
extends Resource
##
## A soft prestige goal. Instances live in data/goals/<id>.tres.
##

@export var id: StringName = &""
@export var display_text: String = ""

# Determines which event(s) the system listens to for progress.
@export var tracker: StringName = &""

# Target value to reach.
@export var target: float = 0.0

# Niche scope. Empty list = available to any niche.
@export var niches: Array[StringName] = []

# Kingdom scope. Empty list = available to any kingdom.
@export var kingdoms: Array[StringName] = []
