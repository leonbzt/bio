class_name SpeciesData
extends Resource
##
## A species an organism can belong to.
## Instances live in data/species/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var kingdom_id: StringName = &""
@export var sprite: Texture2D
@export var base_traits: Array[TraitData] = []
@export var colonize_cost: Dictionary = {}   # {resource_id: float}
@export var tick_yield: Dictionary = {}      # resources generated per tick per tile

# Layered species can yield from multiple species entries (e.g. lichen).
@export var layer_count: int = 1
@export var layer_species: Array[StringName] = []
