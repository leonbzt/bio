# Brief 04 — EventData.scope schema + EcologicalPressure filter + 4 new scoped events

**Suggested agent**: ChatGPT 5.2 (schema + filter) + Kilo (data). Route diff to **Claude** — filter logic.

Read first:
1. `scripts/data/event_data.gd` — current schema.
2. `scripts/systems/ecological_pressure.gd._maybe_trigger`.
3. `docs/briefs/phase_13_paused/04_event_scope_schema.md` + `05_event_content_pass.md` — direct source material.

## Goal

Add `EventData.scope` + `scope_target` fields. Filter event pool by scope before weighted roll. Backfill all existing events with explicit scope. Author 4 new scoped events.

## Schema

### `scripts/data/event_data.gd`

```gdscript
# Phase 14b axis-scoped events.
# Recognized scopes:
#   &"world"       — always eligible
#   &"kingdom"     — current_kingdom_id matches (denormalized mirror)
#   &"species_tag" — any species in unlocked_species_in_run has this tag
#   &"era"         — current era id matches
#   &"ecosystem"   — current ecosystem id matches
@export var scope: StringName = &"world"
@export var scope_target: StringName = &""
```

## Filter logic

### `scripts/systems/ecological_pressure.gd._maybe_trigger`

Insert scope filter before the weighted roll:

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
    for ev in eligible:
        total_weight += ev.trigger_weight
    if total_weight <= 0.0:
        return

    var roll: float = _rng.randf_range(0.0, total_weight)
    var picked: EventData = null
    for ev in eligible:
        roll -= ev.trigger_weight
        if roll <= 0.0:
            picked = ev
            break
    if picked == null:
        return

    # Legacy kingdom_required check removed — scope handles it.
    if picked.id == &"herbivore_wave" and owned_count < 6:
        return

    var payload: Dictionary = picked.payload.duplicate(true)
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
        push_warning("EcologicalPressure: event %s has scope %s but no scope_target" % [event_data.id, scope])
        return false
    if scope == &"kingdom":
        return StringName(GameState.current_kingdom_id) == target
    if scope == &"species_tag":
        # Match if any introduced species in this run carries the target tag.
        var unlocked: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
        var species_index: SpeciesIndex = load("res://data/species/_index.tres") as SpeciesIndex
        if species_index == null:
            return false
        for sp_id in unlocked:
            for sp in species_index.species:
                if sp.id == StringName(sp_id) and sp.tags.has(target):
                    return true
        return false
    if scope == &"era":
        var era_id: StringName = StringName(GameState.meta_save.get("current_era_id", ""))
        return era_id == target
    if scope == &"ecosystem":
        var eco_id: StringName = StringName(GameState.meta_save.get("current_ecosystem_id", ""))
        return eco_id == target
    push_warning("EcologicalPressure: unknown scope %s on event %s" % [scope, event_data.id])
    return false
```

## Backfill existing event scopes

| File | scope | scope_target |
|---|---|---|
| `data/events/drought.tres` | `&"world"` | `&""` |
| `data/events/cool_spell.tres` | `&"world"` | `&""` |
| `data/events/herbivore_wave.tres` | `&"species_tag"` | `&"plantae"` |
| `data/events/spore_infection.tres` | `&"species_tag"` | `&"fungi"` |
| `data/events/mass_extinction.tres` | `&"world"` | `&""` |

(Legacy `payload.kingdom_required` may stay in file but is no longer read. Cleanup deferred.)

## 4 new scoped events

### `data/events/cold_snap.tres`

```
[resource]
script = ExtResource("1")
id = &"cold_snap"
display_name = "Cold Snap"
description = "The cold deepens. Tiles slow."
trigger_weight = 0.8
duration_ticks = 90
scope = &"era"
scope_target = &"cryogenian"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.5,
    "biomass_multiplier": 0.7
},
"counter_node": "cryotolerance"
}
```

### `data/events/sulfur_bloom.tres`

```
[resource]
id = &"sulfur_bloom"
display_name = "Sulfur Bloom"
description = "Vents belch acid haze. Plantae wither; fungi thrive."
trigger_weight = 0.6
duration_ticks = 60
scope = &"ecosystem"
scope_target = &"cryo_volcanic_vent"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.6,
    "biomass_multiplier": 0.8
},
"fungi_bonus": 1.5
}
```

### `data/events/wildfire.tres`

```
[resource]
id = &"wildfire"
display_name = "Wildfire"
description = "Smoke darkens the sky. Old growth burns; new growth follows."
trigger_weight = 0.5
duration_ticks = 75
scope = &"era"
scope_target = &"devonian"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.7,
    "biomass_multiplier": 0.6
},
"post_event_bonus_ticks": 60,
"post_event_biomass_multiplier": 1.3
}
```

(Post-event bonus wiring is optional polish. Ship without it if AmbientModifierSystem timer plumbing is non-trivial.)

### `data/events/swamp_fever.tres`

```
[resource]
id = &"swamp_fever"
display_name = "Swamp Fever"
description = "Standing water turns; pathogens rise. Animal tiles weaken."
trigger_weight = 0.6
duration_ticks = 60
scope = &"ecosystem"
scope_target = &"dev_inland_swamp"
payload = {
"modifiers": {
    "biomass_multiplier": 0.85
},
"animal_hp_modifier": 0.7
}
```

(`animal_hp_modifier` is a payload-reserved field — wiring deferred to Phase 15 when animal HP system extends.)

## Update `data/events/_index.tres`

Append all 4 new events.

## AmbientModifierSystem `biomass_multiplier` channel

Confirm AmbientModifierSystem recognizes `&"biomass_multiplier"`. If not, add it (single dict entry alongside `sunlight_multiplier`, `nutrient_multiplier`). `growth_system._apply_yields` reads it via `_ambient.get_multiplier(&"biomass_multiplier")` once per biomass calculation.

## Acceptance criteria

- [ ] `EventData.scope` + `scope_target` fields exist; existing files load default `&"world"`.
- [ ] 5 existing events have explicit scope set.
- [ ] 4 new events load + registered in index.
- [ ] `AmbientModifierSystem` recognizes `&"biomass_multiplier"`.
- [ ] Fungi run never sees `herbivore_wave` in candidate pool.
- [ ] Cryogenian fungi run on volcanic_vent sees `cold_snap`, `sulfur_bloom`, `spore_infection`, `drought`, `cool_spell` as eligible; not `wildfire` / `swamp_fever` / `herbivore_wave`.
- [ ] Devonian plantae run on inland_swamp sees `drought`, `cool_spell`, `herbivore_wave`, `wildfire`, `swamp_fever`; not `cold_snap` / `sulfur_bloom` / `spore_infection`.
- [ ] Mass extinction stays at weight 0; only fires via EraSystem.

## Out of scope

- Per-niche-scoped events (legacy `niche` scope deprecated; capability removed).
- Post-event scheduled modifiers as a general system (graceful degrade on wildfire).
- Animal HP modifier wiring (Phase 15).
- HUD hints surfacing "counter node available" (polish).
