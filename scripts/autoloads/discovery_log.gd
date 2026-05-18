extends Node
##
## DiscoveryLog — owns the index of authored entries, tracks which are unlocked,
## and exposes unlock/query API. Trigger wiring lives here.
##

const DISCOVERY_INDEX_PATH: String = "res://data/discovery/_index.tres"

const _MILESTONES: Dictionary[StringName, int] = {
	&"prestige_5": 5,
	&"prestige_25": 25,
	&"prestige_50": 50
}

var _all_entries: Array[DiscoveryEntry] = []
var _entries_by_id: Dictionary[StringName, DiscoveryEntry] = {}
var _trigger_index: Dictionary[String, StringName] = {}


func _enter_tree() -> void:
	EventBus.evolution_node_unlocked.connect(_on_evolution_node_unlocked)
	EventBus.species_introduced.connect(_on_species_introduced)
	EventBus.event_resolved.connect(_on_event_resolved)
	EventBus.prestige_triggered.connect(_on_prestige_triggered)
	EventBus.run_started.connect(_on_run_started)
	EventBus.era_changed.connect(_on_era_changed)
	EventBus.ecosystem_completed.connect(_on_ecosystem_completed)
	EventBus.era_transition_started.connect(_on_era_transition_started)


func _ready() -> void:
	add_to_group("discovery_log")
	var index: DiscoveryIndex = load(DISCOVERY_INDEX_PATH) as DiscoveryIndex
	if index == null:
		push_error("DiscoveryLog: missing discovery index")
		return
	_all_entries = index.entries
	_entries_by_id.clear()
	_trigger_index.clear()
	for entry in _all_entries:
		if entry == null:
			continue
		_entries_by_id[entry.id] = entry
		if entry.category != &"" and entry.trigger_id != &"":
			var key := "%s:%s" % [String(entry.category), String(entry.trigger_id)]
			_trigger_index[key] = entry.id


func get_all_entries() -> Array[DiscoveryEntry]:
	return _all_entries


func get_unlocked_entries() -> Array[DiscoveryEntry]:
	var log: Dictionary = GameState.meta_save.get("discovery_log", {})
	var result: Array[DiscoveryEntry] = []
	for entry in _all_entries:
		if entry == null:
			continue
		if bool(log.get(String(entry.id), false)):
			result.append(entry)
	return result


func get_total_count() -> int:
	return _all_entries.size()


func get_unlocked_count() -> int:
	var log: Dictionary = GameState.meta_save.get("discovery_log", {})
	var count := 0
	for key in log.keys():
		if bool(log[key]):
			count += 1
	return count


func is_unlocked(entry_id: StringName) -> bool:
	var log: Dictionary = GameState.meta_save.get("discovery_log", {})
	return bool(log.get(String(entry_id), false))


func unlock(entry_id: StringName) -> bool:
	if not _entries_by_id.has(entry_id):
		push_warning("DiscoveryLog: unknown entry id %s" % String(entry_id))
		return false
	if is_unlocked(entry_id):
		return false
	var log: Dictionary = GameState.meta_save.get("discovery_log", {}) as Dictionary
	log[String(entry_id)] = true
	GameState.meta_save["discovery_log"] = log
	EventBus.discovery_unlocked.emit(entry_id)
	SaveSystem.save_now()
	return true


func find_entry_for_trigger(category: StringName, trigger_id: StringName) -> StringName:
	var key := "%s:%s" % [String(category), String(trigger_id)]
	return _trigger_index.get(key, &"")


func _on_evolution_node_unlocked(node_id: StringName) -> void:
	var node_entry := find_entry_for_trigger(&"node", node_id)
	if node_entry != &"":
		unlock(node_entry)
	var node: EvolutionNodeData = _lookup_node(node_id)
	if node != null:
		for kingdom_id in node.grants_kingdoms:
			var kingdom_entry := find_entry_for_trigger(&"kingdom", kingdom_id)
			if kingdom_entry != &"":
				unlock(kingdom_entry)
	if node != null and not node.requires_kingdom_played.is_empty():
		var milestone_entry := find_entry_for_trigger(&"milestone", &"first_cross_kingdom_node")
		if milestone_entry != &"":
			unlock(milestone_entry)


func _on_species_introduced(species_id: StringName) -> void:
	if species_id == &"":
		return
	var entry := find_entry_for_trigger(&"species", species_id)
	if entry != &"":
		unlock(entry)
	var starter: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
	if species_id == starter:
		var played: Array = GameState.meta_save.get("species_played", []) as Array
		if not played.has(String(species_id)):
			played.append(String(species_id))
			GameState.meta_save["species_played"] = played
			SaveSystem.save_now()


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
	var seen: Array = GameState.run_save.get("event_first_fires_seen", []) as Array
	if seen.has(String(event_id)):
		return
	seen.append(String(event_id))
	GameState.run_save["event_first_fires_seen"] = seen
	var entry := find_entry_for_trigger(&"event", event_id)
	if entry != &"":
		unlock(entry)
	else:
		SaveSystem.save_now()


func _on_run_started(kingdom_id: StringName) -> void:
	if kingdom_id != &"":
		var entry := find_entry_for_trigger(&"kingdom", kingdom_id)
		if entry != &"":
			unlock(entry)
	var starter: StringName = String(GameState.run_save.get("starting_species_id", ""))
	if starter != "":
		_on_species_introduced(StringName(starter))


func _on_prestige_triggered(_summary: Dictionary) -> void:
	var stats: Dictionary = GameState.meta_save.get("statistics", {})
	var count: int = int(stats.get("prestige_count", 0))
	for milestone_id in _MILESTONES.keys():
		var threshold: int = _MILESTONES[milestone_id]
		if count >= threshold:
			var entry := find_entry_for_trigger(&"milestone", milestone_id)
			if entry != &"":
				unlock(entry)


func _on_era_changed(era_id: StringName) -> void:
	if era_id == &"":
		return
	var entry := find_entry_for_trigger(&"era", era_id)
	if entry != &"":
		unlock(entry)


func _on_ecosystem_completed(ecosystem_id: StringName) -> void:
	if ecosystem_id == &"":
		return
	var entry := find_entry_for_trigger(&"ecosystem", ecosystem_id)
	if entry != &"":
		unlock(entry)


func _on_era_transition_started(_from: StringName, _to: StringName) -> void:
	var milestone := find_entry_for_trigger(&"milestone", &"first_era_transition")
	if milestone != &"":
		unlock(milestone)
	var era_entry := find_entry_for_trigger(&"era", _to)
	if era_entry != &"":
		unlock(era_entry)


func _lookup_node(node_id: StringName) -> EvolutionNodeData:
	var ps := get_tree().get_first_node_in_group("prestige_system")
	if ps == null:
		return null
	for node in ps.get_all_nodes():
		if node.id == node_id:
			return node
	return null
