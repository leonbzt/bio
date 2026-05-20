# Brief 02 — Per-resource multiplier chains + HUD chips

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — math correctness load-bearing.

Read first:
1. `scripts/autoloads/resource_ledger.gd` — current API.
2. `scripts/systems/growth_system.gd._apply_yields` — yield calculation site.
3. `scripts/ui/hud.gd` + `scenes/ui/hud.tscn` — where multiplier chips render.
4. `scripts/autoloads/kingdom_theme.gd.RESOURCES` — per-resource colors.

## Goal

Introduce a per-resource multiplier registry. Every yield computed by `GrowthSystem` multiplies through `ResourceLedger.get_multiplier(resource_id)`. HUD shows a compact chip per resource displaying the current multiplier; tooltip shows the contributing sources.

This is the **substrate** for all "your power went up" feel. Phase 15a wires the API + display; future phases (15b structures, 15c evolution) add concrete sources.

## API

### `scripts/autoloads/resource_ledger.gd`

```gdscript
# Per-resource multiplier registry.
# Each resource has a Dictionary of {source_key: float_value}.
# Effective multiplier = product of all source values; missing keys default to 1.0.
var _multiplier_sources: Dictionary[StringName, Dictionary] = {}

func set_multiplier_source(resource_id: StringName, source_key: StringName, value: float) -> void:
    if not _multiplier_sources.has(resource_id):
        _multiplier_sources[resource_id] = {}
    _multiplier_sources[resource_id][source_key] = value
    EventBus.resource_multiplier_changed.emit(resource_id, get_multiplier(resource_id))

func clear_multiplier_source(resource_id: StringName, source_key: StringName) -> void:
    if not _multiplier_sources.has(resource_id):
        return
    var d: Dictionary = _multiplier_sources[resource_id]
    d.erase(source_key)
    EventBus.resource_multiplier_changed.emit(resource_id, get_multiplier(resource_id))

func get_multiplier(resource_id: StringName) -> float:
    if not _multiplier_sources.has(resource_id):
        return 1.0
    var product: float = 1.0
    for v in _multiplier_sources[resource_id].values():
        product *= float(v)
    return product

func get_multiplier_breakdown(resource_id: StringName) -> Array:
    var out: Array = []
    if _multiplier_sources.has(resource_id):
        for k in _multiplier_sources[resource_id].keys():
            out.append({"source": String(k), "value": float(_multiplier_sources[resource_id][k])})
    return out

func reset_run() -> void:
    # Existing: zero resources. Add: clear per-run multiplier sources.
    # Sources keyed with prefix "run:" are wiped; "meta:" sources persist.
    for resource_id in _multiplier_sources.keys():
        var d: Dictionary = _multiplier_sources[resource_id]
        for k in d.keys():
            if String(k).begins_with("run:"):
                d.erase(k)
    # ... existing reset logic ...
```

### New `EventBus` signal

```gdscript
signal resource_multiplier_changed(resource_id: StringName, new_multiplier: float)
```

### `GrowthSystem._apply_yields` integration

In the yield application loop, after all existing per-tile multipliers and just before adding to total:

```gdscript
# Phase 15a: apply per-resource multiplier from the registry.
per_tile *= ResourceLedger.get_multiplier(resource_key)
```

Place at the end of the per-tile multiplier chain so trait/biome/symbiosis bonuses stack first, then the global per-resource multiplier multiplies the result.

## HUD chips

Add a horizontal row of multiplier chips below the resource bar (or replace the bar entirely if cleaner). Each chip:

```
[● Biomass  ×2.4]
```

- Small colored swatch in resource color
- Multiplier value as text (×N.N, 1 decimal)
- Tooltip on hover/tap: list of contributing sources

### `scripts/ui/multiplier_chips.gd` (new)

