extends Node
##
## SaveSystem — JSON save/load with versioned migrations.
## Schema and migration convention in docs/ARCHITECTURE.md sections 3 and 9.
## Implementation in brief 03. Changes here MUST be reviewed by Claude.
##

const SAVE_VERSION: int = 20

# Kingdom precedence for the v17 → v18 multi → single occupant flatten.
# When a v17 tile had >1 kingdom slot, the migration keeps the species whose
# kingdom appears earliest in this list and discards the rest.
const _SINGLE_OCCUPANT_KINGDOM_PRECEDENCE: Array[StringName] = [
	&"plantae",
	&"fungi",
	&"animals"
]
const SAVE_PATH: String = "user://save.json"
const TEMP_PATH: String = "user://save.json.tmp"
const BACKUP_PATH: String = "user://save.json.bak"

const _KINGDOM_DEFAULT_STARTERS: Dictionary[StringName, StringName] = {
	&"plantae": &"pioneer_grass",
	&"fungi": &"mycelium_thread",
	&"animals": &"common_grazer"
}

# Phase 14a stopgap — auto-unlocked species (no proper unlock-tree UI yet).
const _PHASE_14A_AUTO_UNLOCK: Array[String] = [
	"cyanobacterial_mat",
	"vent_archaeon",
	"cryo_lichen",
	"tree_fern_stem",
	"wood_rot_bracket",
	"creeping_vine",
	"spore_drift",
	"scavenger_swarm"
]

const _NICHE_TO_STARTER_SPECIES: Dictionary[StringName, StringName] = {
	&"photosynthesizer": &"pioneer_grass",
	&"parasitic_plantae": &"bramble",
	&"decomposer": &"mycelium_thread",
	&"mycorrhizal_fungi": &"mycelium_thread_mycorrhizal",
	&"lichen": &"lichen_common",
	&"herbivore": &"common_grazer",
	&"predator": &"common_predator"
}

# Species id -> lineage id; hardcoded so migration can run before content loads.
const _SPECIES_TO_LINEAGE: Dictionary[StringName, StringName] = {
	&"pioneer_grass": &"pioneer_stem",
	&"cyanobacterial_mat": &"pioneer_stem",
	&"mycelium_thread": &"mycorrhizal",
	&"mycelium_thread_mycorrhizal": &"mycorrhizal",
	&"bramble": &"parasitic_climber",
	&"lichen_common": &"lichen",
	&"cryo_lichen": &"lichen",
	&"vent_archaeon": &"extremophile",
	&"tree_fern_stem": &"arborescent",
	&"wood_rot_bracket": &"saprotroph",
	&"common_grazer": &"tetrapod_browser",
	&"common_predator": &"tetrapod_predator"
}


func _ready() -> void:
	# Autosave is driven by _notification for cross-platform pause/quit.
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		save_now()


func save_now() -> void:
	# Perf (Tier 2): TerritorySystem batches its run_save sync; flush
	# any pending tile mutations into run_save before we serialize.
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var territory := tree.root.get_node_or_null("World/Systems/TerritorySystem")
		if territory != null and territory.has_method("flush_to_save_immediate"):
			territory.flush_to_save_immediate()
	var save_dict := _build_save_dict()
	var json: String = JSON.stringify(save_dict, "\t")

	var tmp := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_error("SaveSystem: failed to open temp file %s" % TEMP_PATH)
		return
	tmp.store_string(json)
	tmp.close()

	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			DirAccess.remove_absolute(BACKUP_PATH)
		DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
	DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)


func load_or_create() -> void:
	var data: Dictionary = _try_load(SAVE_PATH)
	if data.is_empty():
		data = _try_load(BACKUP_PATH)
		if not data.is_empty():
			push_warning("SaveSystem: primary save corrupted, restored from backup")
	if data.is_empty():
		var fresh := _build_default_save()
		_write_save(fresh)
		GameState.meta_save = fresh["meta"]
		GameState.run_save = fresh["run"]
		GameState.last_save_unix = int(Time.get_unix_time_from_system())
		EventBus.run_loaded.emit(fresh["save_version"])
		return

	_apply_loaded(data)


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var err := DirAccess.remove_absolute(SAVE_PATH)
		if err != OK:
			push_error("SaveSystem: failed to delete save file: %s" % SAVE_PATH)
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(BACKUP_PATH)
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)
	var fresh := _build_default_save()
	_write_save(fresh)
	GameState.meta_save = fresh["meta"]
	GameState.run_save = fresh["run"]
	GameState.last_save_unix = int(Time.get_unix_time_from_system())
	EventBus.run_loaded.emit(fresh["save_version"])


