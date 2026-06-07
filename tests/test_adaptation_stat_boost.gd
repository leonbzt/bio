extends GutTest


func before_each() -> void:
	GameState.run_save = {
		"adaptation": 100.0,
		"species_stat_boosts": {},
	}


func test_level_up_stat_stores_boost() -> void:
	AdaptationSystem.level_up_stat(&"test_sp", &"production")
	assert_eq(AdaptationSystem.get_stat_boost(&"test_sp", &"production"), 1)
	assert_eq(AdaptationSystem.get_stat_boost(&"test_sp", &"efficiency"), 0)


func test_level_counts_total_boosts() -> void:
	assert_eq(AdaptationSystem.get_level(&"test_sp"), 1)
	AdaptationSystem.level_up_stat(&"test_sp", &"production")
	assert_eq(AdaptationSystem.get_level(&"test_sp"), 2)
	AdaptationSystem.level_up_stat(&"test_sp", &"resistance")
	assert_eq(AdaptationSystem.get_level(&"test_sp"), 3)


func test_max_level_blocks_further_upgrades() -> void:
	AdaptationSystem.level_up_stat(&"test_sp", &"production")
	AdaptationSystem.level_up_stat(&"test_sp", &"efficiency")
	assert_false(AdaptationSystem.can_level_up(&"test_sp"))
	assert_false(AdaptationSystem.level_up_stat(&"test_sp", &"spread"))


func test_invalid_stat_name_rejected() -> void:
	assert_false(AdaptationSystem.level_up_stat(&"test_sp", &"invalid_stat"))


func test_species_level_multiplier_scales_with_production() -> void:
	assert_almost_eq(AdaptationSystem.species_level_multiplier(&"test_sp"), 1.0, 0.001)
	AdaptationSystem.level_up_stat(&"test_sp", &"production")
	assert_almost_eq(AdaptationSystem.species_level_multiplier(&"test_sp"), 1.1, 0.001)


func test_spend_deducts_adaptation() -> void:
	GameState.run_save["adaptation"] = 20.0
	AdaptationSystem.level_up_stat(&"test_sp", &"production")  # costs 0 (level 1->2)
	assert_almost_eq(AdaptationSystem.get_amount(), 20.0, 0.001)
	AdaptationSystem.level_up_stat(&"test_sp", &"efficiency")  # costs 5 (level 2->3)
	assert_almost_eq(AdaptationSystem.get_amount(), 15.0, 0.001)


func test_insufficient_adaptation_blocks_upgrade() -> void:
	GameState.run_save["adaptation"] = 0.0
	AdaptationSystem.level_up_stat(&"test_sp", &"production")  # costs 0, should succeed
	assert_eq(AdaptationSystem.get_level(&"test_sp"), 2)
	GameState.run_save["adaptation"] = 1.0  # not enough for 5.0 cost
	assert_false(AdaptationSystem.level_up_stat(&"test_sp", &"efficiency"))
