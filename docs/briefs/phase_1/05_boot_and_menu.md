# Brief 05 — Boot scene and main menu

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read `docs/ARCHITECTURE.md` sections 5–6 before starting.

## Goal
Build the initial app flow: `boot.tscn` → `main_menu.tscn` → `world.tscn`. Boot is responsible for calling `SaveSystem.load_or_create()` and showing a splash for at least 0.5s.

## Outputs (create)
- `scenes/main/boot.tscn` with `scripts/ui/boot.gd`
- `scenes/main/main_menu.tscn` with `scripts/ui/main_menu.gd`

## Set in Project Settings
- **Application → Run → Main Scene** = `res://scenes/main/boot.tscn`

## Implementation notes
### `boot.gd`
- In `_ready()`: call `SaveSystem.load_or_create()`, wait `0.5s` via `await get_tree().create_timer(0.5).timeout`, then `get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")`.
- The scene should display the game title and a small "loading" label centered.

### `main_menu.gd`
- Three buttons: **Play**, **Continue**, **Reset Save**.
- `Play` and `Continue` both call `get_tree().change_scene_to_file("res://scenes/world/world.tscn")`. (They diverge later when meta-progression matters; for now both behave the same.)
- `Reset Save` shows a confirmation dialog, deletes `user://save.json`, then reloads the menu scene.
- All button label text comes from a `const STRINGS := { ... }` dictionary at the top of the script — no inline string literals in the button setup. (Sets up localization later.)

## Acceptance criteria
- [ ] Cold launch shows boot for 0.5s, then main menu.
- [ ] Save is loaded before the menu becomes interactive (verified by logging `run_loaded`).
- [ ] All three menu buttons work as described.
- [ ] No autoload registration changes (those happened in brief 00).

## Out of scope
- Settings menu, credits, audio sliders. Phase 7.
- New-game vs continue divergence. Phase 4.
