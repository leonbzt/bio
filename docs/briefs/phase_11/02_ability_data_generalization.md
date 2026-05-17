# Brief 02 — AbilityData resource + AbilitySystem generalization

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — refactors a contract.

Read first:
1. `scripts/systems/ability_system.gd` — current Toxin-Bloom-only implementation.
2. `scripts/data/niche_data.gd` + `scripts/data/discovery_entry.gd` for the resource + content-index pattern.
3. `scripts/autoloads/event_bus.gd` — `ability_used` signal already exists.
4. `scripts/systems/ecological_pressure.gd:153` — `is_event_active(id)` already exposed for our predicate.

## Goal
Refactor `AbilitySystem` to be data-driven. Toxin Bloom becomes the first `AbilityData` instance. New abilities slot into the registry without touching `ability_system.gd`. Subsequent briefs (05) add the three event-tied abilities.

## Outputs

### Create `scripts/data/ability_data.gd`

```gdscript
class_name AbilityData
extends Resource
##
## A tap-targeted ability. Instances live in data/abilities/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# StringName -> float. Spent on use via ResourceLedger.
@export var cost: Dictionary = {}

# Evolution-node id that unlocks this ability. Empty = always available.
@export var unlock_node_id: StringName = &""

# If non-empty, ability is only usable while this event is currently active
# (via EcologicalPressure.is_event_active).
@export var requires_event_active: StringName = &""

# Target mode for the input router. Recognized values:
#   &"target_tile" — player taps a tile to invoke
#   &"self"        — invoked immediately on button press (no tap needed)
@export var target_mode: StringName = &"target_tile"

# Effect radius in tiles (used for AOE abilities like Toxin Bloom and Irrigate).
@export var radius: int = 0

# Effect magnitude. Domain-specific:
#   Toxin Bloom: damage per herbivore
#   Irrigate: nutrient restoration per tile
#   Bundle: warmth bonus per tile
#   Cull: spore-clear damage
@export var magnitude: float = 0.0

# Free-form extra payload merged into the EventBus.ability_used emission.
@export var extra_payload: Dictionary = {}
```

### Create `scripts/data/ability_index.gd`

```gdscript
class_name AbilityIndex
extends Resource

@export var abilities: Array[AbilityData] = []
```

### Create `data/abilities/toxin_bloom.tres`

```
[gd_resource type="Resource" script_class="AbilityData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/ability_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"toxin_bloom"
display_name = "Toxin Bloom"
description = "Release defensive toxins in a 3-tile radius. Damages herbivores caught inside."
cost = {
"biomass": 50.0
}
unlock_node_id = &""
requires_event_active = &""
target_mode = &"target_tile"
radius = 3
magnitude = 3.0
extra_payload = {}
```

(Magnitude 3.0 matches `TOXIN_BLOOM_DAMAGE` in the old code; `toxin_potency` bumps it via the same lookup pattern brief 03 establishes.)

### Create `data/abilities/_index.tres`

```
[gd_resource type="Resource" script_class="AbilityIndex" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/ability_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/abilities/toxin_bloom.tres" id="2"]

[resource]
script = ExtResource("1")
abilities = Array[Resource]([ExtResource("2")])
```

(Brief 05 appends the three new abilities.)

### Refactor `scripts/systems/ability_system.gd`

