extends Node

const SCAN_INTERVAL_TICKS: int = 5
const STRUCTURE_INDEX_PATH: String = "res://data/structures/_index.tres"

var _structures: Array[StructureData] = []
var _structures_by_id: Dictionary[StringName, StructureData] = {}
var _active: Array[Dictionary] = []
var _last_scan_tick: int = 0
# Perf (Tier 2): coalesce multiple tile changes within a SCAN_INTERVAL_TICKS
# window into a single _scan. Previously every tile_colonized / tile_lost
# triggered an immediate full grid scan on top of the periodic _on_tick scan.
var _scan_dirty: bool = false

@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")


func _ready() -> void:
	_load_structures()
	EventBus.tick.connect(_on_tick)
	EventBus.run_loaded.connect(_on_run_loaded)
	EventBus.tile_colonized.connect(func(_c, _o): _scan_dirty = true)
	EventBus.tile_lost.connect(func(_c, _o): _scan_dirty = true)


func _load_structures() -> void:
	_structures.clear()
	_structures_by_id.clear()
	var index: StructureIndex = load(STRUCTURE_INDEX_PATH) as StructureIndex
	if index == null:
		return
	for sd in index.structures:
		if sd != null:
			_structures.append(sd)
			_structures_by_id[sd.id] = sd


func _on_run_loaded(_v: int) -> void:
	_active.clear()
	_clear_all_structure_bonuses()
	_scan()


func _on_tick(_delta: float) -> void:
	_last_scan_tick += 1
	if _last_scan_tick < SCAN_INTERVAL_TICKS:
		return
	_last_scan_tick = 0
	if not _scan_dirty:
		# No tile changes since last scan — structure set can't have changed.
		return
	_scan()


func _scan() -> void:
	_scan_dirty = false
	# Perf (Tier 2): skip pattern matching for any structure whose required
	# kingdom has zero tiles. Cuts the per-scan cost in half early/mid run.
	# Authoring order in `_structures` (= order in structures/_index.tres) IS
	# the precedence rule for one-structure-per-tile claim: the first match
	# in iteration order wins; later candidates touching a claimed tile skip.
	var candidates: Array[Dictionary] = []
	for sd in _structures:
		var required_kingdom: StringName = StringName(sd.pattern_params.get("kingdom_id", ""))
		if required_kingdom != &"" and _territory.get_kingdom_occupied_coords(required_kingdom).is_empty():
			continue
		var matches: Array = _find_pattern_matches(sd)
		for m in matches:
			candidates.append({
				"id": sd.id,
				"anchor": m["anchor"],
				"tiles": m["tiles"]
			})
	# Greedy claim pass — one structure per tile.
	var claimed_tiles: Dictionary = {}
	var newly_active: Array[Dictionary] = []
	for entry in candidates:
		var conflict: bool = false
		for c in entry["tiles"]:
			if claimed_tiles.has(c):
				conflict = true
				break
		if conflict:
			continue
		for c in entry["tiles"]:
			claimed_tiles[c] = true
		newly_active.append(entry)

	var old_keys: Dictionary = {}
	for entry in _active:
		old_keys[_active_key(entry)] = entry
	var new_keys: Dictionary = {}
	for entry in newly_active:
		new_keys[_active_key(entry)] = entry

	for k in old_keys.keys():
		if not new_keys.has(k):
			_revert_structure(old_keys[k])

	for k in new_keys.keys():
		if not old_keys.has(k):
			_promote_structure(new_keys[k])

	_active = newly_active
	_persist_active()


func _active_key(entry: Dictionary) -> String:
	return "%s@%s" % [String(entry["id"]), str(entry["anchor"])]


func _promote_structure(entry: Dictionary) -> void:
	var sd: StructureData = _structures_by_id.get(entry["id"], null)
	if sd == null:
		return
	_apply_bonus(sd, entry)
	if _tile_grid.has_method("add_structure_halo"):
		_tile_grid.add_structure_halo(_active_key(entry), entry["tiles"], sd.halo_color)
	EventBus.structure_promoted.emit(sd.id, entry["anchor"])
	var played: Array = GameState.meta_save.get("structures_discovered", []) as Array
	if not played.has(String(sd.id)):
		played.append(String(sd.id))
		GameState.meta_save["structures_discovered"] = played
		SaveSystem.save_now()


func _revert_structure(entry: Dictionary) -> void:
	var sd: StructureData = _structures_by_id.get(entry["id"], null)
	if sd == null:
		return
	_revert_bonus(sd, entry)
	if _tile_grid.has_method("remove_structure_halo"):
		_tile_grid.remove_structure_halo(_active_key(entry))


func _apply_bonus(sd: StructureData, entry: Dictionary) -> void:
	match sd.bonus_handler:
		&"mycorrhizal_hub":
			_bonus_mycorrhizal_hub(entry, true)
		&"old_growth_stand":
			_bonus_old_growth_stand(entry, true)
		&"fairy_ring":
			_bonus_fairy_ring(entry, true)
		&"decay_pit":
			_bonus_decay_pit(entry, true)
		&"fern_grove":
			_bonus_fern_grove(entry, true)
		_:
			push_warning("StructureRegistry: unknown bonus handler %s" % String(sd.bonus_handler))


