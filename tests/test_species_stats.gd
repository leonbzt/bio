extends GutTest


func _make_species(yield_dict: Dictionary, consume_dict: Dictionary, col_cost: float, kingdom: StringName, affinity: Dictionary = {}) -> SpeciesData:
	var s := SpeciesData.new()
	s.id = &"test_species"
	s.tick_yield = yield_dict
	s.consume_input = consume_dict
	s.colonize_cost = {"biomass": col_cost}
	s.kingdom_id = kingdom
	s.biome_affinity = affinity
	return s


func test_derive_production_from_yield_sum() -> void:
	var s := _make_species({"biomass": 2.0, "decay": 0.2}, {}, 5.0, &"plantae")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["production"], clampi(roundi(2.2 * 3.0), 1, 10))


func test_derive_consumption_from_consume_sum() -> void:
	var s := _make_species({}, {"biomass": 1.5}, 8.0, &"animals")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["consumption"], clampi(roundi(1.5 * 3.0), 1, 10))


func test_derive_resistance_from_biome_affinity() -> void:
	var s := _make_species({"biomass": 1.0}, {}, 5.0, &"plantae", {"wetland": 1.2, "forest": 0.5, "desert": 1.0})
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["resistance"], 2 + 2)  # 2 affinities >= 1.0 + base 2


func test_derive_spread_from_colonize_cost() -> void:
	var s := _make_species({"biomass": 1.0}, {}, 4.0, &"plantae")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["spread"], clampi(roundi(20.0 / 4.0), 1, 10))


func test_derive_clamped_to_1_10() -> void:
	var huge := _make_species({"biomass": 100.0}, {}, 0.1, &"plantae")
	var stats: Dictionary = SpeciesStats.derive(huge)
	assert_eq(stats["production"], 10)
	assert_eq(stats["spread"], 10)


func test_kingdom_special_plantae_retention() -> void:
	var s := _make_species({"biomass": 1.0}, {}, 5.0, &"plantae")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["special_name"], "Retention")
	assert_eq(stats["special_value"], clampi(roundi(60.0 / 10.0), 1, 10))


func test_kingdom_special_animals_harvest() -> void:
	var s := _make_species({}, {"biomass": 1.5}, 8.0, &"animals")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["special_name"], "Harvest")
	assert_eq(stats["special_value"], clampi(roundi(1.5 * 4.0), 1, 10))


func test_kingdom_special_fungi_reach() -> void:
	var s := _make_species({"nutrients": 1.5}, {"decay": 1.5}, 6.0, &"fungi")
	var stats: Dictionary = SpeciesStats.derive(s)
	assert_eq(stats["special_name"], "Reach")
	assert_eq(stats["special_value"], 5)


func test_role_color_returns_distinct_colors() -> void:
	var producer := SpeciesStats.role_color(&"producer")
	var harvester := SpeciesStats.role_color(&"harvester")
	var recycler := SpeciesStats.role_color(&"recycler")
	assert_ne(producer, harvester)
	assert_ne(harvester, recycler)
	assert_ne(producer, recycler)


func test_role_label() -> void:
	assert_eq(SpeciesStats.role_label(&"producer"), "Producer")
	assert_eq(SpeciesStats.role_label(&"harvester"), "Harvester")
	assert_eq(SpeciesStats.role_label(&"recycler"), "Recycler")
	assert_eq(SpeciesStats.role_label(&"unknown"), "Unknown")
