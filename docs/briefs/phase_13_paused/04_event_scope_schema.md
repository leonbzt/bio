# Brief 04 — EventData.scope + scope_target schema + EcologicalPressure filtering

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — filter logic determines what events the player ever sees.

Read first:
1. `scripts/data/event_data.gd` — current schema.
2. `scripts/systems/ecological_pressure.gd._maybe_trigger` — where filtering lives.
3. `data/events/herbivore_wave.tres` — the existing `payload.kingdom_required` field is being replaced.
4. `scripts/autoloads/era_system.gd` — `get_current_era()` + `get_current_ecosystem()` are the lookups.

## Goal

Make events declare what context they belong to, instead of every event being rolled from one global pool. A fungi run should *never see* herbivore_wave in the lottery — not "rolls and skips it", *never sees it*.

## Schema change

### `scripts/data/event_data.gd`

```gdscript
class_name EventData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var trigger_weight: float = 1.0
@export var duration_ticks: int = 60
@export var payload: Dictionary = {}

# Phase 13 axis-scoped events.
# Recognized scope values:
#   &"world"     — always eligible
#   &"kingdom"   — only when current_kingdom_id == scope_target
#   &"niche"     — only when current_niche_id == scope_target
#   &"era"       — only when current era's id == scope_target
#   &"ecosystem" — only when current ecosystem's id == scope_target
# scope_target is the matching id; ignored when scope == &"world".
@export var scope: StringName = &"world"
@export var scope_target: StringName = &""
```

The default `&"world"` means newly-created events without explicit scope behave like all existing events did (until brief 05 retags them).

## Filter logic

### `scripts/systems/ecological_pressure.gd._maybe_trigger`

Insert a scope-eligibility filter before the weighted roll. Remove the legacy `payload.kingdom_required` check (now handled by scope).

```gdscript
func _maybe_trigger() -> void:
    if _active.size() > 0:
        return
    if not _territory.has_method("get_owned_coords"):
        return
    var owned_count: int = _territory.get_owned_coords().size()
    if owned_count < _get_min_tiles_before_events():
        return
    if _rng.randf() >= TRIGGER_PROBABILITY:
        return

    # Phase 13: build the eligible candidate pool by scope first.
    var eligible: Array[EventData] = []
    for event_data in _events_by_id.values():
        if event_data.trigger_weight <= 0.0:
            continue
        if not _event_matches_scope(event_data):
            continue
        eligible.append(event_data)
    if eligible.is_empty():
        return

    var total_weight: float = 0.0
    for event_data in eligible:
        total_weight += event_data.trigger_weight
    if total_weight <= 0.0:
        return

    var roll: float = _rng.randf_range(0.0, total_weight)
    var picked: EventData = null
    for event_data in eligible:
        roll -= event_data.trigger_weight
        if roll <= 0.0:
            picked = event_data
            break
    if picked == null:
        return

    # The legacy kingdom_required check is gone — scope handles it now.
    if picked.id == &"herbivore_wave" and owned_count < 6:
        return

    var payload: Dictionary = picked.payload.duplicate(true)
    # Stamp scope into the payload for downstream consumers (HUD toast, discovery, etc.).
    payload["scope"] = String(picked.scope)
    if picked.scope_target != &"":
        payload["scope_target"] = String(picked.scope_target)
    _active.append({
        "id": picked.id,
        "ticks_remaining": picked.duration_ticks,
        "payload": payload
    })
    _sync_run_save()
    EventBus.event_started.emit(picked.id, payload)


func _event_matches_scope(event_data: EventData) -> bool:
    var scope := event_data.scope
    if scope == &"" or scope == &"world":
        return true
    var target := event_data.scope_target
    if target == &"":
        # Misconfigured: scope set but no target. Skip with a warning once.
        push_warning("EcologicalPressure: event %s has scope %s but no scope_target" % [event_data.id, scope])
        return false
    if scope == &"kingdom":
        return StringName(GameState.current_kingdom_id) == target
    if scope == &"niche":
        return StringName(GameState.current_niche_id) == target
    if scope == &"era":
        var era_id: StringName = StringName(GameState.meta_save.get("current_era_id", ""))
        return era_id == target
    if scope == &"ecosystem":
        var eco_id: StringName = StringName(GameState.meta_save.get("current_ecosystem_id", ""))
        return eco_id == target
    push_warning("EcologicalPressure: unknown scope %s on event %s" % [scope, event_data.id])
    return false
```

### Legacy field migration in data

The `payload.kingdom_required` field stays in the source `.tres` files (no rewrite needed) but is no longer read. Brief 05 sets `scope = &"kingdom"` + `scope_target = &"plantae"` on herbivore_wave, making the legacy field redundant.

Optionally clean up in a follow-up — not blocking.

## EraSystem integration

The era system's `_emit_mass_extinction` already stamps `payload.scope = "world"` manually. Update it to also stamp `scope_target = ""` for consistency, and rely on the EventData's `scope` field (set in brief 05) rather than payload-stamping going forward:

```gdscript
# In era_system.gd._emit_mass_extinction — payload still carries the contextual
# from_era/to_era hints, but scope now flows from EventData itself.
func _emit_mass_extinction(from_era: StringName, to_era: StringName) -> void:
    var payload: Dictionary = {
        "scope": "world",
        "narrative_only": true,
        "from_era": String(from_era),
        "to_era": String(to_era)
    }
    EventBus.event_started.emit(&"mass_extinction", payload)
    EventBus.event_resolved.emit(&"mass_extinction", &"narrative")
```

(No change in behavior; just calling out that the manual payload stamping is now redundant with EventData.scope. Either delete the payload key or leave it — Phase 13 leaves it for minimal diff.)

## ARCHITECTURE.md updates

- §4 schema — add `scope` + `scope_target` to `EventData`.
- §6 systems — update EcologicalPressure section to describe the scope filter.

## Acceptance criteria

- [ ] `EventData.scope` and `EventData.scope_target` exist as exported fields.
- [ ] Existing `.tres` files load with no inspector errors (default scope = `&"world"`).
- [ ] `EcologicalPressure._maybe_trigger` filters by scope before rolling.
- [ ] A fungi run never has `herbivore_wave` in its candidate pool (after brief 05 sets the scope on it).
- [ ] A plantae run still rolls drought + cool_spell + herbivore_wave normally.
- [ ] An unknown scope value logs a warning and excludes the event (no crash).
- [ ] `mass_extinction` is `trigger_weight = 0`, so the scope filter is moot for it (still fires explicitly via EraSystem).

## Out of scope

- Authoring new scoped events (brief 05).
- Per-niche scope content (capability ships, no niche-scoped events authored in Phase 13).
- Per-ecosystem scope content (same — capability without content).
- Per-era scope content (one or two seeded in brief 05).
- Scope-aware UI hints in HUD toasts ("This event only fires in Cryogenian"). Polish, deferred.
- Removing the `payload.kingdom_required` legacy field from existing `.tres` files (cleanup, not breaking).
