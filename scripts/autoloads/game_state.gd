extends Node
##
## GameState — top-level snapshot of the live game.
## Two save layers: run_save (resets on prestige) and meta_save (persistent).
## Populated by SaveSystem on boot.
##

var current_kingdom_id: StringName = &""
var run_seed: int = 0
var is_run_active: bool = false
var last_save_unix: int = 0

const INPUT_MODE_COLONIZE: StringName = &"colonize"
const INPUT_MODE_TARGET: StringName = &"target_ability"
var input_mode: StringName = INPUT_MODE_COLONIZE

# Active species to place on tile taps during a run.
var placement_target_species_id: StringName = &""

var run_save: Dictionary = {}
var meta_save: Dictionary = {}
