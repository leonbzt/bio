# Architecture (authoritative spec)

> Every agent (Claude, ChatGPT, Kilo) should read this document before making changes. It defines contracts that must not be violated. If a brief contradicts this document, this document wins.

## 1. Locked decisions

| Decision | Value |
|---|---|
| Engine | Godot 4 (latest stable) |
| Language | GDScript only |
| Orientation | Portrait |
| Render resolution | 360×640 base, stretched (`canvas_items`, `keep`) |
| World | Fixed grid, **32 cols × 48 rows** |
| Tick rate | 1 Hz (configurable per-build) |
| Offline progress | Replays at most **8 hours** of ticks on cold start |
| Save format | JSON in `user://save.json`, versioned |
| MVP platforms | Android only |
| Min Android API | 24 (Android 7.0) |

## 2. Architectural principles

1. **Data-driven content.** Species, traits, events, biomes, kingdoms = `Resource` files in `data/`. Code holds behavior, resources hold content.
2. **Autoload singletons for services.** Global services live in `scripts/autoloads/`. They expose state + signals. They contain no gameplay logic.
3. **EventBus for cross-system communication.** Systems do not import each other. They emit and subscribe to signals on `EventBus`. This is the single most important architectural rule.
4. **Tick-driven simulation.** All passive progression is driven by `TickClock.tick(delta)`. `_process` is reserved for UI, animation, input.
5. **Composition over inheritance for organisms.** An organism is a scene + a list of `TraitData` resources. No `ThickBarkPlant` subclass — apply `thick_bark.tres` to a plant scene.
6. **Two save layers.** `RunSave` resets on prestige. `MetaSave` persists evolution-tree unlocks, kingdom unlocks, statistics.

## 3. Autoload contracts

These are committed contracts. Implementations may change; signatures may not without Claude review.

### `EventBus` (singleton, signals only)

```gdscript
# Tick / time
signal tick(delta_seconds: float)
signal paused_changed(is_paused: bool)

# Resources
signal resource_changed(resource_id: StringName, new_amount: float)

# Territory
signal tile_tapped(coord: Vector2i)
signal tile_colonized(coord: Vector2i, owner_id: StringName)
signal tile_lost(coord: Vector2i, prev_owner_id: StringName)

# Organisms
signal organism_spawned(organism_id: int, species_id: StringName, coord: Vector2i)
signal organism_died(organism_id: int, cause: StringName)

# Evolution
signal trait_unlocked(trait_id: StringName)
signal evolution_node_unlocked(node_id: StringName)

# Ecological pressure
signal event_started(event_id: StringName, payload: Dictionary)
signal event_resolved(event_id: StringName, outcome: StringName)

# Input mode and abilities
signal input_mode_changed(mode: StringName)
signal ability_used(ability_id: StringName, payload: Dictionary)
signal placement_target_changed(target: StringName)

# Run lifecycle
signal run_started(kingdom_id: StringName)
signal prestige_triggered(summary: Dictionary)
signal run_loaded(save_version: int)

# Offline progress
signal replay_started(total_ticks: int)
signal replay_finished()
```

### `TickClock`

```gdscript
var is_paused: bool
var tick_hz: float = 1.0      # configurable in project settings

func pause() -> void
func resume() -> void
func force_tick(n: int = 1) -> void   # for debugging / offline replay
```

Emits `EventBus.tick(delta)` and `EventBus.paused_changed`.

### `ResourceLedger`

Holds the live numeric resources for the current run. All resources are `float`.

```gdscript
const BIOMASS    := &"biomass"
const NUTRIENTS  := &"nutrients"
const SUNLIGHT   := &"sunlight"
const DECAY      := &"decay"
const SPORES     := &"spores"
const PRESSURE   := &"population_pressure"

func get_amount(resource_id: StringName) -> float
func add(resource_id: StringName, amount: float) -> void
func spend(resource_id: StringName, amount: float) -> bool   # returns false if insufficient
func can_afford(costs: Dictionary) -> bool                    # {resource_id: amount}
func spend_bundle(costs: Dictionary) -> bool                  # atomic — all or nothing
func reset_run() -> void                                      # zero all known on prestige
```

Emits `EventBus.resource_changed` after every mutation.

**Persistence:** ResourceLedger subscribes to `EventBus.run_loaded` and hydrates `_amounts` from `GameState.run_save["resources"]`. Every mutation writes back into that dict so `SaveSystem.save_now()` captures the current balances without an explicit pre-save hook.

### `GameState`

```gdscript
var current_kingdom_id: StringName     # which kingdom this run plays
var run_seed: int                       # for deterministic events
var is_run_active: bool

# Two save layers — see SaveSystem
var run_save: Dictionary                # serialized RunSave
var meta_save: Dictionary               # serialized MetaSave
```

### `SaveSystem`

```gdscript
const SAVE_VERSION := 1
const SAVE_PATH := "user://save.json"

func save_now() -> void                 # blocking, called on tree_exiting + app pause
func load_or_create() -> void           # called once on boot
func reset_save() -> void               # delete + rebuild default; emits run_loaded
func migrate(old: Dictionary, from_version: int) -> Dictionary
```

