extends Node
##
## GameState — top-level snapshot of the live game.
## Two save layers: run_save (resets on prestige) and meta_save (persistent).
## Populated by SaveSystem on boot.
##

var current_kingdom_id: StringName = &""
var current_niche_id: StringName = &""
var run_seed: int = 0
var is_run_active: bool = false
var last_save_unix: int = 0

const INPUT_MODE_COLONIZE: StringName = &"colonize"
var input_mode: StringName = INPUT_MODE_COLONIZE

# Symbiosis runs let the player toggle which layer the next tap targets.
# In single-kingdom runs this is locked to current_kingdom_id by PrestigeSystem.start_run().
var placement_target: StringName = &""

var run_save: Dictionary = {}
var meta_save: Dictionary = {}
