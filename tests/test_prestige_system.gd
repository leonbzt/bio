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
