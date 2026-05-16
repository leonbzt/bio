extends GutTest


func test_migrate_v0_renames_kingdom_field() -> void:
	var v0 := {
		"save_version": 0,
		"saved_at_unix": 123,
		"meta": {
			"unlocked_kingdoms": [],
			"evolution_tree": {},
			"statistics": {}
		},
		"run": {
			"kingdom": "plantae",
			"run_seed": 1,
			"tick_count": 0,
			"resources": {},
			"tiles": [],
			"organisms": [],
			"active_events": []
		}
	}

	var migrated := SaveSystem.migrate(v0, 0)
	assert_true(migrated["run"].has("kingdom_id"))
	assert_false(migrated["run"].has("kingdom"))
	assert_eq(migrated["run"]["kingdom_id"], "plantae")


func test_migrate_v1_adds_biome_map() -> void:
	var v1 := {
		"save_version": 1,
		"saved_at_unix": 123,
		"meta": {
			"unlocked_kingdoms": [],
			"evolution_tree": {},
			"statistics": {}
		},
		"run": {
			"kingdom_id": "plantae",
			"run_seed": 1,
			"tick_count": 0,
			"resources": {},
			"tiles": [],
			"organisms": [],
			"active_events": []
		}
	}

	var migrated := SaveSystem.migrate(v1, 1)
	assert_true(migrated["run"].has("biome_map"))


func test_migrate_v2_adds_prestige_scaffolding() -> void:
	var v2 := {
		"save_version": 2,
		"meta": {
			"unlocked_kingdoms": [],
			"evolution_tree": {},
			"statistics": {}
		},
		"run": {
			"resources": {},
			"biome_map": {},
			"tiles": [],
			"organisms": [],
			"active_events": []
		}
	}

	var migrated := SaveSystem.migrate(v2, 2)
	assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
	assert_eq(migrated["meta"]["statistics"]["evolution_points_balance"], 0)
	assert_true(migrated["run"]["statistics"].has("total_biomass_earned"))


func test_migrate_v3_splits_tile_ownership() -> void:
	var v3 := {
		"save_version": 3,
		"meta": {
			"unlocked_kingdoms": ["plantae"],
			"evolution_tree": {},
			"statistics": {}
		},
		"run": {
			"tiles": [
				{"coord": [5, 7], "owner_id": "plantae", "data": {}},
				{"coord": [6, 7], "owner_id": "plantae", "data": {"trait": "thick"}}
			],
			"resources": {},
			"biome_map": {},
			"organisms": [],
			"active_events": [],
			"statistics": {
				"total_biomass_earned": 0.0,
				"tiles_colonized": 0,
				"waves_defeated": 0
			}
		}
	}

	var migrated := SaveSystem.migrate(v3, 3)
	var tiles: Array = migrated["run"]["tiles"]
	assert_eq(tiles.size(), 2)
	for tile in tiles:
		assert_false(tile.has("owner_id"))
		assert_eq(tile["surface_owner"], "plantae")
		assert_eq(tile["subsurface_owner"], "")
	assert_eq(tiles[1]["data"]["trait"], "thick")


func test_migrate_v0_cascades_to_current() -> void:
	var v0 := {
		"save_version": 0,
		"saved_at_unix": 0,
		"meta": {},
		"run": {
			"kingdom": "plantae"
		}
	}

	var migrated := SaveSystem.migrate(v0, 0)
	assert_true(migrated["run"].has("kingdom_id"))
	assert_false(migrated["run"].has("kingdom"))
	assert_true(migrated["run"].has("biome_map"))
	assert_true(migrated["meta"]["unlocked_kingdoms"].has("plantae"))
	assert_true(migrated["run"].has("statistics"))
	assert_eq(migrated["run"]["niche_id"], "photosynthesizer")


func test_migrate_v4_adds_niche_id() -> void:
	var v4 := {
		"save_version": 4,
		"meta": {"unlocked_kingdoms": ["plantae"], "evolution_tree": {}, "statistics": {}},
		"run": {
			"kingdom_id": "plantae",
			"tiles": [{"coord": [1, 1], "surface_owner": "plantae", "subsurface_owner": "", "data": {}}],
			"resources": {},
			"biome_map": {},
			"organisms": [],
			"active_events": [],
			"statistics": {
				"total_biomass_earned": 0.0,
				"tiles_colonized": 0,
				"waves_defeated": 0
			}
		}
	}

	var migrated := SaveSystem.migrate(v4, 4)
	assert_eq(migrated["run"]["niche_id"], "photosynthesizer")


func test_migrate_v4_fungi_default_niche() -> void:
	var v4_fungi := {
		"save_version": 4,
		"meta": {},
		"run": {"kingdom_id": "fungi"}
	}

	var migrated := SaveSystem.migrate(v4_fungi, 4)
	assert_eq(migrated["run"]["niche_id"], "decomposer")


func test_migrate_v5_adds_discovery_fields() -> void:
	var v5 := {
		"save_version": 5,
		"meta": {"unlocked_kingdoms": ["plantae", "fungi"], "evolution_tree": {}, "statistics": {}},
		"run": {
			"kingdom_id": "plantae",
			"niche_id": "photosynthesizer",
			"tiles": [],
			"resources": {},
			"biome_map": {},
			"organisms": [],
			"active_events": [],
			"statistics": {"total_biomass_earned": 0.0, "tiles_colonized": 0, "waves_defeated": 0}
		}
	}
	var migrated := SaveSystem.migrate(v5, 5)
	assert_true(migrated["meta"].has("discovery_log"))
	assert_true(migrated["meta"].has("kingdoms_played"))
	assert_true(migrated["meta"].has("niches_played"))
	assert_eq(migrated["meta"]["discovery_log"], {})
	assert_eq(migrated["meta"]["kingdoms_played"], [])
	assert_eq(migrated["meta"]["niches_played"], [])
	assert_true(migrated["run"].has("event_first_fires_seen"))
	assert_eq(migrated["run"]["event_first_fires_seen"], [])


func test_migrate_v5_does_not_backfill_kingdoms_played() -> void:
	var v5 := {
		"save_version": 5,
		"meta": {"unlocked_kingdoms": ["plantae", "fungi", "symbiosis"]},
		"run": {}
	}
	var migrated := SaveSystem.migrate(v5, 5)
	assert_eq(migrated["meta"]["kingdoms_played"], [])


func test_migrate_v0_cascades_to_v6() -> void:
	var v0 := {"save_version": 0, "meta": {}, "run": {"kingdom": "plantae"}}
	var migrated := SaveSystem.migrate(v0, 0)
	assert_true(migrated["meta"].has("discovery_log"))
	assert_true(migrated["meta"].has("kingdoms_played"))
	assert_true(migrated["meta"].has("niches_played"))
	assert_true(migrated["run"].has("event_first_fires_seen"))
	assert_eq(migrated["run"]["niche_id"], "photosynthesizer")
