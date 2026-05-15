# Brief 02 — Implement drought + cool_spell event handlers

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `data/events/drought.tres` and `cool_spell.tres` — payload definitions.
2. `scripts/systems/ecological_pressure.gd` — emits `event_started` / `event_resolved`.
3. `scripts/systems/spore_infection_handler.gd` — pattern to mirror (event-scoped handler).
4. `scripts/systems/nutrient_system.gd` — applies per-tick yields based on biome.

## Goal
Phase 3 left these two events as scheduling-only stubs. Phase 7 implements the actual effects so they're not embarrassing in release.

- **Drought**: while active, multiply nutrient yields by the payload's `nutrient_multiplier` (0.5).
- **Cool Spell**: while active, multiply sunlight yields by `sunlight_multiplier` (0.5).

Both events have `kingdom_required = ""` already — they fire for any kingdom. That's fine; symbiosis runs experience them too.

## Approach
Rather than create two separate handler files, add a single `AmbientModifierSystem` that handles all "modify-yield-while-active" events generically. Keeps the per-event surface small.

## Outputs (create)
- `scripts/systems/ambient_modifier_system.gd`
- Modification to `scenes/world/world.tscn` — add node under `Systems`, near `SporeInfectionHandler`.
- Modification to `scripts/systems/nutrient_system.gd` — read multipliers from this system before applying biome yields.

## Implementation

### `ambient_modifier_system.gd`
```gdscript
extends Node

# Maps active event id -> the multipliers it applies.
# Subscribers query get_multiplier(key) to compute their per-tick scaling.
var _active: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
    EventBus.event_started.connect(_on_event_started)
    EventBus.event_resolved.connect(_on_event_resolved)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
    var mods: Dictionary = {}
    if payload.has("nutrient_multiplier"):
        mods["nutrient_multiplier"] = float(payload["nutrient_multiplier"])
    if payload.has("sunlight_multiplier"):
        mods["sunlight_multiplier"] = float(payload["sunlight_multiplier"])
    if mods.is_empty():
        return
    _active[event_id] = mods


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
    _active.erase(event_id)


# Public read for other systems. Returns the product of all active multipliers for the key.
func get_multiplier(key: StringName) -> float:
    var product: float = 1.0
    for mods in _active.values():
        if mods.has(key):
            product *= float(mods[key])
    return product
```

### NutrientSystem patch
Add `@onready var _ambient: Node = get_node("../AmbientModifierSystem")` at the top.

In `_on_tick`:
```gdscript
var sun_mult: float = _ambient.get_multiplier(&"sunlight_multiplier") if _ambient.has_method("get_multiplier") else 1.0
var nut_mult: float = _ambient.get_multiplier(&"nutrient_multiplier") if _ambient.has_method("get_multiplier") else 1.0

# ...
if biome.sunlight_per_tick != 0.0:
    ResourceLedger.add(ResourceLedger.SUNLIGHT, biome.sunlight_per_tick * sun_mult)
if biome.nutrient_per_tick != 0.0:
    ResourceLedger.add(ResourceLedger.NUTRIENTS, biome.nutrient_per_tick * nut_mult)
```

(Apply the same multipliers to decay if you want droughts to also slow decay — biology suggests yes, but the payload doesn't include a decay multiplier. Skip unless desired.)

### GrowthSystem
For consistency, GrowthSystem should also respect `sunlight_multiplier` when computing biomass (since biomass formula already multiplies by `biome.sunlight_per_tick`). One-line change in `_apply_yields`:

```gdscript
if resource_key == &"biomass":
    # ...
    per_tile *= biome.sunlight_per_tick
    per_tile *= _ambient.get_multiplier(&"sunlight_multiplier") if _ambient else 1.0
    # ...
```

You'll need to add `@onready var _ambient` reference. Don't apply nutrient_multiplier here — that's NutrientSystem's job (nutrients are credited separately).

## Acceptance criteria
- [ ] Drought event fires (it's already in scheduling rotation). HUD shows the toast.
- [ ] While drought is active, nutrient HUD value climbs at ~50% of normal rate.
- [ ] After event resolves: full rate restored.
- [ ] Cool Spell: sunlight + biomass yields run at ~50% during the event.
- [ ] Two events active at once (if the scheduler ever does this): multipliers compound (e.g. drought × cool spell = 0.25× nutrient yield not just 0.5×).
- [ ] No effect on the player if neither event is active.

## Out of scope
- Visual indicator on tiles (dimmed overlay during drought). Skip; the HUD toast + visibly slower yields is enough.
- New events. Reuse the existing two stubs.
