# Brief 05 — Save robustness: backup rotation + corruption recovery

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — touches save format.

Read first:
1. `scripts/autoloads/save_system.gd` — current load/save flow.
2. `docs/ARCHITECTURE.md` § 3 (`SaveSystem` contract).
3. `tests/test_save_system.gd`.

## Goal
Survive two failure modes that real-world players will hit:
1. **Mid-write power loss**: the device kills the app while `save_now()` is partway through writing the JSON, leaving a truncated file. Without backups, the player loses all progress.
2. **Schema corruption**: a future bug writes invalid JSON. Without a fallback, the game won't boot until the save is hand-edited.

Solution: write through a temp file, rotate two backup slots.

## Outputs (modify)
- `scripts/autoloads/save_system.gd`
- `tests/test_save_system.gd`

## Implementation

### Constants
```gdscript
const SAVE_PATH: String = "user://save.json"
const TEMP_PATH: String = "user://save.json.tmp"
const BACKUP_PATH: String = "user://save.json.bak"
```

### `save_now()` — write-temp-then-rename pattern
```gdscript
func save_now() -> void:
    var save_dict := _build_save_dict()
    var json: String = JSON.stringify(save_dict, "\t")

    var tmp := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
    if tmp == null:
        push_error("SaveSystem: failed to open temp file %s" % TEMP_PATH)
        return
    tmp.store_string(json)
    tmp.close()

    # Rotate: current -> backup, then temp -> current.
    if FileAccess.file_exists(SAVE_PATH):
        if FileAccess.file_exists(BACKUP_PATH):
            DirAccess.remove_absolute(BACKUP_PATH)
        DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)
    DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
```

### `load_or_create()` — try current, then backup, then default
```gdscript
func load_or_create() -> void:
    var data: Dictionary = _try_load(SAVE_PATH)
    if data.is_empty():
        data = _try_load(BACKUP_PATH)
        if not data.is_empty():
            push_warning("SaveSystem: primary save corrupted, restored from backup")
    if data.is_empty():
        # No file or both corrupted — fresh save.
        data = _build_default_save()
        _write_save(data)
        GameState.meta_save = data["meta"]
        GameState.run_save = data["run"]
        GameState.last_save_unix = int(Time.get_unix_time_from_system())
        EventBus.run_loaded.emit(data["save_version"])
        return
    _apply_loaded(data)


func _try_load(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var text: String = file.get_as_text()
    file.close()
    var parser := JSON.new()
    if parser.parse(text) != OK:
        push_warning("SaveSystem: JSON parse failed for %s" % path)
        return {}
    var raw: Variant = parser.data
    if not (raw is Dictionary):
        return {}
    var data: Dictionary = raw as Dictionary
    var save_version := int(data.get("save_version", 0))
    if save_version > SAVE_VERSION:
        push_error("SaveSystem: %s has newer save_version (%d > %d)" % [path, save_version, SAVE_VERSION])
        return {}
    if save_version < SAVE_VERSION:
        data = migrate(data, save_version)
        data["save_version"] = SAVE_VERSION
    return data


func _apply_loaded(data: Dictionary) -> void:
    GameState.meta_save = data.get("meta", {})
    GameState.run_save = data.get("run", {})
    GameState.last_save_unix = int(data.get("saved_at_unix", 0))
    EventBus.run_loaded.emit(int(data.get("save_version", SAVE_VERSION)))
```

### `reset_save()` — also delete backup
```gdscript
func reset_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
    if FileAccess.file_exists(BACKUP_PATH):
        DirAccess.remove_absolute(BACKUP_PATH)
    if FileAccess.file_exists(TEMP_PATH):
        DirAccess.remove_absolute(TEMP_PATH)
    # ... rest of existing reset flow (build default, hydrate GameState, emit run_loaded)
```

## Tests
Add to `test_save_system.gd`:

```gdscript
func test_corrupted_primary_falls_back_to_backup() -> void:
    # This test requires file IO. Use FileAccess directly in test setup.
    # Set up a valid backup + corrupted primary, call load_or_create, assert hydrated.
    # Simplified version — just test the load path with mock paths if FileAccess is awkward.
    pass  # implement if test framework allows
```

(GUT's file IO is awkward; this test may be skipped in favor of manual verification — see acceptance criteria.)

## Acceptance criteria
- [ ] First save writes both `save.json` and (after a second save) `save.json.bak`.
- [ ] After 3 saves, only `save.json` and `save.json.bak` exist on disk — no leftover `save.json.tmp`.
- [ ] Manual test: corrupt `save.json` by editing it to `{INVALID}`, relaunch. Game boots, warns in logcat about corruption, continues from backup state.
- [ ] If both files corrupt: game boots with a fresh default save, doesn't crash.
- [ ] Reset Save deletes all three files.

## Out of scope
- Cloud backup. Local-only.
- More than two backup slots. Two is enough to survive one bad write.
- Cryptographic verification. Phase 8+.
