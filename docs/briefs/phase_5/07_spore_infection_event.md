# Brief 07 — Spore infection event

**Suggested agent**: Kilo for the .tres. ChatGPT for the handler.

Read first:
1. `data/events/herbivore_wave.tres` and `data/events/_index.tres` — pattern.
2. `scripts/systems/ecological_pressure.gd` — how `event_started` is emitted; `_maybe_trigger` filtering for fungi-only.
3. `scripts/systems/fungi_colonization.gd` (brief 06) — adjacency rules to reuse.

## Goal
A new ecological event that fires only in fungi runs. While active, spores spread fungi to one adjacent unowned subsurface tile per N ticks. No player input required; it's a passive amplifier.

This gives fungi runs a fitting tempo: fewer tense moments than herbivore waves, more "your network is silently spreading" feel.

## Outputs (create)

### Content
`data/events/spore_infection.tres`:
- `id = &"spore_infection"`
- `display_name = "Spore Bloom"`
- `description = "Conditions favor passive fungal spread."`
- `trigger_weight = 0.8`
- `duration_ticks = 60`
- `payload = {"spread_every_ticks": 5, "kingdom_required": "fungi"}`

Add it to `data/events/_index.tres`:
```
[ext_resource type="Resource" path="res://data/events/spore_infection.tres" id="5"]
...
events = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4"), ExtResource("5")])
```

### Handler
`scripts/systems/spore_infection_handler.gd`:
```gdscript
extends Node

const EVENT_ID: StringName = &"spore_infection"
const KINGDOM_ID: StringName = &"fungi"

@onready var _territory: Node = get_node("../TerritorySystem")

var _spread_counter: int = 0
var _spread_every: int = 5
var _is_active: bool = false
var _is_replaying: bool = false


func _ready() -> void:
    EventBus.event_started.connect(_on_event_started)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.tick.connect(_on_tick)
    EventBus.replay_started.connect(func(_n): _is_replaying = true)
    EventBus.replay_finished.connect(func(): _is_replaying = false)


func _on_event_started(event_id: StringName, payload: Dictionary) -> void:
    if event_id != EVENT_ID:
        return
    _is_active = true
    _spread_counter = 0
    _spread_every = int(payload.get("spread_every_ticks", 5))


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
    if event_id != EVENT_ID:
        return
    _is_active = false


func _on_tick(_delta: float) -> void:
    if not _is_active or _is_replaying:
        return
    if GameState.current_kingdom_id != KINGDOM_ID:
        return
    _spread_counter += 1
    if _spread_counter < _spread_every:
        return
    _spread_counter = 0
    _try_spread_one()


func _try_spread_one() -> void:
    var owned: Array[Vector2i] = _territory.get_subsurface_owned_coords(KINGDOM_ID)
    if owned.is_empty():
        return
    # Find any unowned-at-subsurface tile adjacent to owned. Pick the first one.
    var seen := {}
    for c in owned:
        seen[c] = true
    for c in owned:
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var neighbor: Vector2i = c + offset
            if neighbor.x < 0 or neighbor.y < 0:
                continue
            if neighbor.x >= 32 or neighbor.y >= 48:
                continue
            if seen.has(neighbor):
                continue
            if _territory.get_subsurface_owner(neighbor) != &"":
                continue
            _territory.add_subsurface(neighbor, KINGDOM_ID)
            return
```

### Scene wiring
Add `SporeInfectionHandler` under `Systems` in `world.tscn` near other event handlers.

## EcologicalPressure changes
Add a kingdom-filter to `_maybe_trigger()`:

```gdscript
# Inside the selection step, after picking an event by weight:
var kingdom_required: String = String(picked_event.payload.get("kingdom_required", ""))
if kingdom_required != "" and String(GameState.current_kingdom_id) != kingdom_required:
    return  # skip this firing; another check tick will roll again
```

Add `kingdom_required` to herbivore_wave's payload (set to `"plantae"`) so plantae runs get herbivore waves but fungi runs don't. Drought / cool_spell keep `kingdom_required` empty for now (they can affect anyone once their handlers are written).

## Acceptance criteria
- [ ] In a fungi run with ≥ 6 owned subsurface tiles, spore_infection eventually fires.
- [ ] While active, one new subsurface-fungi tile appears every 5 ticks on the edge of the existing network.
- [ ] In a plantae run, spore_infection never fires (kingdom filter rejects).
- [ ] In a fungi run, herbivore_wave never fires (kingdom filter rejects).
- [ ] On `event_resolved`, passive spread stops.
- [ ] Kill app mid-event, relaunch: event resumes (EcologicalPressure already persists `active_events`); handler picks up via the re-emitted `event_started`.

## Out of scope
- Sound/animation for spore bursts. Phase 7.
- Spread targeting heuristics (currently picks first valid neighbor). Random selection or scoring → Phase 7.
- Drought/cool_spell handlers. Phase 7.
