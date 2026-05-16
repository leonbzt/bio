# Brief 03 — Default niches: Photosynthesizer + Decomposer

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/systems/plant_colonization.gd` — current logic.
2. `scripts/systems/fungi_colonization.gd` — current logic.
3. `scripts/systems/colonization_rules_registry.gd` (from brief 02).
4. `data/niches/_index.tres` (empty stub from brief 02).

## Goal
Refactor the existing PlantColonization and FungiColonization to read niche definitions from `NicheData` rather than hardcoded constants. Implement the default-niche rules (`adjacent_empty` and `fungi_substrate`) inside `ColonizationRulesRegistry`. Author the two default niche `.tres` files.

After this brief, the existing gameplay is functionally identical — but driven by niches under the hood. This is the test that the niche layer doesn't regress anything.

## Outputs

### `data/niches/photosynthesizer.tres`
```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/pioneer_grass.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"photosynthesizer"
display_name = "Photosynthesizer"
description = "Convert sunlight into biomass. The basic plantae playstyle."
kingdom_id = &"plantae"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"adjacent_empty"
cost_override = {}
unlock_node_id = &""
```

(Bramble can be added to species_options too if you want it available for this niche.)

### `data/niches/decomposer.tres`
```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/mycelium_thread.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"decomposer"
display_name = "Decomposer"
description = "Feed on the dead. Spread through corpses and networks."
kingdom_id = &"fungi"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"fungi_substrate"
cost_override = {}
unlock_node_id = &""
```

### Update `data/niches/_index.tres`
```
events = Array[Resource]([ExtResource("2"), ExtResource("3")])
```
With the two new ExtResource references to the niche files.

### `ColonizationRulesRegistry` rule implementations

Fill in `_rule_adjacent_empty` and `_rule_fungi_substrate` by **moving the existing logic** from `PlantColonization._on_tile_tapped` and `FungiColonization._on_tile_tapped`.

For `_rule_adjacent_empty`:
```gdscript
func _rule_adjacent_empty(coord, kingdom_id, species, niche) -> Dictionary:
    var territory: Node = _get_territory()
    if territory.get_surface_owner(coord) != &"":
        return {"valid": false, "cost": {}, "data": {}}
    var owned: Array[Vector2i] = territory.get_surface_owned_coords(kingdom_id)
    if owned.size() > 0:
        var owned_set: Dictionary = {}
        for c in owned: owned_set[c] = true
        var has_neighbor: bool = false
        for n in neighbors(coord):
            if owned_set.has(n):
                has_neighbor = true
                break
        if not has_neighbor:
            return {"valid": false, "cost": {}, "data": {}}
    # Cost: niche override or species default; existing thrifty_growth modifier still applies.
    var cost: Dictionary
    if not niche.cost_override.is_empty():
        cost = niche.cost_override.duplicate()
    else:
        cost = species.colonize_cost.duplicate()
    if MetaModifiers.is_unlocked(&"thrifty_growth"):
        for k in cost.keys():
            cost[k] = maxf(0.0, float(cost[k]) - 1.0)
    # Bootstrap (first tile): free.
    if owned.is_empty():
        cost = {}
    return {"valid": true, "cost": cost, "data": {}}


func _get_territory() -> Node:
    return get_tree().root.get_node("World/Systems/TerritorySystem")
```

(Adjust the node path to match your scene tree.)

For `_rule_fungi_substrate`: same shape, mirror existing fungi colonization logic (bootstrap free, then plant tile / corpse / fungi adjacency check; cost from niche.cost_override or species).

### Refactor `PlantColonization._on_tile_tapped`

Replace the body with:
```gdscript
func _on_tile_tapped(coord: Vector2i) -> void:
    if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
        return
    if not _is_active():
        return
    var niche: NicheData = _get_active_niche()
    if niche == null:
        return
    var species: SpeciesData = _get_species_for_niche(niche)
    if species == null:
        return
    var result: Dictionary = ColonizationRulesRegistry.evaluate(
        niche.colonization_rule, coord, KINGDOM_ID, species, niche
    )
    if not result.get("valid", false):
        return
    var cost: Dictionary = result.get("cost", {})
    if not cost.is_empty() and not ResourceLedger.spend_bundle(cost):
        return
    var ok: bool = _territory.add_surface(coord, KINGDOM_ID)
    if ok:
        # Apply per-niche data (e.g. parasite_decay_ticks) to the tile.
        var data_extras: Dictionary = result.get("data", {})
        for key in data_extras.keys():
            _territory.set_tile_data(coord, key, data_extras[key])
        SaveSystem.save_now()
```

`_get_active_niche()` loads `data/niches/_index.tres` and looks up by `GameState.current_niche_id`. Cache the dict in `_ready`.

`_get_species_for_niche(niche)` for now returns `niche.species_options[0]` — Phase 8 doesn't add species-selection UI. Player gets the first listed species for their niche.

`_territory.set_tile_data(coord, key, value)` is a new public method on TerritorySystem — small addition: writes into the tile's `data` dict and syncs to save.

### Refactor `FungiColonization._on_tile_tapped`
Mirror the plant version. Calls `_territory.add_subsurface` instead of `add_surface`.

## Acceptance criteria
- [ ] After this brief, plantae and fungi runs behave **identically to before** (regression check).
- [ ] Inspecting `save.json` mid-run: `run.niche_id` is `"photosynthesizer"` or `"decomposer"` depending on kingdom.
- [ ] Removing one of the niche `.tres` files from disk and relaunching: colonization fails gracefully (push_error in logcat, no crash).
- [ ] `_territory.set_tile_data(coord, key, value)` works and persists to save.

## Out of scope
- Parasite plantae niche (brief 04).
- Mycorrhizal fungi niche (brief 05).
- Niche selection UI (brief 06).
- Multi-species selection within a niche (Phase 9 — for now first listed wins).
