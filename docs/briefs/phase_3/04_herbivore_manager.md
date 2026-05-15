# Brief 04 — HerbivoreManager (spawning, movement, eating)

**Suggested agent**: ChatGPT 5.2 via Copilot. Heaviest brief in Phase 3 — read it carefully and implement step by step.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (signals: `event_started`, `event_resolved`, `organism_spawned`, `organism_died`, `tile_lost`, `ability_used`), § 5 (system map row for HerbivoreManager), § 7a (catch-up pattern).
2. `scripts/systems/territory_system.gd` — `get_owned_coords()`, `_tiles` mutation patterns.
3. `scripts/entities/herbivore.gd` (brief 03).
4. `scripts/systems/ecological_pressure.gd` (brief 02) — for `is_event_active`, `resolve_event`.

## Goal
Manage the lifecycle of herbivore organisms during a `herbivore_wave` event:
1. On `event_started(&"herbivore_wave", payload)`: spawn N herbivores at random edge tiles. N = `payload.spawn_count`.
2. On each `tick`: every herbivore moves one step closer to the nearest owned tile (every `speed_ticks` ticks), or chews the tile it's on (every `chew_ticks` ticks). When chew completes, the tile is removed from territory.
3. On `ability_used(&"toxin_bloom", payload)`: damage all herbivores within `payload.radius_tiles` of `payload.coord`.
4. When all herbivores die: emit `event_resolved(&"herbivore_wave", &"defeated")`.
5. When event expires (handled by EcologicalPressure → emits `event_resolved`): despawn remaining herbivores.

## Outputs (create)
- `scripts/systems/herbivore_manager.gd`
- Modification to `scenes/world/world.tscn` — add `HerbivoreManager` node under `Systems`, after `EcologicalPressure`. Also expose a `@export var herbivore_scene: PackedScene` so it can instantiate herbivores; assign it to `scenes/organisms/herbivore.tscn` in the editor.

## TerritorySystem coordination
HerbivoreManager needs to remove tiles from TerritorySystem when a herbivore finishes chewing. Add a public method to TerritorySystem (this is a tiny patch, include it in the brief):

```gdscript
# In territory_system.gd
func lose_tile(coord: Vector2i, cause: StringName) -> void:
    if not _tiles.has(coord):
        return
    var prev_owner: StringName = _tiles[coord].get("owner_id", OWNER_ID)
    _tiles.erase(coord)
    if _tile_grid.has_method("set_owned"):
        _tile_grid.set_owned(coord, false)
    _sync_run_save()
    EventBus.tile_lost.emit(coord, prev_owner)
```

Note: keep `cause` as a logging parameter for now even though it's unused by TerritorySystem itself — herbivores or other systems might want to filter by cause later.

## Implementation notes for HerbivoreManager

### Constants and state
```gdscript
const HERBIVORE_SPECIES_ID: StringName = &"herbivore"

@export var herbivore_scene: PackedScene
@onready var _territory: Node = get_node("../TerritorySystem")
@onready var _tile_grid: Node = get_node("../../TileGrid")
@onready var _organisms_parent: Node2D = get_node("../../Organisms")

var _herbivores: Array[Herbivore] = []
var _next_organism_id: int = 1
var _is_replaying: bool = false
var _rng: RandomNumberGenerator
```

### `_ready()`
- Seed `_rng` from `GameState.run_seed XOR Time.get_unix_time_from_system()`.
- Connect `event_started`, `event_resolved`, `tick`, `ability_used`, `replay_started`, `replay_finished`, `run_loaded`.
- Catch-up: if `GameState.run_save.organisms` is non-empty, restore them via `_on_run_loaded(SaveSystem.SAVE_VERSION)`.

### `_on_event_started(event_id, payload)`
- Skip unless `event_id == &"herbivore_wave"`.
- For `i in range(payload.spawn_count)`:
  - Pick a spawn tile: random edge tile (x == 0, x == GRID_WIDTH-1, y == 0, or y == GRID_HEIGHT-1).
  - Instantiate `herbivore_scene`. Set `organism_id = _next_organism_id`, `hp = payload.hp`, position via `tile_grid.map_to_local(coord)`.
  - Add to `_organisms_parent`. Append to `_herbivores`. Increment `_next_organism_id`.
  - Emit `organism_spawned(id, HERBIVORE_SPECIES_ID, coord)`.
