# Brief 07 — 4 starter structures + bonus handlers

**Suggested agent**: Kilo (data) + ChatGPT (handlers). Route diff to **Claude** (balance).

Read first:
1. `docs/briefs/phase_15b/05_structure_detector.md` — schema + pattern types + handler dispatch.

## Goal

Author 4 starter structure data files + implement their bonus handlers in StructureRegistry. Register all 4 in `data/structures/_index.tres`. Add discovery entries.

## Structures

### 1. `data/structures/mycorrhizal_hub.tres`

```
[gd_resource type="Resource" script_class="StructureData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/structure_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"mycorrhizal_hub"
display_name = "Mycorrhizal Hub"
description = "Mycelium dense enough to connect roots across an entire stand. Plants borrow nutrients through the underground."
pattern_type = &"square_NxM_with_adjacent"
pattern_params = {
"width": 3,
"height": 3,
"kingdom_id": "fungi",
"adjacent_kingdom_id": "plantae",
"min_adjacent": 4
}
bonus_handler = &"mycorrhizal_hub"
halo_color = Color(0.75, 0.5, 0.9, 0.55)
```

**Pattern**: 3×3 of fungi tiles with ≥4 plantae neighbors.
**Bonus**: +50% biomass to all plantae tiles within the cluster's bounding box (extended by 1).

### 2. `data/structures/old_growth_stand.tres`

```
[resource]
id = &"old_growth_stand"
display_name = "Old-Growth Stand"
description = "Ancient trees so dense the canopy seals over. Light filters. The herd avoids it."
pattern_type = &"block_NxM_same_species"
pattern_params = {
"width": 4,
"height": 4,
"kingdom_id": "plantae"
}
bonus_handler = &"old_growth_stand"
halo_color = Color(0.4, 0.85, 0.3, 0.55)
```

**Pattern**: 4×4 contiguous same-plantae-species.
**Bonus**: +100% biomass to those 16 tiles; herbivore_wave skips them once per event.

### 3. `data/structures/fairy_ring.tres`

```
[resource]
id = &"fairy_ring"
display_name = "Fairy Ring"
description = "Mycelium grows outward from a central point in a perfect ring. The center stays mysteriously bare."
pattern_type = &"ring_radius_N"
pattern_params = {
"radius": 1,
"kingdom_id": "fungi"
}
bonus_handler = &"fairy_ring"
halo_color = Color(0.5, 0.8, 0.95, 0.55)
```

**Pattern**: 8 fungi tiles arranged in radius-1 ring around an unoccupied center (3×3 area minus the center).
**Bonus**: Unlocks free Sporulate ability for the rest of the run.

### 4. `data/structures/decay_pit.tres`

```
[resource]
id = &"decay_pit"
display_name = "Decay Pit"
description = "Where corpses fall and fungi feast. Nutrients pour back into surrounding soil."
pattern_type = &"area_on_biome"
pattern_params = {
"width": 2,
"height": 2,
"kingdom_id": "fungi",
"biome_id": "rich_soil",
"require_adjacent_corpse": true
}
bonus_handler = &"decay_pit"
halo_color = Color(0.8, 0.5, 0.5, 0.55)
```

**Pattern**: 2×2 fungi tiles on rich_soil biome, with adjacent corpse.
**Bonus**: +30% nutrients to all tiles within 3 steps of any constituent tile.

## `data/structures/_index.tres`

```
[gd_resource type="Resource" script_class="StructureIndex" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/data/structure_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/structures/mycorrhizal_hub.tres" id="2"]
[ext_resource type="Resource" path="res://data/structures/old_growth_stand.tres" id="3"]
[ext_resource type="Resource" path="res://data/structures/fairy_ring.tres" id="4"]
[ext_resource type="Resource" path="res://data/structures/decay_pit.tres" id="5"]

[resource]
script = ExtResource("1")
structures = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4"), ExtResource("5")])
```

## Bonus handler refinements

The placeholder handlers in brief 05 apply bonuses globally. Refine each to be **per-cluster scoped** where it makes sense, using per-structure multiplier source keys.

### Mycorrhizal Hub — local plantae biomass boost

```gdscript
func _bonus_mycorrhizal_hub(entry: Dictionary, apply: bool) -> void:
    var key: String = "run:structure:mycorrhizal_hub:%s" % str(entry["anchor"])
    if apply:
        # Stamp data on the constituent + adjacent tiles so growth_system reads
        # this and applies a per-tile boost (tile_data flag pattern).
        for c in entry["tiles"]:
            _territory.set_tile_data(c, "structure_mycorrhizal_hub", true)
            for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                _territory.set_tile_data(c + offset, "structure_mycorrhizal_hub", true)
    else:
        for c in entry["tiles"]:
            _territory.set_tile_data(c, "structure_mycorrhizal_hub", false)
            for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                _territory.set_tile_data(c + offset, "structure_mycorrhizal_hub", false)
```

Then `GrowthSystem._apply_yields` checks the flag and adds a local multiplier:

```gdscript
# In _apply_yields biomass branch, after per-tile multipliers:
if kingdom_id == &"plantae" and bool(_territory.get_tile_data(coord, "structure_mycorrhizal_hub", false)):
    per_tile *= 1.50
```

### Old-Growth Stand — local plantae 2× + herbivore skip

```gdscript
func _bonus_old_growth_stand(entry: Dictionary, apply: bool) -> void:
    for c in entry["tiles"]:
        _territory.set_tile_data(c, "structure_old_growth", apply)
```

In `GrowthSystem._apply_yields` biomass branch:

