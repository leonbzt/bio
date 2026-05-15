class_name KingdomData
extends Resource
##
## A playable kingdom (Plantae, Fungi, Symbiosis hybrid, ...).
## Instances live in data/kingdoms/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var starting_species: Array[SpeciesData] = []
@export var starting_resources: Dictionary = {}   # {resource_id: float}
@export var unlock_cost: Dictionary = {}           # paid in MetaSave currency