func migrate(old: Dictionary, from_version: int) -> Dictionary:
	# Cascading: each block migrates one version forward.
	if from_version < 1:
		# v0 -> v1: rename run.kingdom -> run.kingdom_id
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if run.has("kingdom") and not run.has("kingdom_id"):
				run["kingdom_id"] = run["kingdom"]
				run.erase("kingdom")
	if from_version < 2:
		# v1 -> v2: add biome_map (generated on first run_loaded).
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if not run.has("biome_map"):
				run["biome_map"] = {}
	if from_version < 3:
		# v2 -> v3: add meta and run statistics scaffolding.
		if old.has("meta") and old["meta"] is Dictionary:
			var meta: Dictionary = old["meta"]
			if not (meta.get("unlocked_kingdoms") is Array):
				meta["unlocked_kingdoms"] = []
			var kingdoms: Array = meta["unlocked_kingdoms"]
			if not kingdoms.has("plantae"):
				kingdoms.append("plantae")

			if not meta.has("statistics") or not (meta["statistics"] is Dictionary):
				meta["statistics"] = {}
			var meta_stats: Dictionary = meta["statistics"]
			if not meta_stats.has("prestige_count"):
				meta_stats["prestige_count"] = 0
			if not meta_stats.has("evolution_points_balance"):
				meta_stats["evolution_points_balance"] = 0
			if not meta_stats.has("total_biomass_lifetime"):
				meta_stats["total_biomass_lifetime"] = 0.0

		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if not run.has("statistics") or not (run["statistics"] is Dictionary):
				run["statistics"] = {}
			var run_stats: Dictionary = run["statistics"]
			if not run_stats.has("total_biomass_earned"):
				run_stats["total_biomass_earned"] = 0.0
			if not run_stats.has("tiles_colonized"):
				run_stats["tiles_colonized"] = 0
			if not run_stats.has("waves_defeated"):
				run_stats["waves_defeated"] = 0
	if from_version < 4:
		# v3 -> v4: split tile ownership into surface/subsurface layers.
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			var tiles_raw: Variant = run.get("tiles", [])
			if tiles_raw is Array:
				for tile in tiles_raw:
					if not (tile is Dictionary):
						continue
					var t: Dictionary = tile
					if t.has("owner_id") and not t.has("surface_owner"):
						t["surface_owner"] = t["owner_id"]
						t.erase("owner_id")
					if not t.has("surface_owner"):
						t["surface_owner"] = ""
					if not t.has("subsurface_owner"):
						t["subsurface_owner"] = ""
	if from_version < 5:
		# v4 -> v5: add niche_id to run; tile.data may carry parasite_decay_ticks.
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if not run.has("niche_id"):
				var kingdom_id: String = String(run.get("kingdom_id", ""))
				match kingdom_id:
					"plantae":
						run["niche_id"] = "photosynthesizer"
					"fungi":
						run["niche_id"] = "decomposer"
					_:
						run["niche_id"] = ""
	if from_version < 6:
		# v5 -> v6: add discovery log, kingdoms played, niche history, and per-run event dedup.
		if old.has("meta") and old["meta"] is Dictionary:
			var meta: Dictionary = old["meta"]
			if not meta.has("discovery_log"):
				meta["discovery_log"] = {}
			if not meta.has("kingdoms_played"):
				meta["kingdoms_played"] = []
			if not meta.has("niches_played"):
				meta["niches_played"] = []
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if not run.has("event_first_fires_seen"):
				run["event_first_fires_seen"] = []
	if from_version < 7:
		# v6 -> v7: niche id rename parasite_plantae -> parasitic_plantae (matches
		# colonization_rule string and unlock node id; was inconsistent in v6).
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if String(run.get("niche_id", "")) == "parasite_plantae":
				run["niche_id"] = "parasitic_plantae"
		if old.has("meta") and old["meta"] is Dictionary:
			var meta: Dictionary = old["meta"]
			var played: Array = meta.get("niches_played", []) as Array
			for i in played.size():
				if String(played[i]) == "parasite_plantae":
					played[i] = "parasitic_plantae"
			meta["niches_played"] = played
	if from_version < 8:
		# v7 -> v8: reserved for Phase 10.
		pass
	if from_version < 9:
		# v8 -> v9: add per-run goal fields (tile_history deferred).
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if not run.has("goal_id"):
				run["goal_id"] = ""
			if not run.has("goal_progress"):
				run["goal_progress"] = {}
			if not run.has("goal_met"):
				run["goal_met"] = false
	if from_version < 10:
		# v9 -> v10: retire symbiosis, add stub resources.
		if old.has("meta") and old["meta"] is Dictionary:
			var meta: Dictionary = old["meta"]
			var unlocked: Array = meta.get("unlocked_kingdoms", []) as Array
			unlocked.erase("symbiosis")
			meta["unlocked_kingdoms"] = unlocked
			var played: Array = meta.get("kingdoms_played", []) as Array
			played.erase("symbiosis")
			meta["kingdoms_played"] = played
		if old.has("run") and old["run"] is Dictionary:
			var run: Dictionary = old["run"]
			if String(run.get("kingdom_id", "")) == "symbiosis":
				run["kingdom_id"] = "fungi"
				run["niche_id"] = "lichen"
			var resources_raw: Variant = run.get("resources", {})
			var resources: Dictionary = resources_raw as Dictionary if resources_raw is Dictionary else {}
			for key in ["protein", "lifeforce", "blood_cohesion", "gray_matter", "mycelial_stability"]:
				if not resources.has(key):
					resources[key] = 0.0
			run["resources"] = resources
	if from_version < 11:
		# v10 -> v11: era + ecosystem state.
		if old.has("meta") and old["meta"] is Dictionary:
			var meta: Dictionary = old["meta"]
			if not meta.has("current_era_id"):
				meta["current_era_id"] = "cryogenian"
			if not meta.has("current_ecosystem_id"):
				meta["current_ecosystem_id"] = "cryo_polar_ice"
			if not meta.has("ecosystem_completions"):
				meta["ecosystem_completions"] = {}
			if not meta.has("eras_unlocked"):
				meta["eras_unlocked"] = ["cryogenian"]
			# Cryogenian only allows fungi — ensure the player has fungi
			# unlocked so they have something to play in the new era.
			var unlocked: Array = meta.get("unlocked_kingdoms", []) as Array
			if not unlocked.has("fungi"):
				unlocked.append("fungi")
				meta["unlocked_kingdoms"] = unlocked
			var tree: Dictionary = meta.get("evolution_tree", {}) as Dictionary
			if not bool(tree.get("unlock_fungi", false)):
				tree["unlock_fungi"] = true
				meta["evolution_tree"] = tree
	if from_version < 12:
		_migrate_v11_to_v12(old)
	if from_version < 13:
		_migrate_v12_to_v13(old)
	if from_version < 14:
		_migrate_v13_to_v14(old)
	if from_version < 15:
		_migrate_v14_to_v15(old)
	if from_version < 16:
		_migrate_v15_to_v16(old)
	if from_version < 17:
		_migrate_v16_to_v17(old)
	if from_version < 18:
		_migrate_v17_to_v18(old)
	if from_version < 19:
		_migrate_v18_to_v19(old)
	if from_version < 20:
		_migrate_v19_to_v20(old)
	return old


