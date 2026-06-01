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

# Active species to place on tile taps during a run.
var placement_target_species_id: StringName = &""

var run_save: Dictionary = {}
var meta_save: Dictionary = {}

# Transient flag: when an in-game prestige routes back through the main menu,
# this asks the menu to skip straight to the ecosystem picker (world_map).
# Set by prestige_screen._close() after a confirmed prestige; consumed and
# cleared by main_menu._ready().
var auto_open_world_map: bool = false
var auto_start_run: bool = false


func get_hero_biomass() -> float:
	return float(run_save.get("hero_biomass_lifetime_produced", 0.0))


func can_afford_hero_biomass(amount: float) -> bool:
	if amount <= 0.0:
		return true
	return get_hero_biomass() >= amount


func spend_hero_biomass(amount: float) -> bool:
	if amount <= 0.0:
		return true
	var current: float = get_hero_biomass()
	if current < amount:
		return false
	run_save["hero_biomass_lifetime_produced"] = current - amount
	return true
