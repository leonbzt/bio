extends GutTest


func test_purchase_node_blocked_by_kingdoms_played() -> void:
	GameState.meta_save = {
		"evolution_tree": {},
		"kingdoms_played": ["plantae"],
		"statistics": {"evolution_points_balance": 100},
		"unlocked_kingdoms": ["plantae", "fungi"]
	}
	var node := EvolutionNodeData.new()
	node.id = &"_test_gated"
	node.meta_cost = {"evolution_points": 5}
	node.requires_kingdom_played = [&"fungi"]
	PrestigeSystem._nodes_by_id[node.id] = node
	PrestigeSystem._all_nodes.append(node)

	assert_false(PrestigeSystem.purchase_node(&"_test_gated"))
	assert_false(PrestigeSystem.is_node_unlocked(&"_test_gated"))

	GameState.meta_save["kingdoms_played"] = ["plantae", "fungi"]
	assert_true(PrestigeSystem.purchase_node(&"_test_gated"))


func test_trigger_prestige_records_kingdom_played() -> void:
	GameState.run_save = {
		"kingdom_id": "plantae",
		"statistics": {"total_biomass_earned": 100.0}
	}
	GameState.meta_save = {"kingdoms_played": [], "statistics": {}, "evolution_tree": {}}
	PrestigeSystem.trigger_prestige()
	assert_true(GameState.meta_save["kingdoms_played"].has("plantae"))

	GameState.run_save = {"kingdom_id": "plantae", "statistics": {"total_biomass_earned": 50.0}}
	PrestigeSystem.trigger_prestige()
	assert_eq(GameState.meta_save["kingdoms_played"].count("plantae"), 1)


func test_calculate_prestige_reward_with_grade_multiplier() -> void:
	var base: int = PrestigeSystem.calculate_prestige_reward(500.0, false, 1.0)
	var graded: int = PrestigeSystem.calculate_prestige_reward(500.0, false, 2.0)
	assert_eq(graded, base * 2)


func test_calculate_prestige_reward_with_cycle_bonus() -> void:
	var no_cycle: int = PrestigeSystem.calculate_prestige_reward(500.0, false, 1.0)
	var with_cycle: int = PrestigeSystem.calculate_prestige_reward(500.0, true, 1.0)
	assert_gt(with_cycle, no_cycle)


func test_calculate_prestige_reward_zero_biomass() -> void:
	var no_cycle: int = PrestigeSystem.calculate_prestige_reward(0.0, false, 1.0)
	assert_eq(no_cycle, 0)
	var with_cycle: int = PrestigeSystem.calculate_prestige_reward(0.0, true, 1.0)
	assert_eq(with_cycle, 50)


func test_reset_run_state_has_team_and_stat_boosts() -> void:
	GameState.run_save = {"team": ["a", "b"], "species_stat_boosts": {"a": {"production": 1}}}
	PrestigeSystem._reset_run_state()
	var run: Dictionary = GameState.run_save
	assert_true(run.has("team"))
	assert_true(run.has("species_stat_boosts"))
	assert_eq((run["team"] as Array).size(), 0)
	assert_eq((run["species_stat_boosts"] as Dictionary).size(), 0)