func _build_default_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"meta": {
			"unlocked_kingdoms": ["plantae", "fungi", "animals"],
			"evolution_tree": {"unlock_fungi": true},
			"discovery_log": {},
			"kingdoms_played": [],
			"species_unlocked": ["calamites", "tree_fern_psaronius", "mycorrhizal_network", "arthropleura", "dwarf_willow", "steppe_sedge", "cushion_moss", "reindeer_lichen", "permafrost_yeast"],
			"species_played": [],
			"lineages_played": [],
			"lineage_runs": [],
			"structures_discovered": [],
			"current_era_id": "carboniferous",
			"current_ecosystem_id": "carbo_coal_swamp",
			"eras_unlocked": ["carboniferous"],
			"ecosystem_completions": {},
			"post_extinction": {},
			"first_run_in_era_completed": [],
			"first_era_seen": "carboniferous",
			"statistics": {
				"prestige_count": 0,
				"evolution_points_balance": 0,
				"total_biomass_lifetime": 0.0
			}
		},
		"run": {
			"kingdom_id": "",
			"starting_species_id": "",
			"starting_species_kingdom_id": "",
			"unlocked_species_in_run": [],
			"run_seed": 0,
			"tick_count": 0,
			"adaptation": 0.0,
			"species_stat_boosts": {},
			"team": [],
			"biome_map": {},
			"fog_revealed": [],
			"obstacles": [],
			"active_structures": [],
			"tiles": [],
			"organisms": [],
			"active_events": [],
			"event_first_fires_seen": [],
			"goal_id": "",
			"goal_progress": {},
			"goal_met": false,
			"hero_biomass_lifetime_produced": 0.0,
			"cycle_closed": false,
			"checkpoints_fired": {},
			"statistics": {
				"total_biomass_earned": 0.0,
				"tiles_colonized": 0,
				"waves_defeated": 0
			}
		}
	}


