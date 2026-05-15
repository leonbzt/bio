# Brief 03 — SaveSystem implementation

**Suggested agent**: ChatGPT 5.2 via Copilot. After implementation, route the diff through Claude — this touches the save format and getting it wrong destroys player saves.

You are working on the Bio-Fantasy RPG project. Before writing any code, read:
1. `docs/ARCHITECTURE.md` — sections 3 (`SaveSystem` contract), 9 (versioning), and the schema snippet.
2. `scripts/autoloads/save_system.gd` — stub.
3. `scripts/autoloads/game_state.gd` — for `run_save` / `meta_save` shape.

## Goal
Implement `SaveSystem.save_now()` and `SaveSystem.load_or_create()` to read/write `user://save.json` in the exact JSON schema given in `ARCHITECTURE.md` section 3. Include the versioning skeleton even though no migrations exist yet.

## Outputs (modify)
- `scripts/autoloads/save_system.gd`

## Implementation notes
- Use `FileAccess.open(SAVE_PATH, FileAccess.WRITE)` and `JSON.stringify(dict, "\t")`.
- On `load_or_create()`:
  1. If `user://save.json` does not exist, build a default save (empty `meta`, no active run) and write it.
  2. If it exists, parse it. If `save_version > SAVE_VERSION`, halt with an error (newer save than build). If `save_version < SAVE_VERSION`, run `migrate()`.
  3. Hydrate `GameState.run_save` and `GameState.meta_save` from the parsed dict.
  4. Emit `EventBus.run_loaded(save_version)`.
- `migrate(old, from_version)` is a `match` statement over `from_version`. For now it's empty (only v1 exists). Leave a clear `TODO` comment with the convention: each new version adds a `match` arm that mutates the dict in place and returns it.
- `save_now()` must be safe to call from `tree_exiting` — no awaits, no deferred calls.
- Autosave wiring: connect to `get_tree().on_request_quit` and to `Application.window_minimized` (Android) — call `save_now()` from both. Keep that connection in `_ready()`.

## Acceptance criteria
- [ ] First launch creates `user://save.json` with `save_version: 1` and an empty meta/run.
- [ ] Subsequent launches load the existing save and emit `run_loaded`.
- [ ] Autosave fires on app pause/exit. Verified by checking the file's mtime after backgrounding.
- [ ] A unit test in `tests/test_save_system.gd` constructs a v0-style dict (one field renamed), runs `migrate()`, and confirms the result matches v1 schema.
- [ ] Code does not write to `user://` from anywhere else — search the codebase to confirm.

## Out of scope
- Cloud sync.
- Save encryption.
- Backup rotation (we'll add this in Phase 7).
