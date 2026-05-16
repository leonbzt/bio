# Brief 02 — NicheData schema + ColonizationRulesRegistry + GameState wiring

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — touches GameState contract.

Read first:
1. `docs/NICHES.md` — design.
2. `docs/ARCHITECTURE.md` — `ColonizationRulesRegistry` row in system map.
3. `scripts/autoloads/game_state.gd`.
4. `scripts/autoloads/event_bus.gd`.

## Goal
Lay the architectural foundation for niches. After this brief lands:
- `NicheData` resources can be authored.
- `ColonizationRulesRegistry` autoload knows how to dispatch per-rule logic.
- `GameState.current_niche_id` is populated and emitted.
- No actual niches exist yet (brief 03+).

## Outputs (create)

### `scripts/data/niche_data.gd`
```gdscript
class_name NicheData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var kingdom_id: StringName = &""
@export var species_options: Array[SpeciesData] = []

# Identifies the colonization rule this niche uses.
# Recognized values (registered in ColonizationRulesRegistry):
#   &"adjacent_empty"     — default plant rule: adjacent to owned, empty tile, biomass cost
#   &"fungi_substrate"    — default fungi rule: plant tile or corpse or adjacent fungi
#   &"parasitic_plantae"  — Phase 8: cheap, withers without network support
#   &"mycorrhizal_fungi"  — Phase 8: must be adjacent to plantae OR adjacent to mycorrhizal
@export var colonization_rule: StringName = &""

# Cost override. If empty, falls back to species.colonize_cost.
@export var cost_override: Dictionary = {}

# Which evolution-tree node grants this niche. Empty = default niche (unlocked from start).
@export var unlock_node_id: StringName = &""
```

### `scripts/data/niche_index.gd`
```gdscript
class_name NicheIndex
extends Resource

@export var niches: Array[NicheData] = []
```

### `scripts/systems/colonization_rules_registry.gd` (autoload)
Centralizes the per-rule logic so each niche's `colonization_rule` string maps to one function:

```gdscript
extends Node

# Public API used by PlantColonization / FungiColonization on each tap.
# Returns Dictionary: {"valid": bool, "cost": Dictionary, "data": Dictionary}
# - valid: whether to colonize.
# - cost: spend before colonizing. Empty dict = free.
# - data: extra fields to attach to the tile's data dict (e.g. parasite_decay_ticks).
func evaluate(rule: StringName, coord: Vector2i, kingdom_id: StringName, species: SpeciesData, niche: NicheData) -> Dictionary:
    match rule:
        &"adjacent_empty":   return _rule_adjacent_empty(coord, kingdom_id, species, niche)
        &"fungi_substrate":  return _rule_fungi_substrate(coord, kingdom_id, species, niche)
        &"parasitic_plantae": return _rule_parasitic_plantae(coord, kingdom_id, species, niche)
        &"mycorrhizal_fungi": return _rule_mycorrhizal_fungi(coord, kingdom_id, species, niche)
        _:
            push_warning("ColonizationRulesRegistry: unknown rule %s" % String(rule))
            return {"valid": false, "cost": {}, "data": {}}


# Each rule function returns the same shape. Implementations land in briefs 03–05.
func _rule_adjacent_empty(coord, kingdom_id, species, niche) -> Dictionary: return {"valid": false, "cost": {}, "data": {}}
func _rule_fungi_substrate(coord, kingdom_id, species, niche) -> Dictionary: return {"valid": false, "cost": {}, "data": {}}
func _rule_parasitic_plantae(coord, kingdom_id, species, niche) -> Dictionary: return {"valid": false, "cost": {}, "data": {}}
func _rule_mycorrhizal_fungi(coord, kingdom_id, species, niche) -> Dictionary: return {"valid": false, "cost": {}, "data": {}}


# Helper used by multiple rules. Returns 4-neighbor coords.
func neighbors(coord: Vector2i) -> Array[Vector2i]:
    return [coord + Vector2i.LEFT, coord + Vector2i.RIGHT, coord + Vector2i.UP, coord + Vector2i.DOWN]
```

Register in `project.godot` autoload list, right after `PrestigeSystem`.

### `scripts/autoloads/game_state.gd` additions
```gdscript
var current_niche_id: StringName = &""
```

### `scripts/autoloads/event_bus.gd` additions
```gdscript
signal niche_changed(niche_id: StringName)
```

Document in `ARCHITECTURE.md` under signals.

### `data/niches/` directory + placeholder `_index.tres`
Create the folder. The `_index.tres` starts empty:

```
[gd_resource type="Resource" script_class="NicheIndex" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_index.gd" id="1"]

[resource]
script = ExtResource("1")
niches = Array[Resource]([])
```

Brief 03 populates it.

## Acceptance criteria
- [ ] `NicheData` schema loads in Godot inspector.
- [ ] `ColonizationRulesRegistry` is registered as an autoload, accessible from any script.
- [ ] `GameState.current_niche_id` exists and persists to save (verified by inspecting `run.niche_id` in save.json after a run starts).
- [ ] `niche_changed` signal is declared but no emitters yet — that's fine. Emitters land in brief 06.
- [ ] No gameplay changes yet — all four `_rule_*` methods return `{"valid": false}` stubs.

## Out of scope
- Implementing the rules (briefs 03–05).
- The niche-selection UI (brief 06).
- Any visual changes (brief 07).