func _write_save(save_dict: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: failed to open save file for write: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_dict, "\t"))


func _build_save_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"meta": GameState.meta_save if GameState.meta_save is Dictionary else {},
		"run": GameState.run_save if GameState.run_save is Dictionary else {}
	}


func _try_load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		push_warning("SaveSystem: JSON parse failed for %s" % path)
		return {}
	var raw: Variant = parser.data
	if not (raw is Dictionary):
		return {}
	var data: Dictionary = raw as Dictionary
	var save_version := int(data.get("save_version", 0))
	if save_version > SAVE_VERSION:
		push_error("SaveSystem: %s has newer save_version (%d > %d)" % [path, save_version, SAVE_VERSION])
		return {}
	if save_version < SAVE_VERSION:
		data = migrate(data, save_version)
		data["save_version"] = SAVE_VERSION
	return data


func _apply_loaded(data: Dictionary) -> void:
	GameState.meta_save = data.get("meta", {})
	GameState.run_save = data.get("run", {})
	_repair_species_unlocked(GameState.meta_save)
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	GameState.current_kingdom_id = StringName(
		run.get("starting_species_kingdom_id", run.get("kingdom_id", ""))
	)
	GameState.last_save_unix = int(data.get("saved_at_unix", 0))
	EventBus.run_loaded.emit(int(data.get("save_version", SAVE_VERSION)))


# Defensive backfill on every load — handles v12 saves created before the
# migration was patched to seed from unlocked_kingdoms (commit c4ee431+).
# Without this, players who tested early get stuck with species_unlocked=["pioneer_grass"]
# and can't enter Cryogenian (filter requires mycelium_thread).
func _repair_species_unlocked(meta: Dictionary) -> void:
	if not (meta is Dictionary):
		return
	var species_unlocked: Array = meta.get("species_unlocked", []) as Array
	var unlocked_kingdoms: Array = meta.get("unlocked_kingdoms", []) as Array
	var kingdoms_played: Array = meta.get("kingdoms_played", []) as Array
	var dirty: bool = false
	for kingdom in unlocked_kingdoms:
		var starter: StringName = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom), &"")
		if starter != &"" and not species_unlocked.has(String(starter)):
			species_unlocked.append(String(starter))
			dirty = true
	for kingdom in kingdoms_played:
		var starter: StringName = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom), &"")
		if starter != &"" and not species_unlocked.has(String(starter)):
			species_unlocked.append(String(starter))
			dirty = true
	if not species_unlocked.has("pioneer_grass"):
		species_unlocked.append("pioneer_grass")
		dirty = true
	# Phase 14a stopgap: auto-unlock the new species so they're testable in
	# the picker. Proper unlock-tree integration (grants_species nodes for
	# vent_archaeon / cryo_lichen / tree_fern_stem / wood_rot_bracket) lands
	# in a future polish pass.
	for sp_id in _PHASE_14A_AUTO_UNLOCK:
		if not species_unlocked.has(sp_id):
			species_unlocked.append(sp_id)
			dirty = true
	if not meta.has("lineages_played"):
		meta["lineages_played"] = []
		dirty = true
	if not meta.has("lineage_runs"):
		meta["lineage_runs"] = []
		dirty = true
	if not meta.has("post_extinction"):
		meta["post_extinction"] = {}
		dirty = true
	if not meta.has("first_run_in_era_completed"):
		meta["first_run_in_era_completed"] = []
		dirty = true
	if not meta.has("first_era_seen"):
		meta["first_era_seen"] = String(meta.get("current_era_id", ""))
		dirty = true
	if dirty:
		meta["species_unlocked"] = species_unlocked
	
	# Phase 15a: defensive backfill for tile ages and species tile counts
	var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
	if not run.has("tile_ages"):
		run["tile_ages"] = {}
	if not run.has("species_tile_counts"):
		run["species_tile_counts"] = {}
	if not run.has("adaptation"):
		run["adaptation"] = 0.0
	if not run.has("species_stat_boosts"):
		run["species_stat_boosts"] = {}
	if not run.has("hero_biomass_lifetime_produced"):
		run["hero_biomass_lifetime_produced"] = 0.0
	if not run.has("cycle_closed"):
		run["cycle_closed"] = false
	if not run.has("checkpoints_fired"):
		run["checkpoints_fired"] = {}