Save schema:

```json
{
  "save_version": 1,
  "saved_at_unix": 1747234567,
  "meta": {
    "unlocked_kingdoms": ["plantae"],
    "evolution_tree": {"unlock_fungi": true},
    "statistics": {
      "prestige_count": 1,
      "evolution_points_balance": 12,
      "total_biomass_lifetime": 4583.0
    }
  },
  "run": {
    "kingdom_id": "plantae",
    "run_seed": 12345,
    "tick_count": 4821,
    "resources": {"biomass": 120.0, "sunlight": 8.0},
    "tiles": [{"coord": [12, 30], "surface_owner": "plantae", "subsurface_owner": "", "data": {}}],
    "organisms": [],
    "active_events": [
      {"id": "herbivore_wave", "ticks_remaining": 45, "payload": {"spawn_count": 3}}
    ],
    "statistics": {
      "total_biomass_earned": 1247.5,
      "tiles_colonized": 18,
      "waves_defeated": 2
    }
  }
}
```

Per-array entry shapes:
- **Phase 5+**: `run.tiles[i] = {"coord": [x,y], "surface_owner": String, "subsurface_owner": String, "data": Dictionary}`. Either owner may be `""` (empty). Surface = above ground (plantae). Subsurface = below ground (fungi).
- **Phase 3+**: `run.organisms[i] = {"organism_id": int, "species_id": StringName, "coord": [x,y], "hp": float, "data": Dictionary}`. Phase 5 adds `species_id == "corpse"` as a recognized variant; corpses use `data.decay_remaining_ticks` and `data.decay_per_tick`.
- **Phase 3+**: `run.active_events[i] = {"id": StringName, "ticks_remaining": int, "payload": Dictionary}`

These shapes evolve additively — loaders should tolerate missing optional fields. Required fields above must always be present in any saved entry.

### `AudioManager`

```gdscript
func play_sfx(sfx_id: StringName) -> void
func play_music(track_id: StringName, fade_in: float = 0.5) -> void
func stop_music(fade_out: float = 0.5) -> void
```

## 4. Resource schemas (in `scripts/data/`)

Every content file in `data/` extends one of these.

### `KingdomData`
```gdscript
class_name KingdomData extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var starting_species: Array[SpeciesData]
@export var starting_resources: Dictionary    # {resource_id: float}
@export var unlock_cost: Dictionary           # paid in MetaSave currency on prestige
```

### `SpeciesData`
```gdscript
class_name SpeciesData extends Resource
@export var id: StringName
@export var display_name: String
@export var kingdom_id: StringName
@export var sprite: Texture2D
@export var base_traits: Array[TraitData]
@export var colonize_cost: Dictionary
@export var tick_yield: Dictionary            # resources generated per tick per tile
```

### `TraitData`
```gdscript
class_name TraitData extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var modifiers: Dictionary             # {"defense": +5, "growth_speed": -0.1}
@export var tradeoff_summary: String          # one-line "+X / -Y"
```

### `EventData`
```gdscript
class_name EventData extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var trigger_weight: float
@export var duration_ticks: int
@export var payload: Dictionary               # event-specific (e.g. herbivore count)
```

### `BiomeData`
```gdscript
class_name BiomeData extends Resource
@export var id: StringName
@export var display_name: String
@export var tile_texture: Texture2D
@export var sunlight_per_tick: float
@export var nutrient_per_tick: float
@export var decay_per_tick: float
```

### Content indices (`data/<folder>/_index.tres`)

**Never enumerate `data/` with `DirAccess` at runtime.** Exported Android builds don't reliably enumerate the virtual `res://` filesystem, and unreferenced `.tres` files may be stripped or unfindable.

Instead, every content folder has an `_index.tres` resource holding a typed array of every resource in that folder. Systems load the index; the `ExtResource` references inside the index force the export pipeline to bundle the dependencies.

Schemas live in `scripts/data/`:
- `BiomeIndex` → `Array[BiomeData]`
- `SpeciesIndex` → `Array[SpeciesData]`
- `TraitIndex` → `Array[TraitData]`
- `EventIndex` → `Array[EventData]`
- `EvolutionTreeIndex` → `Array[EvolutionNodeData]`

Adding a new content file means updating the corresponding `_index.tres` in the inspector. Forgetting is a loud editor error (unresolved ExtResource), not a silent runtime miss.

### `EvolutionNodeData`
```gdscript
class_name EvolutionNodeData extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var prerequisites: Array[StringName]  # other node ids
@export var meta_cost: Dictionary
@export var grants_traits: Array[TraitData]
@export var grants_kingdoms: Array[StringName]
```

## 5. System map

Each gameplay system is a single `.gd` script attached to a node under `world.tscn`. They communicate only via EventBus or by reading autoloads.

