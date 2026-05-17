# Brief 08 — Animal kingdom registration + Herbivore niche + species

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — new kingdom, new colonization model.

Read first:
1. `scripts/systems/prestige_system.gd` — kingdom unlock + start_run logic.
2. `scripts/systems/herbivore_manager.gd` — the existing hostile-herbivore mover. Reference only; we are NOT reusing this class (per locked decision: separate stat-block).
3. `scripts/entities/herbivore.gd` — the existing Herbivore scene/script. Reference only.
4. `docs/KINGDOMS.md` § Animals.
5. `data/species/_index.tres`.

## Goal

Introduce the Animals kingdom as a playable option. After this brief:
- Player can buy `unlock_animals` evolution node (already exists from Phase 9 brief 04, gated by `requires_kingdom_played = [&"plantae", &"fungi"]`).
- Buying it adds `&"animals"` to `meta.unlocked_kingdoms`.
- Prestige screen shows an Animals button.
- Choosing it goes to the Animal niche selector: Herbivore (this brief) and Predator (brief 09).
- Animal niche runs let the player place animal organisms on a tile-range basis (not strict adjacency like plants).

Animals are **mobile range-tile occupants** per `KINGDOMS.md`. v1 implementation: animals occupy a 1-tile "home" + a wander-range around it. Concrete simplification for Phase 10: an Animal organism is anchored to one tile (the "home"), and its yield comes from that home tile + a configurable wander radius around it.

## Concrete model

| Field | Value | Notes |
|---|---|---|
| Kingdom id | `&"animals"` | Registered in `kingdom_data.gd` if such a registry exists, otherwise hardcoded alongside `&"plantae"` / `&"fungi"` (mirror the existing pattern) |
| Niche id | `&"herbivore"` | First animal niche |
| Species id | `&"common_grazer"` | Generic herbivore species — the "Pioneer Grass" of animals |
| Placement model | tap an empty surface tile → spawn a Common Grazer organism anchored there | Different from plant adjacency — no neighbor required (the species is mobile) |
| Yield | per tick: 0.4 protein, 0.2 biomass (from grazing) — drawn from cellulose-tagged biomes (grassland) | Cellulose/protein/biomass relationship is the educational hook |
| Yield wander radius | 2 tiles | Yield is computed by summing eligible biome tiles within radius of the home |
| Resource cost | 8 cellulose (per `cost_override`) for placement | Cellulose comes from biomass conversion in v1 |
| Tile variant | `&"animals_herbivore"` | New tile variant for visuals (brief 11 graphics) |

## Outputs

### Create `scripts/data/animal_species_data.gd` (or extend SpeciesData)

Animals share most fields with plants/fungi but have additional behavior. v1 decision: **reuse SpeciesData** for animals. Animal organisms are anchored, not mobile in the moving sense — they just yield from a wander radius. No new class.

If a future phase wants mobile-actually-moving animals (like the hostile herbivore-wave animals), that's a separate class (`AnimalOrganism extends Node2D`, like the existing `Herbivore extends Node2D`). Phase 10's playable animals are static anchor tiles.

### Create `data/species/common_grazer.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"common_grazer"
display_name = "Common Grazer"
kingdom_id = &"animals"
base_traits = Array[Resource]([])
colonize_cost = {"cellulose": 8.0}
tick_yield = {
    "protein": 0.4,
    "biomass": 0.2
}
layer_count = 1
layer_species = Array[Resource]([])
```

### Append to `data/species/_index.tres`

Add `common_grazer` reference.

### Create `data/niches/herbivore.tres`

```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/common_grazer.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"herbivore"
display_name = "Herbivore"
description = "You move. You eat what grows. The line between food and you is short."
kingdom_id = &"animals"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"animal_anchor"
cost_override = {}    # use species' colonize_cost
unlock_node_id = &""    # default for animal kingdom; no separate niche unlock node
tile_variant = &"animals_herbivore"
expects_layered = false
parasitic_targets = []
```

### Append to `data/niches/_index.tres`

Add `herbivore` reference.

### Update `data/evolution_tree/unlock_animals.tres`

Brief 9 phase 9 created this node as a Phase 10 scaffold. Make it actually unlock the kingdom:

```
grants_kingdoms = [&"animals"]
```

(Other fields already set in Phase 9 brief 04.)

### Add `_rule_animal_anchor` to `ColonizationRulesRegistry`

```gdscript
&"animal_anchor":
    return _rule_animal_anchor(coord, kingdom_id, species, niche)


