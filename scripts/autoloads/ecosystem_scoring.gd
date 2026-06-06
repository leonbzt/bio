extends Node
##
## EcosystemScoring — composite score from throughput, diversity, sustainability.
## Drives run-end grade (S/A/B/C/D) and prestige reward multiplier.
##

const THROUGHPUT_WEIGHT: float = 0.4
const DIVERSITY_WEIGHT: float = 0.3
const SUSTAINABILITY_WEIGHT: float = 0.3
const THROUGHPUT_PERFECT: float = 10.0
const RATE_WINDOW: int = 30

const GRADE_THRESHOLDS: Dictionary = {
	"S": 90.0,
	"A": 75.0,
	"B": 60.0,
	"C": 40.0,
}
const GRADE_MULTIPLIERS: Dictionary = {
	"S": 2.0,
	"A": 1.5,
	"B": 1.0,
	"C": 0.75,
	"D": 0.5,
}

var _rate_history: Array[float] = []
var _last_biomass: float = 0.0
var _cached_grade: String = "D"
var _cached_score: float = 0.0
var _cached_breakdown: Dictionary = {}
var _era_species_count: int = 7


func _ready() -> void:
	_cache_era_species_count()
	EventBus.tick.connect(_on_tick)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_loaded.connect(_on_run_loaded)


func get_grade() -> String:
	return _cached_grade


func get_score() -> float:
	return _cached_score


func get_breakdown() -> Dictionary:
	return _cached_breakdown


func get_grade_multiplier() -> float:
	return float(GRADE_MULTIPLIERS.get(_cached_grade, 0.5))


func _on_run_started(_kingdom_id: StringName) -> void:
	_rate_history.clear()
	_last_biomass = GameState.get_hero_biomass()
	_cached_grade = "D"
	_cached_score = 0.0
	_cached_breakdown = {}
	_cache_era_species_count()


func _on_run_loaded(_save_version: int) -> void:
	_rate_history.clear()
	_last_biomass = GameState.get_hero_biomass()


func _on_tick(_delta: float) -> void:
	var current: float = GameState.get_hero_biomass()
	var delta_biomass: float = current - _last_biomass
	_last_biomass = current
	_rate_history.push_back(delta_biomass)
	if _rate_history.size() > RATE_WINDOW:
		_rate_history.pop_front()

	var throughput_norm: float = _compute_throughput()
	var diversity: float = _compute_diversity()
	var sustainability: float = _compute_sustainability()

	_cached_score = (throughput_norm * THROUGHPUT_WEIGHT + diversity * DIVERSITY_WEIGHT + sustainability * SUSTAINABILITY_WEIGHT) * 100.0
	_cached_breakdown = {
		"throughput": throughput_norm,
		"diversity": diversity,
		"sustainability": sustainability,
	}
	_cached_grade = _score_to_grade(_cached_score)


func _compute_throughput() -> float:
	if _rate_history.is_empty():
		return 0.0
	var total: float = 0.0
	for d in _rate_history:
		total += d
	var avg_per_tick: float = total / float(_rate_history.size())
	var per_sec: float = avg_per_tick * TickClock.tick_hz
	return minf(1.0, per_sec / THROUGHPUT_PERFECT)


func _compute_diversity() -> float:
	var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
	var placed: int = in_run.size()
	var total_available: int = _era_species_count
	if total_available <= 0:
		return 0.0
	return minf(1.0, float(placed) / float(total_available))


func _compute_sustainability() -> float:
	var growth: Node = _get_growth_system()
	var territory: Node = _get_territory_system()
	if growth == null or territory == null:
		return 0.0
	var coords: Array = territory.get_all_owned_coords()
	if coords.is_empty():
		return 0.0
	var total_sat: float = 0.0
	for coord in coords:
		total_sat += float(growth.get_tile_input_satisfaction(coord))
	return total_sat / float(coords.size())


func _cache_era_species_count() -> void:
	var index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
	if index == null:
		_era_species_count = 7
		return
	var era_id: StringName = StringName(GameState.run_save.get("era_id", "carboniferous"))
	if era_id == &"":
		era_id = &"carboniferous"
	var count: int = 0
	for species in index.species:
		if species == null:
			continue
		if species.era_requires == era_id or species.era_requires == &"":
			count += 1
	_era_species_count = maxi(count, 1)


func _score_to_grade(score: float) -> String:
	if score >= GRADE_THRESHOLDS["S"]:
		return "S"
	elif score >= GRADE_THRESHOLDS["A"]:
		return "A"
	elif score >= GRADE_THRESHOLDS["B"]:
		return "B"
	elif score >= GRADE_THRESHOLDS["C"]:
		return "C"
	return "D"


func _get_growth_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/GrowthSystem")


func _get_territory_system() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null("World/Systems/TerritorySystem")
