# Brief 06 — Run-setup UI: kingdom → niche cascade

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/ui/prestige_screen.gd` — current kingdom-button list.
2. `scripts/ui/main_menu.gd` — `_open_kingdom_select()` flow.
3. `scripts/systems/prestige_system.gd` — `start_run(kingdom_id)`.
4. `data/niches/_index.tres` (post-brief-03 + 04 + 05) — 4 niches: photosynthesizer, decomposer, parasite_plantae, mycorrhizal_fungi.

## Goal
Today's flow: "Begin run as Plantae" → run starts as photosynthesizer plantae. With niches, the run-setup needs to show **kingdom selection** then **niche selection** for that kingdom.

After this brief:
1. Player taps a kingdom button → niche list appears (only unlocked niches for that kingdom).
2. Player taps a niche → run starts as `(kingdom_id, niche_id)`.

## Outputs (modify + small additions)
- `scripts/ui/prestige_screen.gd` — add niche-selection step.
- `scripts/ui/main_menu.gd` (or the kingdom-select overlay it shares with prestige) — same change.
- `scripts/systems/prestige_system.gd` — `start_run(kingdom_id, niche_id)` signature changes.

## Changes

### `PrestigeSystem.start_run` signature
```gdscript
func start_run(kingdom_id: StringName, niche_id: StringName = &"") -> void:
    if not is_kingdom_unlocked(kingdom_id):
        return
    var resolved_niche: StringName = _resolve_niche(kingdom_id, niche_id)
    if resolved_niche == &"":
        push_error("PrestigeSystem: no valid niche for kingdom %s" % String(kingdom_id))
        return
    GameState.current_kingdom_id = kingdom_id
    GameState.current_niche_id = resolved_niche
    GameState.run_seed = randi()
    GameState.is_run_active = true
    if kingdom_id == &"symbiosis":
        GameState.placement_target = &"plantae"
    else:
        GameState.placement_target = kingdom_id
    EventBus.placement_target_changed.emit(GameState.placement_target)
    EventBus.niche_changed.emit(resolved_niche)
    EventBus.run_started.emit(kingdom_id)
    SaveSystem.save_now()


func _resolve_niche(kingdom_id: StringName, requested: StringName) -> StringName:
    # If the requested niche is valid for the kingdom and unlocked, use it.
    # Otherwise fall back to the first unlocked niche for that kingdom.
    var niches: Array[NicheData] = get_niches_for_kingdom(kingdom_id, true)
    if niches.is_empty():
        return &""
    if requested != &"":
        for n in niches:
            if n.id == requested:
                return requested
    return niches[0].id


func get_niches_for_kingdom(kingdom_id: StringName, only_unlocked: bool = true) -> Array[NicheData]:
    var index: NicheIndex = load("res://data/niches/_index.tres") as NicheIndex
    if index == null:
        return []
    var result: Array[NicheData] = []
    for n in index.niches:
        if n.kingdom_id != kingdom_id:
            continue
        if only_unlocked and n.unlock_node_id != &"":
            if not MetaModifiers.is_unlocked(n.unlock_node_id):
                continue
        result.append(n)
    return result
```

### `_reset_run_state` patch
Also clear `current_niche_id`:
```gdscript
GameState.current_niche_id = &""
EventBus.niche_changed.emit(&"")
```

### `prestige_screen.gd` UI changes

After the player taps a kingdom button, instead of immediately starting a run, show a **niche subview** with one button per unlocked niche for that kingdom.

Minimum-viable layout:
- Kingdom buttons stay where they are.
- On kingdom tap: clear/hide the kingdom-list and show a niche-list in the same area.
- Each niche button shows `display_name` + a 1-line `description`.
- Tapping a niche button calls `PrestigeSystem.start_run(kingdom_id, niche_id)`.
- A back button returns from niche-list to kingdom-list.

If a kingdom has only one unlocked niche, **skip the niche step** and call `start_run(kingdom_id, that_niche_id)` directly. (Prevents an annoying one-option screen for new players.)

Pseudo-code:
```gdscript
func _on_kingdom_button_pressed(kingdom_id: StringName) -> void:
    var niches: Array[NicheData] = PrestigeSystem.get_niches_for_kingdom(kingdom_id)
    if niches.size() == 1:
        PrestigeSystem.start_run(kingdom_id, niches[0].id)
        _close_overlay()
        return
    _show_niche_subview(kingdom_id, niches)


func _show_niche_subview(kingdom_id: StringName, niches: Array[NicheData]) -> void:
    # Hide kingdom buttons. Create one button per niche. Add a "back" button.
    ...
```

### `main_menu.gd` flow
If `main_menu` uses the prestige screen for kingdom-select on cold launch (per brief 7 of Phase 4), no changes needed beyond what's above — the flow inherits.

## Acceptance criteria
- [ ] Plantae kingdom + only photosynthesizer unlocked: tapping Plantae starts the run immediately (skip niche step).
- [ ] Plantae kingdom + parasite_plantae unlocked: tapping Plantae shows two niche buttons.
- [ ] Tapping a niche button starts the run with the right `(kingdom_id, niche_id)` pair.
- [ ] `GameState.current_niche_id` is set; `EventBus.niche_changed` fires on run start.
- [ ] `save.json`'s `run.niche_id` reflects the chosen niche.
- [ ] Resume flow ("Continue" button) uses the saved `niche_id`; no fresh niche-pick prompt.

## Out of scope
- Species selection within a niche (Phase 9).
- Niche descriptions with previews/icons (brief 07).
- Multi-step navigation animations.
- Showing locked niches with "requires X" tooltips (nice-to-have; defer to polish).
