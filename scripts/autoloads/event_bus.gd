extends Node
##
## EventBus — singleton signal hub.
## Systems do not import each other; they emit and listen here.
##

# Tick / time
signal tick(delta_seconds: float)
signal paused_changed(is_paused: bool)

# Territory
signal tile_tapped(coord: Vector2i)
signal tile_colonized(coord: Vector2i, owner_id: StringName)
signal tile_lost(coord: Vector2i, prev_owner_id: StringName)
signal tile_harvested(coord: Vector2i, amounts: Dictionary)
signal animal_harvested(coord: Vector2i, amount: float)
signal soil_replenished(coord: Vector2i, amount: float)
signal harvest_combo(level: int)

# Structures
signal structure_promoted(structure_id: StringName, anchor: Vector2i)

# Evolution
signal evolution_node_unlocked(node_id: StringName)
signal discovery_unlocked(entry_id: StringName)
signal species_leveled(species_id: StringName, new_level: int)

# Ambient events (era transitions, cold snaps)
signal event_started(event_id: StringName, payload: Dictionary)
signal event_resolved(event_id: StringName, outcome: StringName)

# Placement
signal placement_target_changed(target_species_id: StringName)

# Run lifecycle
signal run_started(kingdom_id: StringName)
signal species_introduced(species_id: StringName)
signal prestige_triggered(summary: Dictionary)
signal run_loaded(save_version: int)
signal goal_progress_changed(progress: Dictionary)
signal goal_met()
signal checkpoint_triggered(id: StringName, payload: Dictionary)
signal cycle_closed()

# Era + ecosystem
signal era_transition_started(from_era: StringName, to_era: StringName)
signal ecosystem_completed(ecosystem_id: StringName)
signal era_changed(era_id: StringName)

# Offline progress
signal replay_started(total_ticks: int)
signal replay_finished()
signal offline_summary(biomass_gained: float)