func _revert_bonus(sd: StructureData, entry: Dictionary) -> void:
	match sd.bonus_handler:
		&"mycorrhizal_hub":
			_bonus_mycorrhizal_hub(entry, false)
		&"old_growth_stand":
			_bonus_old_growth_stand(entry, false)
		&"fairy_ring":
			_bonus_fairy_ring(entry, false)
		&"decay_pit":
			_bonus_decay_pit(entry, false)
		&"fern_grove":
			_bonus_fern_grove(entry, false)


func _clear_all_structure_bonuses() -> void:
	for entry in _active:
		var sd: StructureData = _structures_by_id.get(entry["id"], null)
		if sd != null:
			_revert_bonus(sd, entry)


func _persist_active() -> void:
	var arr: Array = []
	for entry in _active:
		var tile_list: Array = []
		for c in entry["tiles"]:
			tile_list.append([c.x, c.y])
		arr.append({
			"id": String(entry["id"]),
			"anchor": [entry["anchor"].x, entry["anchor"].y],
			"tiles": tile_list
		})
	GameState.run_save["active_structures"] = arr


func _find_pattern_matches(sd: StructureData) -> Array:
	match sd.pattern_type:
		&"block_NxM_same_species":
			return _match_block(sd.pattern_params)
		&"ring_radius_N":
			return _match_ring(sd.pattern_params)
		&"square_NxM_with_adjacent":
			return _match_block_with_adjacent(sd.pattern_params)
		&"area_on_biome":
			return _match_area_on_biome(sd.pattern_params)
		&"cross_5_same_species":
			return _match_cross_5(sd.pattern_params)
		_:
			return []


func _match_block(params: Dictionary) -> Array:
	var w: int = int(params.get("width", 3))
	var h: int = int(params.get("height", 3))
	var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
	# Optional species lock — when set, the block must be made of this exact
	# species (e.g., Fern Grove requires tree_fern_psaronius, not any plantae).
	# Empty = "any same species", the legacy behavior.
	var required_species: StringName = StringName(params.get("required_species", ""))
	var out: Array = []
	for y in range(_tile_grid.GRID_HEIGHT - h + 1):
		for x in range(_tile_grid.GRID_WIDTH - w + 1):
			var anchor: Vector2i = Vector2i(x, y)
			var coords: Array[Vector2i] = []
			var first_species: StringName = &""
			var ok: bool = true
			for dy in range(h):
				for dx in range(w):
					var c: Vector2i = Vector2i(x + dx, y + dy)
					var sp: StringName = _territory.get_occupant(c, kingdom_id)
					if sp == &"":
						ok = false
						break
					if required_species != &"" and sp != required_species:
						ok = false
						break
					if first_species == &"":
						first_species = sp
					elif sp != first_species:
						ok = false
						break
					coords.append(c)
				if not ok:
					break
			if ok:
				out.append({"anchor": anchor, "tiles": coords})
	return out


func _match_cross_5(params: Dictionary) -> Array:
	# Plus / cross shape: a center tile plus its 4 cardinal neighbors, all of
	# the same species (and optionally locked to a specific species). Used by
	# Fern Grove — fronds spreading radially from a central frond.
	var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
	var required_species: StringName = StringName(params.get("required_species", ""))
	var out: Array = []
	for y in range(1, _tile_grid.GRID_HEIGHT - 1):
		for x in range(1, _tile_grid.GRID_WIDTH - 1):
			var center: Vector2i = Vector2i(x, y)
			var positions: Array[Vector2i] = [
				center,
				center + Vector2i.UP,
				center + Vector2i.DOWN,
				center + Vector2i.LEFT,
				center + Vector2i.RIGHT,
			]
			var first_species: StringName = &""
			var ok: bool = true
			for p in positions:
				var sp: StringName = _territory.get_occupant(p, kingdom_id)
				if sp == &"":
					ok = false
					break
				if required_species != &"" and sp != required_species:
					ok = false
					break
				if first_species == &"":
					first_species = sp
				elif sp != first_species:
					ok = false
					break
			if ok:
				out.append({"anchor": center, "tiles": positions})
	return out


func _match_block_with_adjacent(params: Dictionary) -> Array:
	var block_matches: Array = _match_block(params)
	var adj_kingdom: StringName = StringName(params.get("adjacent_kingdom_id", ""))
	var min_adj: int = int(params.get("min_adjacent", 4))
	var out: Array = []
	for m in block_matches:
		var coord_set: Dictionary = {}
		for c in m["tiles"]:
			coord_set[c] = true
		var adj_count: int = 0
		var seen_adj: Dictionary = {}
		for c in m["tiles"]:
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var n: Vector2i = c + offset
				if coord_set.has(n) or seen_adj.has(n):
					continue
				if _territory.get_occupant(n, adj_kingdom) != &"":
					seen_adj[n] = true
					adj_count += 1
		if adj_count >= min_adj:
			out.append(m)
	return out


