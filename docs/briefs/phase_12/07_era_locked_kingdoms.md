# Brief 07 — Era-locked kingdom availability

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — touches PrestigeSystem contract.

Read first:
1. `docs/briefs/phase_12/04_era_system_autoload.md`.
2. `scripts/systems/prestige_system.gd` — `start_run` is the enforcement point.
3. `scripts/ui/prestige_screen.gd` — brief 05 already added the filter at the UI level.

## Goal
Make the era restriction binding at the engine level, not just the UI. If a player somehow bypasses the UI filter (e.g., dev console call to `PrestigeSystem.start_run(&"plantae")` during Cryogenian), the system refuses. The UI filter (brief 05) is the soft enforcement; this is the hard one.

## Implementation

### Extend `prestige_system.start_run`

After the `is_kingdom_unlocked` check, add:

```gdscript
func start_run(kingdom_id: StringName, niche_id: StringName = &"") -> void:
    if not is_kingdom_unlocked(kingdom_id):
        return
    if not _is_kingdom_available_in_current_era(kingdom_id):
        push_warning("PrestigeSystem: kingdom %s is not available in the current era" % String(kingdom_id))
        return
    # ... rest of existing start_run ...


func _is_kingdom_available_in_current_era(kingdom_id: StringName) -> bool:
    var era: EraData = EraSystem.get_current_era()
    if era == null:
        return true  # No era system loaded (e.g., very early init) — allow.
    if era.available_kingdoms.is_empty():
        return true  # Empty list = no restriction.
    return era.available_kingdoms.has(kingdom_id)
```

### Tests

Append to `tests/test_prestige_system.gd`:

```gdscript
func test_start_run_blocked_by_era() -> void:
    # Set up: Cryogenian era, player has plantae unlocked, plantae is NOT in
    # cryogenian.available_kingdoms — start_run should be a no-op.
    GameState.meta_save = {
        "unlocked_kingdoms": ["plantae", "fungi"],
        "current_era_id": "cryogenian",
        "current_ecosystem_id": "cryo_polar_ice",
        "kingdoms_played": [], "evolution_tree": {}, "statistics": {},
        "discovery_log": {}, "niches_played": [], "ecosystem_completions": {},
        "eras_unlocked": ["cryogenian"]
    }
    GameState.is_run_active = false
    PrestigeSystem.start_run(&"plantae")
    assert_false(GameState.is_run_active)


func test_start_run_allowed_by_era() -> void:
    GameState.meta_save["current_era_id"] = "cryogenian"
    GameState.is_run_active = false
    PrestigeSystem.start_run(&"fungi", &"decomposer")
    assert_true(GameState.is_run_active)
```

## Acceptance criteria
- [ ] During Cryogenian: `PrestigeSystem.start_run(&"plantae")` no-ops with a console warning.
- [ ] During Cryogenian: `PrestigeSystem.start_run(&"fungi")` succeeds.
- [ ] During Devonian: both succeed.
- [ ] If no era is set (rare), no restriction.
- [ ] UI filter from brief 05 still works (UI never offers the locked kingdom button).

## Out of scope
- Era-locked niche enforcement (niches inherit kingdom availability; if kingdom is locked, all its niches are unreachable through this path).
- Era-locked evolution-tree nodes (Phase 13+).
- Per-era resource availability (Phase 14).
