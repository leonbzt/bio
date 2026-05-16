extends Node
##
## EventBus — singleton signal hub.
## Systems do not import each other; they emit and listen here.
## Signals listed in docs/ARCHITECTURE.md section 3. Do not add new ones without
## updating that document first.
##

# Tick / time
signal tick(delta_seconds: float)
signal paused_changed(is_paused: bool)

# Resources
signal resource_changed(resource_id: StringName, new_amount: float)

# Territory
signal tile_tapped(coord: Vector2i)
signal tile_colonized(coord: Vector2i, owner_id: StringName)
signal tile_lost(coord: Vector2i, prev_owner_id: StringName)

# Organisms
signal organism_spawned(organism_id: int, species_id: StringName, coord: Vector2i)
signal organism_died(organism_id: int, cause: StringName)

# Evolution
signal trait_unlocked(trait_id: StringName)
signal evolution_node_unlocked(node_id: StringName)
signal discovery_unlocked(entry_id: StringName)

# Ecological pressure
signal event_started(event_id: StringName, payload: Dictionary)
signal event_resolved(event_id: StringName, outcome: StringName)

# Input mode and abilities
signal input_mode_changed(mode: StringName)
signal ability_used(ability_id: StringName, payload: Dictionary)
signal placement_target_changed(target: StringName)

# Run lifecycle
signal run_started(kingdom_id: StringName)
signal niche_changed(niche_id: StringName)
signal prestige_triggered(summary: Dictionary)
signal run_loaded(save_version: int)

# Offline progress
signal replay_started(total_ticks: int)
signal replay_finished()