func _migrate_v11_to_v12(save: Dictionary) -> void:
	var meta: Dictionary = save.get("meta", {}) as Dictionary
	var kingdoms_played: Array = meta.get("kingdoms_played", []) as Array
	var unlocked_kingdoms: Array = meta.get("unlocked_kingdoms", []) as Array
	var species_unlocked: Array = meta.get("species_unlocked", []) as Array
	# Seed default starters from any kingdom the player has unlocked OR played.
	# Without this, a v11 save with fungi unlocked but never-played leaves
	# Cryogenian ecosystems (filter=[mycelium_thread]) un-enterable in v12.
	for kingdom in unlocked_kingdoms:
		var starter: StringName = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom), &"")
		if starter != &"" and not species_unlocked.has(String(starter)):
			species_unlocked.append(String(starter))
	for kingdom in kingdoms_played:
		var starter: StringName = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom), &"")
		if starter != &"" and not species_unlocked.has(String(starter)):
			species_unlocked.append(String(starter))
	if not species_unlocked.has("pioneer_grass"):
		species_unlocked.append("pioneer_grass")
	meta["species_unlocked"] = species_unlocked
	if not meta.has("species_played"):
		meta["species_played"] = []
	meta.erase("niches_played")
	save["meta"] = meta

	var run: Dictionary = save.get("run", {}) as Dictionary
	var kingdom_id: String = String(run.get("kingdom_id", ""))
	var niche_id: String = String(run.get("niche_id", ""))
	var starter_species: StringName = &""
	if niche_id != "":
		starter_species = _NICHE_TO_STARTER_SPECIES.get(StringName(niche_id), &"")
	if starter_species == &"" and kingdom_id != "":
		starter_species = _KINGDOM_DEFAULT_STARTERS.get(StringName(kingdom_id), &"")

	if starter_species != &"":
		run["starting_species_id"] = String(starter_species)
		var in_run: Array = [String(starter_species)]
		if niche_id == "lichen":
			if not in_run.has("pioneer_grass"):
				in_run.append("pioneer_grass")
			if not in_run.has("mycelium_thread"):
				in_run.append("mycelium_thread")
		run["unlocked_species_in_run"] = in_run
		run["starting_species_kingdom_id"] = kingdom_id
	else:
		if not run.has("starting_species_id"):
			run["starting_species_id"] = ""
		if not run.has("unlocked_species_in_run"):
			run["unlocked_species_in_run"] = []
		if not run.has("starting_species_kingdom_id"):
			run["starting_species_kingdom_id"] = ""

	run.erase("niche_id")
	var active: Array = run.get("active_events", []) as Array
	for entry in active:
		if entry is Dictionary:
			var payload: Dictionary = entry.get("payload", {}) as Dictionary
			if not payload.has("scope"):
				payload["scope"] = "world"
			entry["payload"] = payload
	run["active_events"] = active

	var tiles: Array = run.get("tiles", []) as Array
	var migrated_tiles: Array = []
	for entry in tiles:
		if not (entry is Dictionary):
			continue
		var coord: Variant = entry.get("coord", null)
		if coord == null:
			continue
		var data: Dictionary = entry.get("data", {}) as Dictionary
		var surface_owner: String = String(entry.get("surface_owner", ""))
		var subsurface_owner: String = String(entry.get("subsurface_owner", ""))
		var occupants: Dictionary = {}
		if surface_owner == "plantae":
			occupants["plantae"] = String(_pick_species_for_kingdom(starter_species, &"plantae", niche_id))
		elif surface_owner == "animals":
			occupants["animals"] = String(_pick_species_for_kingdom(starter_species, &"animals", niche_id))
		if subsurface_owner == "fungi":
			occupants["fungi"] = String(_pick_species_for_kingdom(starter_species, &"fungi", niche_id))
		if occupants.is_empty():
			continue
		migrated_tiles.append({
			"coord": coord,
			"occupants": occupants,
			"data": data
		})
	run["tiles"] = migrated_tiles
	save["run"] = run


