class_name BiomeData
extends Resource
##
## A tile biome (grassland, decay-rich soil, ...) with per-tick yields.
## Instances live in data/biomes/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var tile_texture: Texture2D
@export var sunlight_per_tick: float = 0.0
@export var nutrient_per_tick: float = 0.0
@export var decay_per_tick: float = 0.0
# Phase 14b: biomes can supply biomass via chemosynthesis.
@export var chemosynthesis_per_tick: float = 0.0