```gdscript
if kingdom_id == &"plantae" and bool(_territory.get_tile_data(coord, "structure_old_growth", false)):
    per_tile *= 2.00
```

In `HerbivoreManager` (or wherever herbivore_wave targets are picked), prefer non-flagged tiles:

```gdscript
# When picking herbivore targets, filter out tiles with structure_old_growth.
if bool(_territory.get_tile_data(coord, "structure_old_growth", false)):
    continue   # skip this tile as target
```

(If HerbivoreManager already has filtering, add this as an additional filter; defer the herbivore part if it requires significant refactoring.)

### Fairy Ring — free Sporulate

```gdscript
func _bonus_fairy_ring(entry: Dictionary, apply: bool) -> void:
    var run: Dictionary = GameState.run_save
    run["fairy_ring_active"] = apply
    GameState.run_save = run
    if apply:
        EventBus.ability_unlocked.emit(&"sporulate_free")
```

AbilitySystem checks `fairy_ring_active` flag — if true, Sporulate ability is available for the run regardless of `mass_fruiting` node ownership. (If sporulate hasn't been wired yet from era-gated nodes, this is a hook for later.)

### Decay Pit — local nutrients boost

```gdscript
func _bonus_decay_pit(entry: Dictionary, apply: bool) -> void:
    var coord_set: Dictionary = {}
    for c in entry["tiles"]:
        coord_set[c] = true
    # Stamp flag on all tiles within 3 steps Manhattan of any constituent tile.
    for c in entry["tiles"]:
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                if abs(dx) + abs(dy) > 3:
                    continue
                var n: Vector2i = Vector2i(c.x + dx, c.y + dy)
                if not coord_set.has(n):
                    _territory.set_tile_data(n, "structure_decay_pit_aura", apply)
```

In `GrowthSystem._apply_yields`, in the nutrients branch (or in `NutrientSystem._on_tick` where nutrients accumulate):

```gdscript
if bool(_territory.get_tile_data(coord, "structure_decay_pit_aura", false)):
    nutrient_amount *= 1.30
```

## Discovery entries

Add 4 entries to `data/discovery/`:

### `disc_structure_mycorrhizal_hub.tres`

```
title = "Roots Find Roots"
body = "Underground threads find each other and learn to share. The plants above the threads grow without knowing why.
You watched it form. The hidden side of every forest is older than the visible side."
category = &"structure"
trigger_id = &"mycorrhizal_hub"
```

### `disc_structure_old_growth_stand.tres`

```
title = "The Canopy Closes"
body = "Sixteen trees stand together long enough that they become a single thing: a forest.
What walks through asking to eat them is turned around. The forest has its own answer."
category = &"structure"
trigger_id = &"old_growth_stand"
```

### `disc_structure_fairy_ring.tres`

```
title = "The Hollow Center"
body = "Mycelium grows outward from one point. After enough seasons, a perfect ring remains around an empty middle.
The spores it releases find every corner of your territory now. The geometry was always the answer."
category = &"structure"
trigger_id = &"fairy_ring"
```

### `disc_structure_decay_pit.tres`

```
title = "Where Everything Returns"
body = "Bodies fall here. Fungi eat them. The nutrients move outward through the soil into the next generation.
You learn that decomposition is not an ending. It is the engine that keeps everything else moving."
category = &"structure"
trigger_id = &"decay_pit"
```

Register all 4 in `data/discovery/_index.tres`.

Wire `DiscoveryLog` to listen for `structure_promoted` and unlock the matching entry:

```gdscript
# In discovery_log.gd._enter_tree (or _ready):
EventBus.structure_promoted.connect(_on_structure_promoted)


func _on_structure_promoted(structure_id: StringName, _anchor: Vector2i) -> void:
    var entry := find_entry_for_trigger(&"structure", structure_id)
    if entry != &"":
        unlock(entry)
```

## Balance notes (calibrate in smoke test)

- Mycorrhizal Hub: 9 fungi + ≥4 plantae adjacent → 9 tiles get +50% biomass. Strong reward for committed mycorrhizal play.
- Old-Growth Stand: 16 plantae tiles → +100% biomass each. Very strong; balanced by the placement cost ramp (Phase 15a) — building 16 tiles of one species costs a lot.
- Fairy Ring: 8 fungi + bare center → unlocks a free ability. Big QoL.
- Decay Pit: 4 fungi + corpse → +30% nutrients to ~25 tiles. Steady but smaller per-tile.

Adjust multipliers in smoke test if any feel under/overpowered.

## Acceptance criteria

- [ ] All 4 `data/structures/*.tres` exist + load in inspector.
- [ ] `data/structures/_index.tres` lists all 4.
- [ ] Building a 3×3 mycelium_thread block with ≥4 adjacent pioneer_grass → halo + bonus visible; plantae yields visibly higher.
- [ ] Building a 4×4 pioneer_grass block → halo + 2× biomass per tile; herbivore_wave skips those tiles.
- [ ] Building a hollow-center 3×3 fungi ring → halo + Sporulate ability available.
- [ ] Building a 2×2 mycelium_thread on rich_soil with adjacent corpse → halo + adjacent tiles get +30% nutrients.
- [ ] Breaking any constituent tile reverts the structure (halo + bonuses gone).
- [ ] Discovery entries unlock on first promotion of each structure type.

## Out of scope

- Multiple bonuses from overlapping structures (each tile bonus stacks naively for v1).
- Per-species sprite art for structures.
- Animated halo / particle effects (Phase 16+).
- Structure persistence across prestige (purely per-run).
- Larger structure recipes (5×5+, 3-component recipes) — Phase 16+.