- Cache the current event payload locally so per-tick logic knows `chew_ticks` and `speed_ticks`. Either store as a member dict or read from `EcologicalPressure._active`.

### `_on_event_resolved(event_id, outcome)`
- Skip unless `event_id == &"herbivore_wave"`.
- For each surviving herbivore: emit `organism_died(id, outcome)`, queue_free the node.
- Clear `_herbivores`. Sync to `run_save.organisms` (now empty).

### `_on_tick(_delta)`
- If `_is_replaying`: return. (Herbivores frozen during catch-up; the wave just resumes after.)
- For each herbivore in `_herbivores`:
  - Track per-herbivore `_action_counter` (store in herbivore via a `data: Dictionary` field, or in a parallel `Dictionary[int, Dictionary]` keyed by organism_id).
  - If herbivore is on an owned tile: chew. Increment chew counter. When ≥ `chew_ticks`, call `_territory.lose_tile(coord, &"herbivore")` and reset counter, then pick a new target.
  - Else: move toward nearest owned tile. Increment move counter. When ≥ `speed_ticks`, take one step (Manhattan, prefer x then y). Reset counter.
  - If no owned tiles remain: despawn (player has lost — see below).
- After processing, sync to save.

### `_on_ability_used(ability_id, payload)`
- Skip unless `ability_id == &"toxin_bloom"`.
- `target: Vector2i = payload.coord`, `radius: int = payload.radius_tiles`, `damage: float = payload.damage`.
- For each herbivore: if Manhattan distance from `coord` to `target` ≤ `radius`, call `take_damage(damage)`. If dead: emit `organism_died(id, &"toxin_bloom")`, queue_free, remove from list.
- After: if `_herbivores.is_empty()` AND a wave is active → call `EcologicalPressure.resolve_event(&"herbivore_wave", &"defeated")`.

### `_on_run_loaded(_v)`
- Despawn any current children.
- Read `run.organisms`. For each entry where `species_id == &"herbivore"`: instantiate, restore coord/hp/id. Track max `organism_id` to seed `_next_organism_id` correctly.

### Save sync
After spawn, despawn, or move/damage tick: rebuild `run.organisms` from `_herbivores`. Same write-through pattern as TerritorySystem and ResourceLedger.

### Player loss
If `TerritorySystem.get_owned_coords().is_empty()` mid-wave: this phase doesn't yet have a "game over" screen. For now, log a warning and let the event expire naturally. We'll wire a real loss-state in Phase 4 when prestige lands.

## Acceptance criteria
- [ ] Herbivores spawn at edges when wave fires.
- [ ] Each herbivore moves toward owned territory at the spec'd `speed_ticks` cadence.
- [ ] On reaching an owned tile, herbivore chews for `chew_ticks` ticks, then the tile reverts (visual overlay clears, `tile_lost` fires).
- [ ] `ability_used(&"toxin_bloom", ...)` damages herbivores in radius; dying ones disappear.
- [ ] Killing all herbivores during a wave triggers `event_resolved(&"herbivore_wave", &"defeated")`.
- [ ] Event expiring naturally despawns remaining herbivores (`event_resolved` from EcologicalPressure handled).
- [ ] Killing the app mid-wave and relaunching: herbivores reappear at saved coords with saved hp.
- [ ] No herbivore ticks fire during offline replay (herbivores resume at their last action_counter on foreground).
- [ ] No direct system imports beyond `TerritorySystem.lose_tile` / `get_owned_coords()` and `EcologicalPressure.resolve_event` / `is_event_active`.

## Out of scope
- Pathfinding around obstacles. Herbivores walk in a straight line; if a tile is unowned, they pass through it.
- Multiple herbivore species. One species this phase.
- Animation. Phase 7.