```gdscript
extends HBoxContainer
##
## Compact row of per-resource multiplier chips. Updates live as sources change.
##

const TRACKED_RESOURCES: Array[StringName] = [
    &"biomass", &"spores", &"decay", &"nutrients"
]
var _chips_by_resource: Dictionary[StringName, Control] = {}

func _ready() -> void:
    add_theme_constant_override("separation", 6)
    EventBus.resource_multiplier_changed.connect(_on_multiplier_changed)
    for resource_id in TRACKED_RESOURCES:
        var chip := _build_chip(resource_id)
        _chips_by_resource[resource_id] = chip
        add_child(chip)
    _refresh_all()

func _on_multiplier_changed(resource_id: StringName, _value: float) -> void:
    if _chips_by_resource.has(resource_id):
        _update_chip(resource_id)

func _refresh_all() -> void:
    for resource_id in TRACKED_RESOURCES:
        _update_chip(resource_id)

func _update_chip(resource_id: StringName) -> void:
    var chip: Control = _chips_by_resource[resource_id]
    var value: float = ResourceLedger.get_multiplier(resource_id)
    var label: Label = chip.get_node("Value") as Label
    label.text = "×%.1f" % value
    # Dim if neutral, accentuate if >1.
    label.modulate = Color(1.0, 1.0, 1.0) if value > 1.0 else Color(0.6, 0.6, 0.6)
    chip.tooltip_text = _build_tooltip(resource_id)

func _build_chip(resource_id: StringName) -> Control:
    var chip := HBoxContainer.new()
    chip.add_theme_constant_override("separation", 3)
    chip.mouse_filter = Control.MOUSE_FILTER_STOP
    var swatch := ColorRect.new()
    swatch.custom_minimum_size = Vector2(8, 8)
    swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    swatch.color = KingdomTheme.resource_color(resource_id)
    chip.add_child(swatch)
    var value := Label.new()
    value.name = "Value"
    value.text = "×1.0"
    value.add_theme_font_override("font", KingdomTheme.SMALL_FONT)
    value.add_theme_font_size_override("font_size", KingdomTheme.SMALL_FONT_SIZE)
    chip.add_child(value)
    return chip

func _build_tooltip(resource_id: StringName) -> String:
    var breakdown: Array = ResourceLedger.get_multiplier_breakdown(resource_id)
    if breakdown.is_empty():
        return "%s — no active multipliers" % String(resource_id).capitalize()
    var lines: Array[String] = ["%s multipliers:" % String(resource_id).capitalize()]
    for entry in breakdown:
        lines.append("  %s: ×%.2f" % [entry["source"], entry["value"]])
    return "\n".join(lines)
```

Register the new scene/script and add an instance to the HUD scene. Suggested placement: a row below the existing resource bar, or to the right of the identity strip.

## Source-key naming convention

To make wipe-on-prestige predictable:
- `&"run:<name>"` — cleared on prestige
- `&"meta:<name>"` — persists across runs

Phase 15a doesn't add many sources yet — that's Phase 15b (structures) and 15c (evolution) job. But the namespacing is locked here.

## Acceptance criteria

- [ ] `ResourceLedger.set_multiplier_source / get_multiplier / get_multiplier_breakdown` exist and behave per spec.
- [ ] `EventBus.resource_multiplier_changed` signal fires on source mutations.
- [ ] `GrowthSystem._apply_yields` multiplies in `get_multiplier(resource_key)` per yield.
- [ ] HUD shows multiplier chips for biomass / spores / decay / nutrients.
- [ ] Adding a test source (`ResourceLedger.set_multiplier_source(&"biomass", &"run:test", 2.0)` from console) updates the chip from ×1.0 to ×2.0 immediately.
- [ ] Tooltip lists active sources with their values.
- [ ] `reset_run()` clears `run:*` sources, preserves `meta:*` sources.
- [ ] No yield regression on a fresh run with no sources active (multiplier = 1.0).

## Out of scope

- Actual source values (briefs 03/05 + later phases add concrete sources).
- Animations on chip update (Phase 16+).
- Per-cluster multipliers (later).
- Negative multipliers / debuffs as sources (event modifiers stay separate).
