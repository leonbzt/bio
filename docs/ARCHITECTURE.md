# Architecture (authoritative spec)

> Every agent (Claude, ChatGPT, Kilo) should read this document before making changes. It defines contracts that must not be violated. If another doc contradicts this document, this document wins.

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

1. **Data-driven content.** Species, events, biomes, kingdoms = `Resource` files in `data/`. Code holds behavior, resources hold content.
2. **Autoload singletons for services.** Global services live in `scripts/autoloads/`. They expose state + signals. They contain no gameplay logic.
3. **EventBus for cross-system communication.** Systems do not import each other. They emit and subscribe to signals on `EventBus`. This is the single most important architectural rule.
4. **Tick-driven simulation.** All passive progression is driven by `TickClock.tick(delta)`. `_process` is reserved for UI, animation, input.
5. **Two save layers.** `run_save` resets on prestige. `meta_save` persists evolution-tree unlocks, kingdom unlocks, statistics.
6. **Local resource flow.** No global resource pools. Resources flow between adjacent tiles via per-tile output buffers (cap 50). See `V1_PROTOTYPE.md` § 2.

## 3. Autoload contracts

### `EventBus` (singleton, signals only)

```gdscript
# Tick / time
signal tick(delta_seconds: float)
signal paused_changed(is_paused: bool)

# Territory
signal tile_tapped(coord: Vector2i)
signal tile_colonized(coord: Vector2i, owner_id: StringName)
signal tile_lost(coord: Vector2i, prev_owner_id: StringName)
signal tile_harvested(coord: Vector2i, amounts: Dictionary)
signal animal_harvested(coord: Vector2i, amount: float)
signal harvest_combo(level: int)

# Structures
signal structure_promoted(structure_id: StringName, anchor: Vector2i)

# Evolution
signal evolution_node_unlocked(node_id: StringName)
signal discovery_unlocked(entry_id: StringName)
signal species_leveled(species_id: StringName, new_level: int)

# Events
signal event_started(event_id: StringName, payload: Dictionary)
signal event_resolved(event_id: StringName, outcome: StringName)

# Placement
signal placement_target_changed(target_species_id: StringName)
signal species_introduced(species_id: StringName)

# Run lifecycle
signal run_started(kingdom_id: StringName)
signal prestige_triggered(summary: Dictionary)
signal run_loaded(save_version: int)
signal goal_progress_changed(progress: Dictionary)
signal goal_met()
signal checkpoint_triggered(id: StringName, payload: Dictionary)
signal cycle_closed()

# Era
signal era_transition_started(from_era: StringName, to_era: StringName)
signal ecosystem_completed(ecosystem_id: StringName)
signal era_changed(era_id: StringName)

# Offline progress
signal replay_started(total_ticks: int)
signal replay_finished()
signal offline_summary(biomass_gained: float)
```

### `TickClock`

```gdscript
var is_paused: bool
var tick_hz: float = 1.0

func pause() -> void
func resume() -> void
func force_tick(n: int = 1) -> void
```

Emits `EventBus.tick(delta)` and `EventBus.paused_changed`.

### `GameState`

```gdscript
var current_kingdom_id: StringName
var run_seed: int
var is_run_active: bool
var placement_target_species_id: StringName
var run_save: Dictionary
var meta_save: Dictionary

func get_hero_biomass() -> float
func can_afford_hero_biomass(amount: float) -> bool
func spend_hero_biomass(amount: float) -> bool
```

### `SaveSystem`

```gdscript
const SAVE_VERSION := 20
const SAVE_PATH := "user://save.json"

func save_now() -> void
func load_or_create() -> void
func reset_save() -> void
func migrate(old: Dictionary, from_version: int) -> Dictionary
```

### `AudioManager`

```gdscript
func play_sfx(sfx_id: StringName) -> void
func play_music(track_id: StringName, fade_in: float = 0.5) -> void
func stop_music(fade_out: float = 0.5) -> void
```

### `RunGoalSystem`

Throughput-based run goal: sustain +5.0 biomass/s for 30 consecutive ticks after cycle closure.

```gdscript
func get_progress() -> float          # sustained_ticks / target
func get_sustained_ticks() -> int
func get_current_rate() -> float      # rolling avg biomass/s
func is_met() -> bool
```

### `EcosystemScoring`

Composite score from throughput (40%), diversity (30%), sustainability (30%). Drives grade (S/A/B/C/D) and prestige reward multiplier.

```gdscript
func get_grade() -> String
func get_score() -> float
func get_breakdown() -> Dictionary
func get_grade_multiplier() -> float   # S=2.0, A=1.5, B=1.0, C=0.75, D=0.5
```

### `AdaptationSystem`

In-run stat-choice leveling. Each level-up picks one of: production, efficiency, resistance, spread.

```gdscript
func level_up_stat(species_id: StringName, stat_name: StringName) -> void
func get_stat_boost(species_id: StringName, stat_name: StringName) -> int
func get_level(species_id: StringName) -> int
func species_level_multiplier(species_id: StringName) -> float
func can_level_up(species_id: StringName) -> bool
func get_level_cost(species_id: StringName) -> float
```

### `CheckpointSystem`

Onboarding nudges. Fires `checkpoint_triggered` as the player places each role.

```gdscript
# Checkpoint order:
# place_hero → place_recycler → place_harvester → bottleneck_nutrients → bottleneck_detritus → run_complete
```

### `EraSystem`, `DiscoveryLog`, `KingdomTheme`, `ColonizationRulesRegistry`