func _migrate_v12_to_v13(save: Dictionary) -> void:
	var meta: Dictionary = save.get("meta", {}) as Dictionary
	if not meta.has("lineages_played"):
		meta["lineages_played"] = []
	var lineages: Array = meta.get("lineages_played", []) as Array
	var species_played: Array = meta.get("species_played", []) as Array
	for sp_id in species_played:
		var lineage: StringName = _SPECIES_TO_LINEAGE.get(StringName(sp_id), &"")
		if lineage != &"" and not lineages.has(String(lineage)):
			lineages.append(String(lineage))
	meta["lineages_played"] = lineages
	save["meta"] = meta


func _migrate_v13_to_v14(save: Dictionary) -> void:
	var meta: Dictionary = save.get("meta", {}) as Dictionary
	if not meta.has("post_extinction"):
		meta["post_extinction"] = {}
	if not meta.has("first_run_in_era_completed"):
		meta["first_run_in_era_completed"] = []
	if not meta.has("first_era_seen"):
		meta["first_era_seen"] = String(meta.get("current_era_id", ""))
	save["meta"] = meta

	var run: Dictionary = save.get("run", {}) as Dictionary
	var active: Array = run.get("active_events", []) as Array
	for entry in active:
		if entry is Dictionary:
			var payload: Dictionary = entry.get("payload", {}) as Dictionary
			if not payload.has("scope"):
				payload["scope"] = "world"
			entry["payload"] = payload
	run["active_events"] = active
	save["run"] = run


func _migrate_v14_to_v15(save: Dictionary) -> void:
	var run: Dictionary = save.get("run", {}) as Dictionary
	if not run.has("tile_ages"):
		run["tile_ages"] = {}
	if not run.has("species_tile_counts"):
		# Recompute from current tiles[].occupants — keeps existing runs accurate.
		var counts: Dictionary = {}
		var tiles: Array = run.get("tiles", []) as Array
		for entry in tiles:
			if not (entry is Dictionary):
				continue
			var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
			for kingdom_id in occupants.keys():
				var sp_id: String = String(occupants[kingdom_id])
				counts[sp_id] = int(counts.get(sp_id, 0)) + 1
		run["species_tile_counts"] = counts
	save["run"] = run

	var meta: Dictionary = save.get("meta", {}) as Dictionary
	if not meta.has("lifetime_counters"):
		meta["lifetime_counters"] = {
			"tiles_placed_lifetime": 0,
			"clusters_formed_lifetime": 0
		}
	save["meta"] = meta


func _migrate_v15_to_v16(save: Dictionary) -> void:
	var run: Dictionary = save.get("run", {}) as Dictionary

	if not run.has("fog_revealed"):
		# Reveal around existing owned tiles so visibility isn't lost.
		var revealed: Array = []
		var tiles: Array = run.get("tiles", []) as Array
		var seen: Dictionary = {}
		for entry in tiles:
			if not (entry is Dictionary):
				continue
			var coord: Variant = entry.get("coord", null)
			if coord is Array and coord.size() == 2:
				_flood_reveal(int(coord[0]), int(coord[1]), 2, seen)
		for k in seen.keys():
			revealed.append(k)
		run["fog_revealed"] = revealed

	if not run.has("obstacles"):
		# Generate deterministically from run_seed if present; otherwise empty.
		if run.has("run_seed") and int(run.get("run_seed", 0)) != 0:
			run["obstacles"] = _generate_obstacles(int(run["run_seed"]))
		else:
			run["obstacles"] = []

	if not run.has("active_structures"):
		run["active_structures"] = []

	save["run"] = run

	var meta: Dictionary = save.get("meta", {}) as Dictionary
	if not meta.has("structures_discovered"):
		meta["structures_discovered"] = []
	save["meta"] = meta


func _migrate_v16_to_v17(save: Dictionary) -> void:
	var run: Dictionary = save.get("run", {}) as Dictionary
	if not run.has("adaptation"):
		run["adaptation"] = 0.0
	if not run.has("species_levels"):
		run["species_levels"] = {}
	save["run"] = run


