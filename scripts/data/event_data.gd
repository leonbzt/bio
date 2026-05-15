class_name EventData
extends Resource
##
## An ecological pressure event (drought, herbivore wave, wildfire, ...).
## Instances live in data/events/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var trigger_weight: float = 1.0
@export var duration_ticks: int = 60
@export var payload: Dictionary = {}          # event-specific parameters