func _rule_animal_anchor(coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
    var territory: Node = _get_territory()
    if territory == null:
        return {"valid": false, "cost": {}, "data": {}}
    # Anchor goes on the surface layer (mobile-but-anchored).
    if territory.get_surface_owner(coord) != &"":
        return {"valid": false, "cost": {}, "data": {}}
    return {"valid": true, "cost": _resolve_cost(species, niche), "data": {}}
```

### Update `GrowthSystem` to handle animals

Currently `_on_tick` only handles plantae + fungi. Add animals:

```gdscript
func _on_tick(_delta_seconds: float) -> void:
    if _all_species.is_empty():
        return
    var kingdom_id: StringName = GameState.current_kingdom_id
    if kingdom_id == &"plantae" or kingdom_id == &"fungi":
        _tick_single_kingdom(kingdom_id)
    elif kingdom_id == &"animals":
        _tick_animals()


func _tick_animals() -> void:
    var species: SpeciesData = _resolve_active_animal_species()
    if species == null:
        return
    var coords: Array[Vector2i] = _territory.get_surface_owned_coords(&"animals")
    _apply_yields(species, coords, &"animals", 1.0)
    # Wander-radius bonus: each animal tile gets +0.1 biomass per biome tile in 2-tile radius
    # that's not itself owned. (Sketchy but conveys "grazing" identity.)
    for coord in coords:
        var bonus: float = 0.0
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                var neighbor: Vector2i = coord + Vector2i(dx, dy)
                if neighbor == coord:
                    continue
                if _territory.get_surface_owner(neighbor) != &"":
                    continue
                var biome: BiomeData = _nutrients.get_biome_at(neighbor)
                if biome != null and biome.id == &"grassland":
                    bonus += 0.1
        if bonus > 0.0:
            ResourceLedger.add(ResourceLedger.BIOMASS, bonus)


func _resolve_active_animal_species() -> SpeciesData:
    # Use the active niche's species_options[0].
    var niche_index := load("res://data/niches/_index.tres")
    if niche_index == null or not (niche_index is NicheIndex):
        return null
    for niche in (niche_index as NicheIndex).niches:
        if niche != null and niche.id == GameState.current_niche_id:
            if niche.species_options.is_empty():
                return null
            return niche.species_options[0]
    return null
```

Note: this generalization (lookup species via current niche) is duplicate logic with `MultiLayerPlacementSystem._resolve_active_species`. Worth deduplicating into a helper on `PrestigeSystem` or a new utility — out of scope for this brief, flag as a follow-up.

### `STARTER_SPECIES_BY_KINGDOM`

The existing dict at the top of `growth_system.gd`:
```gdscript
const STARTER_SPECIES_BY_KINGDOM := {
    &"plantae": &"pioneer_grass",
    &"fungi": &"mycelium_thread"
}
```

Add:
```gdscript
&"animals": &"common_grazer"
```

(This is a fallback path; the niche-based lookup above is the primary route. The const exists because Phase 6 hardcoded starter species. Keep both in sync until that const is retired.)

## Acceptance criteria
- [ ] Buy `unlock_animals` (requires `insectivory` + `cordyceps_mastery` + plantae + fungi played; 20 EP). Animals appears in `meta.unlocked_kingdoms`.
- [ ] Prestige screen shows Animals button.
- [ ] Tap Animals → niche selector shows Herbivore (Predator after brief 09).
- [ ] Choose Herbivore → run starts: `kingdom_id == &"animals"`, `niche_id == &"herbivore"`.
- [ ] Tap an empty grassland tile → Common Grazer animal placed (cost 8 cellulose; spent from current pool).
- [ ] Per-tick yield: 0.4 protein + 0.2 biomass per anchored animal, +bonus biomass from wander-radius grass tiles.
- [ ] Cellulose displayed in HUD (greyed until brief 10 fully implements; sufficient if it doesn't crash).
- [ ] Existing hostile herbivore-wave system still works during plantae runs (regression — separate code path).

## Out of scope
- Predator niche (brief 09).
- Animal organisms actually *moving* (anchored model only in Phase 10).
- Insect agents (deferred to Phase 14).
- Cellulose production hooks (Phase 14 makes cellulose a real resource; for Phase 10 the player starts with 0 cellulose and effectively can't place animals without a dev cheat that grants some — this is the Phase 10 placeholder behavior).
- Animal sprite + visual polish (brief 11).
