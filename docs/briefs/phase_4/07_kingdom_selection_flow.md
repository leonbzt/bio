# Brief 07 — Kingdom selection at fresh launch

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `scripts/ui/main_menu.gd` — current Play / Continue / Reset flow.
2. `scripts/systems/prestige_system.gd` — `start_run`, `is_kingdom_unlocked`.

## Goal
Currently the menu's Play and Continue buttons go straight to `world.tscn`, assuming an active plantae run. After Phase 4, two cases:

1. **Resuming a run** (`GameState.is_run_active == true` *and* run state non-empty): Continue button enters that run.
2. **No active run** (post-prestige, or fresh save, or `is_run_active == false`): player must pick a kingdom before entering the world.

Brief 06's prestige screen handles case 2 right after prestige. This brief handles case 2 on cold launch (e.g. player force-killed mid-prestige-screen, or has never played).

## Outputs (modify)
- `scripts/ui/main_menu.gd`
- `scenes/main/main_menu.tscn` — add a "Choose Kingdom" submenu (or re-use the prestige screen as a kingdom-only overlay).

## Approach

Simplest: when the player taps Play (or Continue without an active run), show a kingdom-select dialog. Use the same `prestige_screen.tscn` (brief 06) but in "kingdom-only" mode that skips sections 1 and 2.

To enable this, `prestige_screen.gd` exposes a flag:
```gdscript
@export var skip_to_kingdom_select: bool = false
```
When true: hide sections 1 and 2, show only section 3.

In `main_menu.gd`:
```gdscript
func _on_play_pressed() -> void:
    if _has_active_run():
        get_tree().change_scene_to_file(WORLD_SCENE)
        return
    _open_kingdom_select()


func _on_continue_pressed() -> void:
    if _has_active_run():
        get_tree().change_scene_to_file(WORLD_SCENE)
    else:
        _open_kingdom_select()


func _has_active_run() -> bool:
    var run: Dictionary = GameState.run_save
    if not (run is Dictionary):
        return false
    var tiles: Array = run.get("tiles", [])
    return tiles.size() > 0
```

`_open_kingdom_select()` instances the prestige_screen with `skip_to_kingdom_select = true`, displays it as a popup. When a kingdom is chosen, it calls `PrestigeSystem.start_run(kingdom_id)` and scene-changes to world.

## PrestigeSystem availability from main menu
PrestigeSystem currently lives in `world.tscn`. The main menu doesn't have access. Two options:

**Option A (recommended)**: Promote PrestigeSystem to an autoload. It's small, holds no per-scene state, and would be useful from anywhere. Add to `project.godot` autoload list. Update brief 04's scene wiring to remove the world.tscn node and use the autoload.

**Option B**: Add a temporary PrestigeSystem to main_menu.tscn just for kingdom select. Janky.

Go with Option A. The change to brief 04's output:
- Remove the `PrestigeSystem` node from `world.tscn`.
- Register `scripts/systems/prestige_system.gd` as an autoload named `PrestigeSystem`.
- Adjust internal lookups (`@onready` on TerritorySystem etc.) — none exist; PrestigeSystem talks via EventBus only.

## Acceptance criteria
- [ ] Fresh save → main menu → Play → kingdom-select shows, with only Plantae available (Fungi locked).
- [ ] Selecting Plantae starts a plantae run.
- [ ] If a run is in progress, Play / Continue go directly to world.
- [ ] After prestige + unlocking fungi, kingdom-select shows both.
- [ ] PrestigeSystem accessible from both main menu and world scenes.

## Out of scope
- Kingdom preview screens (icons, descriptions). Phase 7.
- Multi-save slots. MVP is single-save.
