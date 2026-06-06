class_name SpeciesStats
extends RefCounted

const SOIL_GRACE_TICKS: int = 60

static func derive(species: SpeciesData) -> Dictionary:
	var yield_sum: float = 0.0
	for v in species.tick_yield.values():
		yield_sum += float(v)

	var consume_sum: float = 0.0
	for v in species.consume_input.values():
		consume_sum += float(v)

	var affinity_count: int = 0
	for v in species.biome_affinity.values():
		if float(v) >= 1.0:
			affinity_count += 1

	var col_cost: float = float(species.colonize_cost.get("biomass", 1.0))

	var production: int = clampi(roundi(yield_sum * 3.0), 1, 10)
	var consumption: int = clampi(roundi(consume_sum * 3.0), 1, 10)
	var resistance: int = clampi(affinity_count + 2, 1, 10)
	var spread: int = clampi(roundi(20.0 / maxf(col_cost, 1.0)), 1, 10)

	var special_name: String = ""
	var special_value: int = 5
	match species.kingdom_id:
		&"plantae":
			special_name = "Retention"
			special_value = clampi(roundi(float(SOIL_GRACE_TICKS) / 10.0), 1, 10)
		&"animals":
			special_name = "Harvest"
			var biomass_consume: float = float(species.consume_input.get("biomass", 0.0))
			special_value = clampi(roundi(biomass_consume * 4.0), 1, 10)
		&"fungi":
			special_name = "Reach"
			special_value = 5

	return {
		"production": production,
		"consumption": consumption,
		"resistance": resistance,
		"spread": spread,
		"special_name": special_name,
		"special_value": special_value,
	}


static func role_color(role: StringName) -> Color:
	match role:
		&"producer":
			return Color(0.45, 0.85, 0.45)
		&"harvester":
			return Color(0.9, 0.7, 0.3)
		&"recycler":
			return Color(0.5, 0.7, 0.95)
	return Color(0.7, 0.7, 0.7)


static func role_label(role: StringName) -> String:
	match role:
		&"producer":
			return "Producer"
		&"harvester":
			return "Harvester"
		&"recycler":
			return "Recycler"
	return "Unknown"


static func stat_summary(species: SpeciesData) -> String:
	var s: Dictionary = derive(species)
	var line: String = "Prod:%d  Cons:%d  Res:%d  Spr:%d" % [
		s["production"], s["consumption"], s["resistance"], s["spread"]
	]
	if s["special_name"] != "":
		line += "\n%s:%d" % [s["special_name"], s["special_value"]]
	return line
