extends Node
##
## SaveSystem — JSON save/load with versioned migrations.
## Schema and migration convention in docs/ARCHITECTURE.md sections 3 and 9.
## Implementation in brief 03. Changes here MUST be reviewed by Claude.
##

const SAVE_VERSION: int = 4
const SAVE_PATH: String = "user://save.json"


func _ready() -> void:
	# Autosave is driven by _notification for cross-platform pause/quit.
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		save_now()


func save_now() -> void:
	# TODO brief 03 — synchronous write, safe to call from tree_exiting.
	var save_dict := {
		"save_version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"meta": GameState.meta_save if GameState.meta_save is Dictionary else {},
		"run": GameState.run_save if GameState.run_save is Dictionary else {}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: failed to open save file for write: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_dict, "\t"))


func load_or_create() -> void:
	# TODO brief 03 — load existing or build default. Hydrate GameState.
	# Emit EventBus.run_loaded(save_version) when done.
	if not FileAccess.file_exists(SAVE_PATH):
		var fresh := _build_default_save()
		_write_save(fresh)
		GameState.meta_save = fresh["meta"]
		GameState.run_save = fresh["run"]
		GameState.last_save_unix = int(Time.get_unix_time_from_system())
		EventBus.run_loaded.emit(fresh["save_version"])
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: failed to open save file for read: %s" % SAVE_PATH)
		return

	var parse := JSON.new()
	var err := parse.parse(file.get_as_text())
	if err != OK:
		push_error("SaveSystem: failed to parse save JSON: %s" % SAVE_PATH)
		return

	var raw: Variant = parse.data
	if not (raw is Dictionary):
		push_error("SaveSystem: save JSON root is not a Dictionary.")
		return
	var data: Dictionary = raw as Dictionary

	var save_version := int(data.get("save_version", 0))
	if save_version > SAVE_VERSION:
		push_error("SaveSystem: save version %d is newer than build %d." % [save_version, SAVE_VERSION])
		return
	if save_version < SAVE_VERSION:
		data = migrate(data, save_version)
		data["save_version"] = SAVE_VERSION
		_write_save(data)

	GameState.meta_save = data.get("meta", {})
	GameState.run_save = data.get("run", {})
	GameState.last_save_unix = int(data.get("saved_at_unix", 0))
	EventBus.run_loaded.emit(int(data.get("save_version", SAVE_VERSION)))


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var err := DirAccess.remove_absolute(SAVE_PATH)
		if err != OK:
			push_error("SaveSystem: failed to delete save file: %s" % SAVE_PATH)
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
	return old


func _build_default_save() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"saved_at_unix": Time.get_unix_time_from_system(),
		"meta": {
			"unlocked_kingdoms": ["plantae"],
			"evolution_tree": {},
			"statistics": {
				"prestige_count": 0,
				"evolution_points_balance": 0,
				"total_biomass_lifetime": 0.0
			}
		},
		"run": {
			"kingdom_id": "",
			"run_seed": 0,
			"tick_count": 0,
			"resources": {},
			"biome_map": {},
			"tiles": [],
			"organisms": [],
			"active_events": [],
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
