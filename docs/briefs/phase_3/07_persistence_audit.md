# Brief 07 — Persistence audit (active_events + organisms)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude before merge — touches save state.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (save schema), per-array entry shapes for `organisms` and `active_events`.
2. `scripts/systems/ecological_pressure.gd` (brief 02) — should already write to `run.active_events`.
3. `scripts/systems/herbivore_manager.gd` (brief 04) — should already write to `run.organisms`.
4. `scripts/autoloads/save_system.gd` — `_build_default_save()`.

## Goal
Verify and patch (if needed) that the new mid-event state survives kill-and-relaunch. This is a verification + small-fix brief, not a new feature.

## Procedure

### Step 1 — Inspect the save mid-event
1. Trigger a herbivore wave (run for ~5 minutes after owning ≥ 6 tiles).
2. While the wave is active and herbivores are mid-chew, background the app.
3. `adb pull /sdcard/Android/data/<package>/files/save.json` and inspect.

Confirm:
- [ ] `run.active_events` contains exactly one entry with `id == "herbivore_wave"`, `ticks_remaining > 0`, full payload.
- [ ] `run.organisms` contains as many entries as visible herbivores. Each has the spec'd shape (organism_id, species_id, coord, hp, data).
- [ ] Per-herbivore `data.action_counter` (or whatever HerbivoreManager uses to track chew/move progress) is present so resumed herbivores don't reset.

### Step 2 — Restore test
1. Force-kill the app from recents.
2. Relaunch.
3. Confirm:
   - [ ] Toast does NOT re-appear (it's a one-shot animation; `event_started` re-fires from EcologicalPressure on hydration but the toast can debounce by tracking event id).
   - [ ] Herbivores re-appear at saved coords with saved hp.
   - [ ] Wave timer continues from saved `ticks_remaining` (verify by quick math or log).
   - [ ] Tapping Toxin Bloom still works.

### Step 3 — Defensive fixes (if anything in step 2 fails)

Common bugs and fixes:

**A. Toast re-fires on relaunch.** EcologicalPressure re-emits `event_started` during `_on_run_loaded` to let HerbivoreManager rehydrate. HUD's toast handler then shows the toast again. Fix: HUD tracks the last shown event id and timestamp; if the same event_id was already shown within the last 30 seconds, skip the toast (it's a rehydration). Add to `hud.gd`:
```gdscript
var _last_toast_event_id: StringName = &""
var _last_toast_unix: int = 0

func _on_event_started(event_id, _payload):
    var now: int = int(Time.get_unix_time_from_system())
    if event_id == _last_toast_event_id and now - _last_toast_unix < 30:
        return  # rehydration, suppress
    _last_toast_event_id = event_id
    _last_toast_unix = now
    # ... show toast
```

**B. Herbivores forget their action_counter.** HerbivoreManager's save sync must include the per-herbivore counter under the `data` key. Make sure `_sync_run_save` does:
```gdscript
"data": {"action_counter": h.action_counter, "target": [target.x, target.y]}
```
And `_on_run_loaded` reads it back.

**C. Save grows unbounded across phases.** Confirm save.json size is < 50KB after a full plant run with one wave. If larger, suspect duplicate entries — check that `_sync_run_save` rebuilds the array rather than appending.

## Acceptance criteria
- [ ] Step 1 passes: save reflects mid-event state with required fields.
- [ ] Step 2 passes: relaunch resumes the wave seamlessly.
- [ ] Save file < 50 KB.
- [ ] No duplicate event entries after multiple background/foreground cycles.

## Out of scope
- Cloud sync.
- Compression (binary save format). Phase 7 if needed.