# v17 → v18: enforce single-species-per-tile invariant. Tiles in v17 could hold
# up to 3 kingdom slots (plantae + fungi + animals); v18 keeps exactly one.
# When a tile had >1 occupant, the dominant kingdom (per
# _SINGLE_OCCUPANT_KINGDOM_PRECEDENCE) wins; others are discarded with a
# warning. The `occupants` dict shape is preserved on disk but is enforced
# to have at most one entry from this version forward. species_tile_counts is
# recomputed to match. See docs/MIGRATION_PLAN.md VM-A2.
func _migrate_v17_to_v18(save: Dictionary) -> void:
	var run: Dictionary = save.get("run", {}) as Dictionary
	var tiles_raw: Variant = run.get("tiles", [])
	if not (tiles_raw is Array):
		return
	var migrated_tiles: Array = []
	var discard_count: int = 0
	for entry in tiles_raw:
		if not (entry is Dictionary):
			continue
		var t: Dictionary = entry
		var occupants_raw: Variant = t.get("occupants", {})
		if not (occupants_raw is Dictionary):
			migrated_tiles.append(t)
			continue
		var occupants: Dictionary = occupants_raw
		if occupants.is_empty():
			# Already conformant (empty tile is fine).
			migrated_tiles.append(t)
			continue
		# Pick dominant by precedence.
		var picked_kingdom: StringName = &""
		var picked_species: StringName = &""
		for k in _SINGLE_OCCUPANT_KINGDOM_PRECEDENCE:
			if occupants.has(String(k)):
				picked_kingdom = k
				picked_species = StringName(occupants[String(k)])
				break
			if occupants.has(k):
				picked_kingdom = k
				picked_species = StringName(occupants[k])
				break
		if picked_kingdom == &"":
			# No matching kingdom in precedence list — pick first arbitrary entry.
			var any_keys: Array = occupants.keys()
			if any_keys.is_empty():
				migrated_tiles.append(t)
				continue
			picked_kingdom = StringName(any_keys[0])
			picked_species = StringName(occupants[any_keys[0]])
		discard_count += maxi(0, occupants.size() - 1)
		t["occupants"] = {String(picked_kingdom): String(picked_species)}
		migrated_tiles.append(t)
	run["tiles"] = migrated_tiles
	# Recompute species_tile_counts from the flattened tiles.
	var counts: Dictionary = {}
	for entry in migrated_tiles:
		if not (entry is Dictionary):
			continue
		var occupants: Dictionary = entry.get("occupants", {}) as Dictionary
		for kingdom_id in occupants.keys():
			var sp_id: String = String(occupants[kingdom_id])
			counts[sp_id] = int(counts.get(sp_id, 0)) + 1
	run["species_tile_counts"] = counts
	save["run"] = run
	if discard_count > 0:
		push_warning("SaveSystem: v17→v18 migration discarded %d co-occupant entries (single-species-per-tile invariant)" % discard_count)


# Helper to flood reveal around a coord (radius in each direction).
static func _flood_reveal(cx: int, cy: int, radius: int, into: Dictionary) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			into["%d,%d" % [cx + dx, cy + dy]] = true


