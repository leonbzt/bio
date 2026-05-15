# Brief 01 — Cleanup known nits

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/systems/corpse_system.gd` — has a dead handler.
2. `scripts/systems/spore_infection_handler.gd` — hardcoded grid bounds.
3. `scripts/entities/tile_grid.gd` — for the grid-size constants.
4. `scripts/ui/hud.gd` — for kingdom-specific resource visibility.

## Goal
Close out three small things flagged in prior audits. None affect gameplay; they remove footguns and improve UX.

## Patches

### 1. Remove the dead `_on_organism_died` handler in CorpseSystem
The corpse-spawn flow goes through a direct call from HerbivoreManager, not through the signal. The empty handler is dead code.

In `corpse_system.gd`, remove:
- The `EventBus.organism_died.connect(_on_organism_died)` line in `_ready`.
- The `func _on_organism_died(...): return` definition.

### 2. Replace hardcoded grid bounds in SporeInfectionHandler
```gdscript
# old
if neighbor.x < 0 or neighbor.y < 0:
    continue
if neighbor.x >= 32 or neighbor.y >= 48:
    continue
```

Replace with:
```gdscript
@onready var _tile_grid: Node = get_node("../../TileGrid")
# ...
if neighbor.x < 0 or neighbor.y < 0:
    continue
if neighbor.x >= int(_tile_grid.GRID_WIDTH) or neighbor.y >= int(_tile_grid.GRID_HEIGHT):
    continue
```

### 3. Hide unused resources per kingdom in HUD
Plantae runs accumulate `decay` from defeated herbivores with no way to spend it; fungi runs show `biomass` at 0 forever; symbiosis shows everything.

Add a kingdom→visible-resources map and re-evaluate when the run changes:

```gdscript
const VISIBLE_RESOURCES_BY_KINGDOM := {
    &"plantae":   [&"biomass", &"nutrients", &"sunlight"],
    &"fungi":     [&"nutrients", &"decay", &"spores"],
    &"symbiosis": [&"biomass", &"nutrients", &"sunlight", &"decay", &"spores"],
    &"":          [&"biomass", &"nutrients", &"sunlight", &"decay", &"spores"],  # no active run
}

func _refresh_resource_visibility() -> void:
    var visible_set: Array = VISIBLE_RESOURCES_BY_KINGDOM.get(GameState.current_kingdom_id,
        VISIBLE_RESOURCES_BY_KINGDOM[&""])
    for resource_id in _labels.keys():
        _labels[resource_id].visible = visible_set.has(resource_id)
```

Connect to `EventBus.run_started` and `EventBus.run_loaded`; call `_refresh_resource_visibility()` from both handlers AND from `_ready` after the labels are bound.

## Acceptance criteria
- [ ] CorpseSystem no longer connects to `organism_died`; the empty handler is gone. CorpseSystem still spawns corpses via the direct call from HerbivoreManager.
- [ ] SporeInfectionHandler references `_tile_grid.GRID_WIDTH/HEIGHT` — changing the grid size in `tile_grid.gd` wouldn't require a code change elsewhere.
- [ ] In plantae runs, only Biomass/Nutrients/Sunlight labels are visible. In fungi runs, only Nutrients/Decay/Spores. In symbiosis runs, all five.

## Out of scope
- Deleting the unused traits (saprophytic_efficiency isn't on any species yet). Leave them — they're cheap to keep.
- Hiding the toxin bloom button in fungi/symbiosis runs (it still works — it's a plantae-flavored ability but mechanically does damage to herbivores either way). Tuning question, defer.
