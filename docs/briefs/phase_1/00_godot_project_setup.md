# Brief 00 — Godot project setup

**Suggested agent**: do this yourself, with ChatGPT as fallback for troubleshooting only. No code generation needed.

## Goal
Stand up the Godot 4 project in the existing repository so Godot recognizes the folder structure already in place.

## Steps

1. Install **Godot 4** (latest stable; pick the standard "Godot Engine" build, not the .NET / Mono one — we're GDScript-only per `docs/ARCHITECTURE.md`).
2. Launch Godot → **Import** → select the project root `/home/leon/1_projects/2_bio/`. When prompted for a name, use `bio`. Godot creates `project.godot` here.
3. Open **Project → Project Settings** and set:
   - **Display → Window → Size**:
     - Viewport Width = `360`
     - Viewport Height = `640`
   - **Display → Window → Stretch**:
     - Mode = `canvas_items`
     - Aspect = `keep`
   - **Display → Window → Handheld**:
     - Orientation = `portrait`
   - **Application → Run → Main Scene** = leave empty for now; brief 05 will set this.
4. **Project → Project Settings → Autoload**: register these scripts (already stubbed in `scripts/autoloads/`). Order matters — register top-down:
   1. `event_bus.gd` → name `EventBus`
   2. `tick_clock.gd` → name `TickClock`
   3. `resource_ledger.gd` → name `ResourceLedger`
   4. `game_state.gd` → name `GameState`
   5. `save_system.gd` → name `SaveSystem`
   6. `audio_manager.gd` → name `AudioManager`
5. **Editor → Manage Export Templates** → download the matching Android template.
6. **Project → Export** → add an Android preset. Use a debug keystore (Godot can generate one). Set the package name (e.g. `com.leon.bio`). Min SDK = 24.
7. Connect your Android phone via USB with developer mode on; click the green Android icon in the editor toolbar to "Run on Remote Android Device". You should see an empty grey screen on your phone.

## Acceptance criteria
- [x] `project.godot` exists at repo root.
- [x] All six autoloads appear in **Project Settings → Autoload** in the listed order.
- [x] Game launches on an Android device showing an empty viewport, no errors in the output panel.

## Out of scope
- Any gameplay code. That comes in the later briefs.
