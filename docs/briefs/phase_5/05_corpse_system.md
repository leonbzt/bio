# Brief 05 — CorpseSystem (decay-producing tiles)

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (`organism_died` signal), per-array entry shapes (`run.organisms[i]` with corpse variant).
2. `scripts/systems/herbivore_manager.gd` — emits `organism_died` when a herbivore dies.
3. `scripts/autoloads/resource_ledger.gd` — `add(DECAY, ...)`.

## Goal
When an organism dies (typically a herbivore from Toxin Bloom), spawn a corpse "organism" on that tile that:
1. Produces a fixed amount of decay per tick for N ticks.
2. Acts as a valid substrate for fungi colonization (FungiColonization in brief 06 queries this).
3. Despawns when fully decomposed.

## Outputs (create)
- `scripts/systems/corpse_system.gd`
- Modification to `scenes/world/world.tscn` — add `CorpseSystem` node under `Systems`, near `HerbivoreManager`.

## Implementation

### Constants
```gdscript
const SPECIES_ID: StringName = &"corpse"
const DEFAULT_DECAY_PER_TICK: float = 0.5
const DEFAULT_DECAY_TICKS: int = 30
```

### State
```gdscript
var _corpses: Dictionary[Vector2i, Dictionary] = {}    # coord -> {ticks_remaining, decay_per_tick, organism_id}
var _next_corpse_id: int = 100_000    # avoid colliding with herbivore ids
```

### `_ready()`
- Connect `EventBus.organism_died.connect(_on_organism_died)`.
- Connect `EventBus.tick.connect(_on_tick)`.
- Connect `EventBus.run_loaded.connect(_on_run_loaded)`.
- Connect `EventBus.replay_started`/`replay_finished` for the same skip-during-replay pattern HerbivoreManager uses.
- Catch-up per § 7a.

### `_on_organism_died(organism_id, cause)`
- Find the dead herbivore's coord from HerbivoreManager. Simplest: HerbivoreManager already emits the signal; pass coord via an extension or have HerbivoreManager call CorpseSystem directly via a public method.
- **Cleanest**: change HerbivoreManager so that when a herbivore dies, it ALSO calls `CorpseSystem.spawn_corpse(coord)`. The signal stays for other subscribers (stats, UI). Direct call from HerbivoreManager to CorpseSystem violates "no system-to-system imports" — so instead, **extend the signal**:

Hmm, that's a contract change. Skip it. Use a side channel:

**Final approach**: HerbivoreManager already has the herbivore's coord at the moment of death. Have it call a public method on CorpseSystem via an `@onready` reference, OR (better) push the coord into the `organism_died` payload by switching to a dictionary-payload pattern.

For Phase 5, take the pragmatic path: **add a sibling reference**. HerbivoreManager can `get_node("../CorpseSystem")` and call `spawn_corpse(coord, decay_per_tick, ticks)` directly. This is technically an internal cross-system call, but both live under the same `Systems` parent and the call is one-directional (no return value, no state coupling). Document the exception in CorpseSystem's docstring.

```gdscript
# In CorpseSystem
func spawn_corpse(coord: Vector2i, decay_per_tick: float = DEFAULT_DECAY_PER_TICK, ticks: int = DEFAULT_DECAY_TICKS) -> void:
    if _corpses.has(coord):
        # Stack? For MVP just refresh the timer to the larger value.
        _corpses[coord]["ticks_remaining"] = max(_corpses[coord]["ticks_remaining"], ticks)
        return
    var organism_id: int = _next_corpse_id
    _next_corpse_id += 1
    _corpses[coord] = {
        "ticks_remaining": ticks,
        "decay_per_tick": decay_per_tick,
        "organism_id": organism_id,
        "coord": coord,
    }
    _sync_run_save()
    EventBus.organism_spawned.emit(organism_id, SPECIES_ID, coord)


# Called by HerbivoreManager when a herbivore dies. Make sure HerbivoreManager imports
# CorpseSystem via @onready var _corpses_node := get_node("../CorpseSystem").
```

### `_on_tick(_delta)`
- If `_is_replaying`: return.
- For each entry in `_corpses`:
  - `ResourceLedger.add(ResourceLedger.DECAY, entry.decay_per_tick)` — but ONLY if fungi run. In plantae runs, corpse decay still happens but isn't useful (no decay consumer); skip to avoid distracting numbers in the HUD. Pragmatic call: emit decay always; if the player isn't fungi they just see decay tick up. That's fine; matches biology.
  - Actually: emit always. Decay is a real resource regardless of kingdom.
  - Decrement `ticks_remaining`. When ≤ 0: emit `organism_died(organism_id, &"decomposed")`, erase entry.
- `_sync_run_save()` after the loop.

### `_on_run_loaded(_v)`
- Read `run.organisms`. For entries where `species_id == "corpse"`, restore `_corpses` from `data.{decay_per_tick, decay_remaining_ticks}` and the entry's `coord`/`organism_id`.

### `_sync_run_save()`
- Rebuild `run.organisms`. **Coordinate with HerbivoreManager:** HerbivoreManager also writes its own herbivores to this array. Either:
  - Use a shared rebuild step that polls both systems (cleanest, but coupling).
  - Each system writes its own subset, identified by `species_id`. CorpseSystem only manages entries where `species_id == "corpse"`. Reads existing array, filters out its own entries, appends fresh corpse entries, writes back.

Go with the filter-and-append pattern. Each system stays responsible for its own organisms.

```gdscript
func _sync_run_save() -> void:
    var run: Dictionary = GameState.run_save
    var existing: Array = run.get("organisms", []) as Array
    var kept: Array = []
    for o in existing:
        if not (o is Dictionary):
            continue
        if String(o.get("species_id", "")) != String(SPECIES_ID):
            kept.append(o)
    for coord in _corpses.keys():
        var c: Dictionary = _corpses[coord]
        kept.append({
            "organism_id": c.organism_id,
            "species_id": "corpse",
            "coord": [coord.x, coord.y],
            "hp": float(c.ticks_remaining),
            "data": {
                "decay_per_tick": c.decay_per_tick,
                "decay_remaining_ticks": c.ticks_remaining,
            }
        })
    run["organisms"] = kept
```

Apply the same pattern to `HerbivoreManager._sync_run_save` if it doesn't already filter — it should filter to only its `&"herbivore"` species.

### `is_corpse_at(coord) -> bool`
Public method for FungiColonization (brief 06):
```gdscript
func is_corpse_at(coord: Vector2i) -> bool:
    return _corpses.has(coord)
```

## Acceptance criteria
- [ ] Kill a herbivore with Toxin Bloom → a corpse appears in `run.organisms` at that tile's coord with the spec'd data fields.
- [ ] Decay resource climbs by `decay_per_tick` per second per active corpse.
- [ ] After ~30 ticks, corpse despawns and stops producing decay.
- [ ] Save mid-decay; relaunch: corpse re-spawns at same coord with the saved `decay_remaining_ticks`.
- [ ] HerbivoreManager and CorpseSystem don't clobber each other's entries in `run.organisms`.
- [ ] No corpse spawned by deaths with cause `&"decomposed"` (avoid infinite chain).

## Out of scope
- Visual sprite for corpses. Phase 7. For now they're invisible but tracked in data.
- Corpse stacking on the same tile. First-wins for MVP.
- Plant-tile deaths (not implemented yet; only herbivores die in Phase 3/5).
