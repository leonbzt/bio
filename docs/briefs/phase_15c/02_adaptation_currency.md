# Brief 02 — Adaptation currency + system

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — formula + accumulation correctness.

Read first:
1. `scripts/autoloads/resource_ledger.gd` — comparable currency API (for reference; Adaptation lives separately).
2. `scripts/systems/territory_system.gd.get_clusters` (Phase 15a brief 03) — cluster size source.
3. `scripts/autoloads/nutrient_system.gd.get_biome_at` — biome enumeration.

## Goal

Adaptation is a per-run currency that accumulates passively while the player plays. Earn rate scales with how *much* ecosystem the player has cultivated:

- **+1 Adaptation per minute per cluster-tile-count >= 5** (clusters of fewer than 5 tiles don't contribute — encourages substantial clusters)
  - Concretely: every tick, add `(total_tiles_in_clusters_of_5plus / 60.0)` Adaptation
- **+0.5 Adaptation per minute per distinct biome present on the map** (rewards exploration)
- **+0.25 Adaptation per minute per active introduced species** (rewards diversity)

All rates tunable. The *shape* — cluster-size-weighted — is locked.

## New autoload

`scripts/autoloads/adaptation_system.gd`:

```gdscript
extends Node
##
## Adaptation — per-run strategic currency. Accumulates passively from
## cluster size, biome diversity, and active species. Spent on per-run
## species evolution levels.
##

signal adaptation_changed(new_amount: float)

const TICKS_PER_MINUTE: float = 60.0    # assumes 1Hz tick (project setting)
# Per-minute rates:
const RATE_PER_CLUSTER_TILE: float = 1.0       # 1 Adaptation/min per tile in 5+ tile clusters
const MIN_CLUSTER_SIZE: int = 5
const RATE_PER_BIOME: float = 0.5
const RATE_PER_SPECIES: float = 0.25


func _ready() -> void:
    EventBus.tick.connect(_on_tick)


func get_amount() -> float:
    return float(GameState.run_save.get("adaptation", 0.0))


func get_per_minute_rate() -> float:
    var per_tick: float = _compute_per_tick_rate()
    return per_tick * TICKS_PER_MINUTE


func can_afford(cost: float) -> bool:
    return get_amount() >= cost


func spend(amount: float) -> bool:
    if not can_afford(amount):
        return false
    _set_amount(get_amount() - amount)
    return true


func _on_tick(_delta: float) -> void:
    var per_tick: float = _compute_per_tick_rate()
    if per_tick <= 0.0:
        return
    _set_amount(get_amount() + per_tick)


func _compute_per_tick_rate() -> float:
    var per_minute: float = 0.0
    per_minute += float(_cluster_tile_count()) * RATE_PER_CLUSTER_TILE
    per_minute += float(_distinct_biomes_present()) * RATE_PER_BIOME
    per_minute += float(_active_species_count()) * RATE_PER_SPECIES
    return per_minute / TICKS_PER_MINUTE


func _cluster_tile_count() -> int:
    var territory: Node = _get_territory()
    if territory == null or not territory.has_method("get_clusters"):
        return 0
    var total: int = 0
    for cluster in territory.get_clusters():
        var size: int = (cluster["coords"] as Array).size()
        if size >= MIN_CLUSTER_SIZE:
            total += size
    return total


func _distinct_biomes_present() -> int:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
    var seen: Dictionary = {}
    for v in biome_map.values():
        seen[String(v)] = true
    return seen.size()


func _active_species_count() -> int:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var unlocked: Array = run.get("unlocked_species_in_run", []) as Array
    return unlocked.size()


func _set_amount(value: float) -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    run["adaptation"] = max(0.0, value)
    GameState.run_save = run
    adaptation_changed.emit(run["adaptation"])


func _get_territory() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/TerritorySystem")
```

Register in `project.godot` as autoload (after EraSystem etc):

```
AdaptationSystem="*res://scripts/autoloads/adaptation_system.gd"
```

## HUD chip

Add a small Adaptation chip in the HUD, sibling of the multiplier chips (or in the same row).

```gdscript
# scripts/ui/adaptation_chip.gd
extends HBoxContainer

@onready var _value_label: Label = $Value
@onready var _rate_label: Label = $Rate


func _ready() -> void:
    add_theme_constant_override("separation", 3)
    AdaptationSystem.adaptation_changed.connect(_on_changed)
    EventBus.tick.connect(_on_tick_refresh)
    _refresh()


func _on_changed(_v: float) -> void:
    _refresh()


func _on_tick_refresh(_delta: float) -> void:
    # Refresh rate every tick (rate can change as clusters form / species introduce).
    _refresh_rate()


func _refresh() -> void:
    _value_label.text = "%s" % FormatUtils.abbreviate(AdaptationSystem.get_amount())
    _refresh_rate()


func _refresh_rate() -> void:
    var per_min: float = AdaptationSystem.get_per_minute_rate()
    _rate_label.text = "+%.1f/min" % per_min
```

Scene (`scenes/ui/adaptation_chip.tscn`):

```
AdaptationChip (HBoxContainer)
  Swatch (ColorRect 8×8, gold #d8c060)
  Value (Label, "0" — default font)
  Rate (Label, "+0.0/min" — small font Tiny5)
```

Place in HUD bar area; sibling of multiplier chips. Mount in `scenes/ui/hud.tscn`.

## Reset on prestige

`AdaptationSystem` doesn't need an explicit reset — `_reset_run_state` (Phase 15c brief 01) zeros `run.adaptation`. The system reads from run_save on next tick.

## Acceptance criteria

- [ ] `AdaptationSystem` registered as autoload.
- [ ] HUD shows Adaptation chip with current amount + per-min rate.
- [ ] Rate visibly increases as cluster size grows past 5 tiles.
- [ ] Rate visibly increases as more biomes are revealed (per Phase 15b fog).
- [ ] Rate visibly increases as more species are introduced.
- [ ] Adaptation pool accumulates over time without intervention.
- [ ] `spend()` decrements correctly; `can_afford()` blocks overspending.
- [ ] Save round-trip preserves the pool.
- [ ] Prestige resets to 0.
- [ ] `adaptation_changed` signal fires on every mutation.

## Out of scope

- Adaptation appearing as a placement cost — reserved for evolution-only in v1.
- Bonus sources for Adaptation (events, structures) — Phase 16+.
- Adaptation cap / overflow handling — pool grows unbounded for v1.
- UI animation on rate change.