| System | File | Subscribes to | Emits |
|---|---|---|---|
| `TerritorySystem` | `scripts/systems/territory_system.gd` | `run_loaded` | `tile_colonized`, `tile_lost` (via public mutators called by colonization systems) |
| `PlantColonization` | `scripts/systems/plant_colonization.gd` | `tile_tapped` (when kingdom is plantae, or symbiosis with placement_target=plantae) | — (calls TerritorySystem) |
| `FungiColonization` | `scripts/systems/fungi_colonization.gd` | `tile_tapped` (when kingdom is fungi, or symbiosis with placement_target=fungi) | — (calls TerritorySystem) |
| `CorpseSystem` | `scripts/systems/corpse_system.gd` | `organism_died`, `tick`, `run_loaded` | `organism_spawned` (for corpses), `organism_died` (when corpse fully decays) |
| `TileInputRouter` | `scripts/systems/tile_input_router.gd` | raw input | `tile_tapped` |
| `GrowthSystem` | `scripts/systems/growth_system.gd` | `tick` | `resource_changed` (via Ledger) |
| `NutrientSystem` | `scripts/systems/nutrient_system.gd` | `tick`, `organism_died` | — |
| `EcologicalPressure` | `scripts/systems/ecological_pressure.gd` | `tick` | `event_started`, `event_resolved` |
| `AbilitySystem` | `scripts/systems/ability_system.gd` | `tile_tapped`, HUD button signals | `input_mode_changed`, `ability_used` |
| `HerbivoreManager` | `scripts/systems/herbivore_manager.gd` | `tick`, `event_started`, `event_resolved`, `ability_used` | `organism_spawned`, `organism_died`, `tile_lost` |
| `EvolutionSystem` | `scripts/systems/evolution_system.gd` | input | `trait_unlocked`, `evolution_node_unlocked` |
| `PrestigeSystem` | `scripts/systems/prestige_system.gd` | UI button signals | `prestige_triggered`, `run_started`, `evolution_node_unlocked` |
| `RunStatsTracker` | `scripts/systems/run_stats_tracker.gd` | `resource_changed`, `tile_colonized`, `event_resolved` | — (writes only to `GameState.run_save.statistics`) |
| `OfflineProgress` | `scripts/systems/offline_progress.gd` | `run_loaded` | `replay_started`, `replay_finished`; drives `force_tick(n)` on TickClock |

## 6. Scene composition

```
world.tscn
└── World (Node2D)
    ├── CameraRig (touch pan/pinch)
    ├── TileGrid (TileMap)
    ├── Organisms (Node2D)        # parent for spawned organism scenes
    ├── Systems (Node)             # holds the system scripts above
    │   ├── TerritorySystem
    │   ├── GrowthSystem
    │   ├── NutrientSystem
    │   ├── EcologicalPressure
    │   ├── EvolutionSystem
    │   └── PrestigeSystem
    └── HUDLayer (CanvasLayer)
        └── HUD (Control)
```

## 7. Input model (mobile)

- Tap = primary action (colonize tile, trigger ability button).
- Drag = pan camera.
- Pinch = zoom camera (clamp 0.5×–2.0×).
- Long-press on tile = inspect (popup with tile info).
- No keyboard inputs in gameplay (debug only, hidden behind a build flag).

## 7a. World-scope hydration pattern

**Problem:** `EventBus.run_loaded` is emitted by `SaveSystem.load_or_create()` during `boot.tscn`, before `world.tscn` (and its child systems) exist. Systems that subscribe only via `_ready()` miss the signal.

**Rule:** Any system living inside `world.tscn` that needs to hydrate from `GameState.run_save` must use the catch-up pattern:

```gdscript
func _ready() -> void:
    EventBus.run_loaded.connect(_on_run_loaded)
    # Catch-up: the signal may have fired before this scene loaded.
    if _has_save_state():
        _on_run_loaded(SaveSystem.SAVE_VERSION)
```

The handler must be idempotent — a no-op if state is empty or already applied — because `run_loaded` can also fire later (e.g. from `SaveSystem.reset_save()`).

Autoloads do not need the catch-up because they are connected before `boot.gd` ever calls `load_or_create()`.

## 8. Non-negotiables (for agent reviewers)

When reviewing AI-generated code, reject any change that:
1. Calls a system directly from another system (must go through EventBus).
2. Uses `_process` for simulation logic (must use `tick` signal).
3. Hardcodes content values that belong in a `.tres` resource.
4. Writes to `user://` without going through `SaveSystem`.
5. Adds a new signal without adding it to this document first.
6. Introduces inheritance for organism variants instead of trait composition.

## 9. Save versioning

Increment `SAVE_VERSION` and add a `migrate()` case any time the JSON schema changes. Never ship a schema change without a migration — players will have saves from earlier builds.

**Migrations must cascade.** A v0 save loaded under build vN must pass through every intermediate step (v0→v1, v1→v2, …, v(N-1)→vN). Implement `migrate()` as a sequence of `if from_version < N:` blocks — *not* a `match` statement, because `match` only fires one arm and would silently skip later steps. Each version bump adds exactly one new `if` block to the chain.

---

**Last updated**: Phase 1 setup. Update this doc whenever a contract changes; do not update it speculatively.