```gdscript
extends Node

const ABILITY_INDEX_PATH: String = "res://data/abilities/_index.tres"

var _abilities_by_id: Dictionary[StringName, AbilityData] = {}
var _pending_ability_id: StringName = &""

@onready var _pressure: Node = get_node("../EcologicalPressure")


func _ready() -> void:
    _load_abilities()
    EventBus.tile_tapped.connect(_on_tile_tapped)


func _load_abilities() -> void:
    _abilities_by_id.clear()
    var index := load(ABILITY_INDEX_PATH)
    if index == null or not (index is AbilityIndex):
        push_error("AbilitySystem: missing ability index at %s" % ABILITY_INDEX_PATH)
        return
    for ability in (index as AbilityIndex).abilities:
        if ability == null:
            continue
        _abilities_by_id[ability.id] = ability


# Public API ---------------------------------------------------------------

func get_all_abilities() -> Array[AbilityData]:
    return _abilities_by_id.values()


func get_usable_abilities() -> Array[AbilityData]:
    var result: Array[AbilityData] = []
    for ability in _abilities_by_id.values():
        if _is_ability_usable(ability):
            result.append(ability)
    return result


func is_ability_usable(id: StringName) -> bool:
    if not _abilities_by_id.has(id):
        return false
    return _is_ability_usable(_abilities_by_id[id])


func get_ability_cost(id: StringName) -> Dictionary:
    if not _abilities_by_id.has(id):
        return {}
    return _abilities_by_id[id].cost


# Request an ability. Returns true if entered target mode; false if rejected.
# For target_mode == &"self", invokes immediately and returns true on success.
func request_ability(id: StringName) -> bool:
    if not _abilities_by_id.has(id):
        return false
    var ability: AbilityData = _abilities_by_id[id]
    if not _is_ability_usable(ability):
        return false
    if _pending_ability_id == id:
        cancel_pending()
        return false
    if ability.target_mode == &"self":
        return _invoke_self(ability)
    _set_mode(GameState.INPUT_MODE_TARGET, id)
    _pending_ability_id = id
    return true


func cancel_pending() -> void:
    _set_mode(GameState.INPUT_MODE_COLONIZE, &"")
    _pending_ability_id = &""


# Backwards-compatible shim for code that still calls request_toxin_bloom.
# Remove in a follow-up cleanup once HUD wires to request_ability.
func request_toxin_bloom() -> bool:
    return request_ability(&"toxin_bloom")


func get_toxin_bloom_cost() -> Dictionary:
    return get_ability_cost(&"toxin_bloom")


# Internals ---------------------------------------------------------------

func _is_ability_usable(ability: AbilityData) -> bool:
    if ability.unlock_node_id != &"" and not MetaModifiers.is_unlocked(ability.unlock_node_id):
        return false
    if ability.requires_event_active != &"":
        if not _pressure.is_event_active(ability.requires_event_active):
            return false
    if not ResourceLedger.can_afford(ability.cost):
        return false
    return true


func _on_tile_tapped(coord: Vector2i) -> void:
    if _pending_ability_id == &"":
        return
    if not _abilities_by_id.has(_pending_ability_id):
        cancel_pending()
        return
    var ability: AbilityData = _abilities_by_id[_pending_ability_id]
    if not _is_coord_in_bounds(coord):
        cancel_pending()
        return
    if not ResourceLedger.spend_bundle(ability.cost):
        cancel_pending()
        return
    var payload: Dictionary = {
        "coord": coord,
        "radius_tiles": ability.radius,
        "magnitude": ability.magnitude,
    }
    # Backwards-compat key for toxin_bloom listeners that read "damage".
    if ability.id == &"toxin_bloom":
        payload["damage"] = _get_toxin_damage(ability)
    for k in ability.extra_payload.keys():
        payload[k] = ability.extra_payload[k]
    EventBus.ability_used.emit(ability.id, payload)
    cancel_pending()


func _invoke_self(ability: AbilityData) -> bool:
    if not ResourceLedger.spend_bundle(ability.cost):
        return false
    var payload: Dictionary = {
        "magnitude": ability.magnitude,
    }
    for k in ability.extra_payload.keys():
        payload[k] = ability.extra_payload[k]
    EventBus.ability_used.emit(ability.id, payload)
    return true


func _set_mode(mode: StringName, ability_id: StringName) -> void:
    if GameState.input_mode == mode and _pending_ability_id == ability_id:
        return
    GameState.input_mode = mode
    EventBus.input_mode_changed.emit(mode)


func _is_coord_in_bounds(coord: Vector2i) -> bool:
    return coord.x >= 0 and coord.x < 32 and coord.y >= 0 and coord.y < 48


# Special-case for the existing toxin_potency upgrade.
# A future polish brief may add a general "ability_potency_overrides" mechanism; until
# then, this stays a localized special-case to keep the refactor scope tight.
func _get_toxin_damage(ability: AbilityData) -> float:
    if MetaModifiers.is_unlocked(&"toxin_potency"):
        return 5.0
    return ability.magnitude
```

### `GameState` additions

Add a new input mode constant if absent:
```gdscript
const INPUT_MODE_TARGET: StringName = &"target_ability"
```

(If `INPUT_MODE_COLONIZE` doesn't already exist as a constant — the old code uses `GameState.INPUT_MODE_COLONIZE` — confirm it does. If only `target_toxin_bloom` was previously used, generalize.)

### `HerbivoreManager._on_ability_used` compatibility

Already listens for `ability_id == &"toxin_bloom"` and reads `payload.damage`. The refactor preserves this via the `"damage"` key copy in `_on_tile_tapped`. **No change needed in herbivore_manager.gd** — verify by smoke-testing toxin bloom kills herbivores post-refactor.

## ARCHITECTURE.md updates

- §4 schema — add `AbilityData`.
- §5 system map — extend `AbilitySystem` row to reflect new public API.

## Acceptance criteria
- [ ] `AbilityData` + `AbilityIndex` loadable in inspector.
- [ ] `data/abilities/toxin_bloom.tres` exists; `data/abilities/_index.tres` references it.
- [ ] `AbilitySystem._load_abilities()` succeeds on cold load (no errors).
- [ ] `AbilitySystem.get_usable_abilities()` returns `[toxin_bloom]` during plantae run (cost permitting).
- [ ] HUD Toxin Bloom button still works identically to before the refactor (regression).
- [ ] Toxin Bloom still kills herbivores via the existing HerbivoreManager listener.
- [ ] `toxin_potency` upgrade still bumps damage from 3 → 5.
- [ ] Pressing Toxin Bloom button twice cancels target mode (existing UX behavior).

## Out of scope
- The 3 new event-tied abilities (brief 03).
- HUD ability bar that lists multiple abilities (brief 03 wires it).
- Generalizing `toxin_potency` into a per-ability potency dict (defer to a polish pass; the special-case in `_get_toxin_damage` is acceptable for now).
- Cooldown system for abilities (not in scope; cost gate is enough).
