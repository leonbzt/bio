class_name TraitData
extends Resource
##
## A reusable trait applied via composition.
## Instances live in data/traits/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var modifiers: Dictionary = {}        # e.g. {"defense": 5, "growth_speed": -0.1}
@export var tradeoff_summary: String = ""     # one-line "+X / -Y"
