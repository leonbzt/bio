# Brief 08 — Mass extinction event content + trigger on era transition

**Suggested agent**: Kilo for the event data, ChatGPT 5.2 for the trigger glue. Route diff to Claude.

Read first:
1. `docs/briefs/phase_12/04_era_system_autoload.md` — `era_transition_started` is the signal.
2. `docs/briefs/phase_12/06_era_transition_passage.md` — the transition narrative UI.
3. `data/events/drought.tres` for `EventData` schema reference.
4. `scripts/systems/ecological_pressure.gd` — how events fire.

## Goal

Add a **mass extinction event** that fires once when an era transitions. In Phase 12, this is **narrative weight only** — a second passage shown alongside the era transition narrative. Gameplay effects (destroying tiles, cascading deaths) are explicitly deferred to Phase 13.

The mass extinction event is also the first "world-scoped" event in the game — its `payload` carries a `scope: "world"` hint that Phase 13 will use when introducing `EventData.scope`.

## Outputs

### `data/events/mass_extinction.tres`

```
[gd_resource type="Resource" script_class="EventData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"mass_extinction"
display_name = "Mass Extinction"
description = "Most of what you built is gone. The world goes on without it. So do you, in some form."
trigger_weight = 0.0
duration_ticks = 1
payload = {
"scope": "world",
"narrative_only": true
}
```

`trigger_weight = 0.0` means the event never rolls naturally — it only fires via explicit code path (the era-transition trigger below).

Add to `data/events/_index.tres`:
```
[ext_resource type="Resource" path="res://data/events/mass_extinction.tres" id="<next>"]
# Append to events array.
```

### Trigger from era transition

In `scripts/autoloads/era_system.gd` `_maybe_unlock_next_era`, after emitting `era_transition_started`:

```gdscript
func _maybe_unlock_next_era(completed_era_id: StringName) -> void:
    for era in _eras_by_id.values():
        if era.unlock_requires_prev_era == completed_era_id:
            if is_era_unlocked(era.id):
                return
            var unlocked: Array = GameState.meta_save.get("eras_unlocked", []) as Array
            unlocked.append(String(era.id))
            GameState.meta_save["eras_unlocked"] = unlocked
            EventBus.era_transition_started.emit(completed_era_id, era.id)
            _emit_mass_extinction(completed_era_id, era.id)
            return


func _emit_mass_extinction(from_era: StringName, to_era: StringName) -> void:
    var payload: Dictionary = {
        "scope": "world",
        "narrative_only": true,
        "from_era": String(from_era),
        "to_era": String(to_era)
    }
    EventBus.event_started.emit(&"mass_extinction", payload)
    # Auto-resolve immediately — it's narrative only.
    EventBus.event_resolved.emit(&"mass_extinction", &"narrative")
```

The event fires, the HUD toast shows the description (existing toast system handles this), and the existing event-discovery wiring triggers the discovery log (if brief 09 authors a `disc_event_mass_extinction` entry).

### Narrative passage piggyback

The era-transition passage (brief 06) is already shown. Mass extinction's description ("Most of what you built is gone...") appears as a HUD toast underneath — making the moment feel multi-layered.

Phase 13 expands mass extinction with actual gameplay effects (tile clearing, optional run-state preservation rules, restart-from-prestige weight). Phase 12 just stamps the moment narratively.

## Acceptance criteria
- [ ] `data/events/mass_extinction.tres` exists; loads in inspector.
- [ ] Registered in events index.
- [ ] `mass_extinction` event never fires from EcologicalPressure's random rolls (`trigger_weight = 0.0`).
- [ ] On Cryogenian → Devonian transition:
  - [ ] Era-transition narrative passage shows (brief 06).
  - [ ] HUD event toast displays "Mass Extinction — Most of what you built is gone..."
  - [ ] `disc_event_mass_extinction` discovery entry unlocks (brief 09 authors it).
- [ ] No gameplay disruption: tiles intact, resources intact, just narrative beats.

## Out of scope
- Gameplay effects (Phase 13).
- Per-extinction archive of what was lost ("you lost N tiles, X events survived, etc." stats). Polish.
- Player choice during extinction ("save one species via meta currency"). Future design.
- `EventData.scope` field as proper schema (Phase 13 adds it).