See source files for API. These are autoloads registered in `project.godot`.

## 4. Resource schemas (in `scripts/data/`)

### `SpeciesData`
```gdscript
class_name SpeciesData extends Resource
@export var id: StringName
@export var display_name: String
@export var latin_name: String
@export var kingdom_id: StringName
@export var role: StringName              # &"producer", &"harvester", &"recycler"
@export var sprite: Texture2D
@export var base_traits: Array[TraitData]
@export var tick_yield: Dictionary         # {resource_id: float per tick}
@export var consume_input: Dictionary      # {resource_id: float per tick}
@export var introduce_cost: Dictionary     # one-shot per-run cost
@export var colonize_cost: Dictionary      # per-tile placement cost
@export var placement_rule: StringName     # adjacent_empty|fungi_substrate|recipe|...
@export var placement_targets: Array[StringName]
@export var tags: Array[StringName]
@export var tick_effects: Array[StringName]
@export var unlock_ep_cost: int
@export var unlock_prerequisites: Array[StringName]
@export var era_requires: StringName
@export var recipe_components: Array[StringName]
@export var tile_marker_color: Color
@export var tile_marker_shape: StringName
@export var biome_affinity: Dictionary
@export var tile_sprite_paths: Array[String]
```

### `EvolutionNodeData`, `BiomeData`, `TraitData`, `EventData`, `DiscoveryEntry`, `EraData`, `EcosystemData`, `StructureData`

See source files in `scripts/data/` for schemas.

### Content indices (`data/<folder>/_index.tres`)

**Never enumerate `data/` with `DirAccess` at runtime.** Exported Android builds don't reliably enumerate the virtual `res://` filesystem.

Every content folder has an `_index.tres` resource holding a typed array. Systems load the index; the `ExtResource` references force the export pipeline to bundle dependencies.

## 5. System map

Systems live under `World/Systems` in `world.tscn`. They communicate only via EventBus or by reading autoloads.

| System | File | Role |
|---|---|---|
| `TerritorySystem` | `scripts/systems/territory_system.gd` | Tile ownership, occupants, species coords |
| `GrowthSystem` | `scripts/systems/growth_system.gd` | Per-tile production, local flow, buffer management |
| `NutrientSystem` | `scripts/systems/nutrient_system.gd` | Soil depletion, symbiotic nutrient transfer |
| `TileInputRouter` | `scripts/systems/tile_input_router.gd` | Tap → colonize or harvest; combo tracking |
| `ObstacleSystem` | `scripts/systems/obstacle_system.gd` | Rock obstacles on grid |
| `FogSystem` | `scripts/systems/fog_system.gd` | Fog of war reveal |
| `StructureRegistry` | `scripts/systems/structure_registry.gd` | Spatial pattern detection, structure halos |
| `OfflineProgress` | `scripts/systems/offline_progress.gd` | Replays missed ticks on cold start |
| `PrestigeSystem` | `scripts/systems/prestige_system.gd` | Run end, evolution points, team run start |

## 6. Scene composition

```
world.tscn
└── World (Node2D)
    ├── EraBackgroundTint (ColorRect)
    ├── CameraRig (touch pan/pinch)
    ├── TileGrid (TileMap)
    ├── Organisms (Node2D)
    ├── Systems (Node)
    │   ├── TileInputRouter
    │   ├── TerritorySystem
    │   ├── ObstacleSystem
    │   ├── FogSystem
    │   ├── NutrientSystem
    │   ├── GrowthSystem
    │   ├── StructureRegistry
    │   ├── OfflineProgress
    │   └── PrestigeSystem (group: "prestige_system")
    └── HUDLayer (CanvasLayer)
        ├── PauseMenu
        └── HUD
```

## 7. Input model (mobile)

- Tap = primary action (colonize tile or harvest buffer).
- Drag = pan camera.
- Pinch = zoom camera (clamp 0.5×–2.0×).
- No keyboard inputs in gameplay.

## 7a. World-scope hydration pattern

**Problem:** `EventBus.run_loaded` is emitted by `SaveSystem.load_or_create()` during `boot.tscn`, before `world.tscn` exists. Systems that subscribe only via `_ready()` miss the signal.

**Rule:** Any system inside `world.tscn` that hydrates from `GameState.run_save` must use the catch-up pattern:

```gdscript
func _ready() -> void:
    EventBus.run_loaded.connect(_on_run_loaded)
    if _has_save_state():
        _on_run_loaded(SaveSystem.SAVE_VERSION)
```

The handler must be idempotent. Autoloads do not need the catch-up because they connect before `boot.gd` calls `load_or_create()`.

## 8. Non-negotiables (for agent reviewers)

Reject any change that:
1. Calls a system directly from another system (must go through EventBus).
2. Uses `_process` for simulation logic (must use `tick` signal).
3. Hardcodes content values that belong in a `.tres` resource.
4. Writes to `user://` without going through `SaveSystem`.
5. Adds a new signal without adding it to this document first.

## 9. Save versioning

Increment `SAVE_VERSION` and add a `migrate()` case any time the JSON schema changes. Never ship a schema change without a migration.

**Migrations must cascade.** A v0 save loaded under build vN must pass through every intermediate step. Implement `migrate()` as a sequence of `if from_version < N:` blocks — *not* a `match` statement.

---

**Last updated**: Phase 19 (team loadout, ecosystem scoring, stat leveling). Current SAVE_VERSION = 20.