func _match_ring(params: Dictionary) -> Array:
	var radius: int = int(params.get("radius", 1))
	var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
	var out: Array = []
	for cy in range(radius, _tile_grid.GRID_HEIGHT - radius):
		for cx in range(radius, _tile_grid.GRID_WIDTH - radius):
			var center: Vector2i = Vector2i(cx, cy)
			if _territory.get_occupant(center, kingdom_id) != &"":
				continue
			var ring_coords: Array[Vector2i] = []
			var first_species: StringName = &""
			var ok: bool = true
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					if max(abs(dx), abs(dy)) != radius:
						continue
					var c: Vector2i = Vector2i(cx + dx, cy + dy)
					var sp: StringName = _territory.get_occupant(c, kingdom_id)
					if sp == &"":
						ok = false
						break
					if first_species == &"":
						first_species = sp
					elif sp != first_species:
						ok = false
						break
					ring_coords.append(c)
				if not ok:
					break
			if ok:
				out.append({"anchor": center, "tiles": ring_coords})
	return out


func _match_area_on_biome(params: Dictionary) -> Array:
	var w: int = int(params.get("width", 2))
	var h: int = int(params.get("height", 2))
	var kingdom_id: StringName = StringName(params.get("kingdom_id", ""))
	var biome_id: StringName = StringName(params.get("biome_id", ""))
	var require_corpse_adj: bool = bool(params.get("require_adjacent_corpse", false))
	var nutrients: Node = get_node_or_null("../NutrientSystem")
	var corpses: Node = get_node_or_null("../CorpseSystem")
	var out: Array = []
	for y in range(_tile_grid.GRID_HEIGHT - h + 1):
		for x in range(_tile_grid.GRID_WIDTH - w + 1):
			var anchor: Vector2i = Vector2i(x, y)
			var coords: Array[Vector2i] = []
			var first_species: StringName = &""
			var ok: bool = true
			for dy in range(h):
				for dx in range(w):
					var c: Vector2i = Vector2i(x + dx, y + dy)
					var sp: StringName = _territory.get_occupant(c, kingdom_id)
					if sp == &"":
						ok = false
						break
					if first_species == &"":
						first_species = sp
					elif sp != first_species:
						ok = false
						break
					if nutrients != null and nutrients.has_method("get_biome_at"):
						var biome: BiomeData = nutrients.get_biome_at(c)
						if biome == null or biome.id != biome_id:
							ok = false
							break
					coords.append(c)
				if not ok:
					break
			if ok and require_corpse_adj:
				ok = _has_adjacent_corpse(coords, corpses)
			if ok:
				out.append({"anchor": anchor, "tiles": coords})
	return out


func _has_adjacent_corpse(coords: Array[Vector2i], corpses: Node) -> bool:
	if corpses == null or not corpses.has_method("is_corpse_at"):
		return false
	var coord_set: Dictionary = {}
	for c in coords:
		coord_set[c] = true
	for c in coords:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + offset
			if coord_set.has(n):
				continue
			if corpses.is_corpse_at(n):
				return true
	return false


func _bonus_mycorrhizal_hub(entry: Dictionary, apply: bool) -> void:
	var bounds := _bounds_from_tiles(entry["tiles"])
	for y in range(bounds["min_y"] - 1, bounds["max_y"] + 2):
		for x in range(bounds["min_x"] - 1, bounds["max_x"] + 2):
			var c := Vector2i(x, y)
			if not _is_in_bounds(c):
				continue
			_territory.set_tile_data(c, "structure_mycorrhizal_hub", apply)


func _bonus_old_growth_stand(entry: Dictionary, apply: bool) -> void:
	for c in entry["tiles"]:
		_territory.set_tile_data(c, "structure_old_growth", apply)


func _bonus_fern_grove(entry: Dictionary, apply: bool) -> void:
	# Humid microclimate — yield boost on grove tiles only. GrowthSystem
	# reads structure_fern_grove and multiplies biomass per tile.
	for c in entry["tiles"]:
		_territory.set_tile_data(c, "structure_fern_grove", apply)


func _bonus_fairy_ring(entry: Dictionary, apply: bool) -> void:
	var run: Dictionary = GameState.run_save
	run["fairy_ring_active"] = apply
	GameState.run_save = run


func _bonus_decay_pit(entry: Dictionary, apply: bool) -> void:
	for c in entry["tiles"]:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if abs(dx) + abs(dy) > 3:
					continue
				var n: Vector2i = Vector2i(c.x + dx, c.y + dy)
				if not _is_in_bounds(n):
					continue
				_territory.set_tile_data(n, "structure_decay_pit_aura", apply)


func _bounds_from_tiles(tiles: Array[Vector2i]) -> Dictionary:
	var min_x: int = 9999
	var min_y: int = 9999
	var max_x: int = -9999
	var max_y: int = -9999
	for c in tiles:
		min_x = mini(min_x, c.x)
		min_y = mini(min_y, c.y)
		max_x = maxi(max_x, c.x)
		max_y = maxi(max_y, c.y)
	return {"min_x": min_x, "min_y": min_y, "max_x": max_x, "max_y": max_y}


func _is_in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < _tile_grid.GRID_WIDTH and c.y < _tile_grid.GRID_HEIGHT
