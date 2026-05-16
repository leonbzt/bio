class_name EvolutionNodeData
extends Resource
##
## A node in the meta-progression evolution tree.
## Instances live in data/evolution_tree/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var prerequisites: Array[StringName] = []   # other node ids
@export var meta_cost: Dictionary = {}              # meta-currency cost
@export var grants_traits: Array[TraitData] = []
@export var grants_kingdoms: Array[StringName] = []

# Phase 9 additions — see docs/PROGRESSION_WEB.md.
@export var wing: StringName = &""
@export var tier: int = 1
@export var requires_kingdom_played: Array[StringName] = []