# Deterministic obstacle generator (mirrors ObstacleSystem).
static func _generate_obstacles(seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	const GRID_W: int = 32
	const GRID_H: int = 48
	const RATE: float = 0.05
	const START_CLEAR_RADIUS: int = 3
	var cx: int = int(GRID_W / 2)
	var cy: int = int(GRID_H / 2)
	var out: Array = []
	for y in range(GRID_H):
		for x in range(GRID_W):
			if abs(x - cx) <= START_CLEAR_RADIUS and abs(y - cy) <= START_CLEAR_RADIUS:
				continue
			if rng.randf() < RATE:
				out.append("%d,%d" % [x, y])
	return out


func _pick_species_for_kingdom(starter_species: StringName, kingdom_id: StringName, niche_id: String) -> StringName:
	if niche_id == "lichen":
		if kingdom_id == &"plantae":
			return &"pioneer_grass"
		if kingdom_id == &"fungi":
			return &"mycelium_thread"
	var species_index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
	if species_index != null:
		for sp in species_index.species:
			if sp.id == starter_species and sp.kingdom_id == kingdom_id:
				return starter_species
	return _KINGDOM_DEFAULT_STARTERS.get(kingdom_id, &"")


# v18 → v19: alpha-content reset. The era/biome/species catalogue was rebuilt
# around Carboniferous + Pleistocene as the canonical starter pair. Legacy
# Cryogenian/Devonian eras + their ecosystems are retired, so any save still
# pointing at them gets redirected into Coal Swamp. Legacy species are
# gated by era_requires = "deferred" — they stay in species_unlocked so the
# player doesn't visibly lose unlocks, but they won't appear in the picker
# until/unless we ship a "Deep Time" era.
const _ALPHA_DEFAULT_SPECIES_UNLOCKS: Array = [
	"calamites", "tree_fern_psaronius", "mycorrhizal_network", "arthropleura",
	"dwarf_willow", "steppe_sedge", "cushion_moss", "reindeer_lichen", "permafrost_yeast"
]
const _LEGACY_ERA_IDS: Array = ["cryogenian", "devonian"]

func _migrate_v18_to_v19(save: Dictionary) -> void:
	var meta: Dictionary = save.get("meta", {}) as Dictionary
	# Era + ecosystem pointers. Anyone in Cryo/Devonian lands in Coal Swamp.
	var current_era: String = String(meta.get("current_era_id", ""))
	if current_era == "" or _LEGACY_ERA_IDS.has(current_era):
		meta["current_era_id"] = "carboniferous"
		meta["current_ecosystem_id"] = "carbo_coal_swamp"
	# eras_unlocked: drop legacy ids, ensure "carboniferous" is present.
	var eras_unlocked: Array = meta.get("eras_unlocked", []) as Array
	var pruned_eras: Array = []
	for era in eras_unlocked:
		if not _LEGACY_ERA_IDS.has(String(era)):
			pruned_eras.append(era)
	if not pruned_eras.has("carboniferous"):
		pruned_eras.append("carboniferous")
	meta["eras_unlocked"] = pruned_eras
	# first_era_seen: rewrite if it was a legacy era.
	if _LEGACY_ERA_IDS.has(String(meta.get("first_era_seen", ""))):
		meta["first_era_seen"] = "carboniferous"
	# ecosystem_completions: drop entries for retired ecosystem ids.
	var completions: Dictionary = meta.get("ecosystem_completions", {}) as Dictionary
	for key in completions.keys():
		var sk := String(key)
		if sk.begins_with("cryo_") or sk.begins_with("dev_"):
			completions.erase(key)
	meta["ecosystem_completions"] = completions
	# post_extinction: if it points at a retired era, clear it (no debuff to apply).
	var pe: Dictionary = meta.get("post_extinction", {}) as Dictionary
	if _LEGACY_ERA_IDS.has(String(pe.get("to_era_id", ""))):
		meta["post_extinction"] = {}
	# first_run_in_era_completed: drop legacy era ids.
	var frc: Array = meta.get("first_run_in_era_completed", []) as Array
	var pruned_frc: Array = []
	for entry in frc:
		if not _LEGACY_ERA_IDS.has(String(entry)):
			pruned_frc.append(entry)
	meta["first_run_in_era_completed"] = pruned_frc
	# species_unlocked: ensure the alpha starters are present so the picker
	# always has something to show. Legacy ids stay in the list but are
	# inert thanks to era_requires = "deferred".
	var species_unlocked: Array = meta.get("species_unlocked", []) as Array
	for alpha_id in _ALPHA_DEFAULT_SPECIES_UNLOCKS:
		if not species_unlocked.has(alpha_id):
			species_unlocked.append(alpha_id)
	meta["species_unlocked"] = species_unlocked
	# unlocked_kingdoms: ensure animals is present (alpha eras include animals).
	var kingdoms: Array = meta.get("unlocked_kingdoms", []) as Array
	for kingdom in ["plantae", "fungi", "animals"]:
		if not kingdoms.has(kingdom):
			kingdoms.append(kingdom)
	meta["unlocked_kingdoms"] = kingdoms
	# Re-show onboarding — the alpha-lock tutorial is a different script
	# (Coal Swamp specific), so anyone migrating from a legacy save should
	# see it once even if they had previously dismissed the old one.
	meta["onboarding_step"] = 0
	save["meta"] = meta


func _migrate_v19_to_v20(save: Dictionary) -> void:
	var run: Dictionary = save.get("run", {}) as Dictionary
	if run.has("species_levels") and not run.has("species_stat_boosts"):
		run["species_stat_boosts"] = {}
		run.erase("species_levels")
	if not run.has("species_stat_boosts"):
		run["species_stat_boosts"] = {}
	if not run.has("team"):
		run["team"] = []
	run.erase("resources")
	save["run"] = run
