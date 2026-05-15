# Technical Scope

## Locked stack
See `ARCHITECTURE.md` section 1 for the canonical table. Summary:

| | |
|---|---|
| Engine | Godot 4 (latest stable) |
| Language | GDScript |
| Orientation | Portrait |
| Resolution | 360×640 base, stretched |
| World | 32×48 fixed tile grid |
| MVP platform | Android only (iOS in Phase 7 if feasible) |
| Min Android API | 24 (Android 7.0) |

## MVP Constraints

### Include
- 2D retro visuals (16×16 tiles, pixel-art organisms)
- single-player only
- one map (32×48)
- three kingdoms: Plantae → Fungi → Symbiosis (hybrid)
- one active ability per kingdom
- one ecological event per kingdom
- passive progression with offline catch-up (8h cap)
- save/load with versioning + migration scaffold from day 1
- evolution tree (5–10 nodes)

### Avoid initially
- multiplayer
- procedural world generation
- realistic ecosystem simulation
- advanced AI
- massive maps
- online economy
- complex animation systems
- cloud sync (Phase 7 maybe)
- iOS (Phase 7 if Mac available)
- localization beyond English (deferred; brief 05 sets up STRINGS dict for later)

## Architecture goals
- modular systems communicating via EventBus only
- data-driven content via Godot `Resource` (.tres)
- simple readable GDScript, beginner-friendly
- tick-driven simulation, not per-frame
- two-tier save (run + meta) with versioned schema

## Out-of-scope and explicit non-goals
- No real-time multiplayer ever in this codebase.
- No 3D.
- No native Android plugins (cuts off many advanced features but keeps build simple).
- No game-as-a-service economy.

## Performance targets
- 60fps on a mid-range Android (e.g. Pixel 4a) during active play.
- < 5% CPU on idle/check-in screens.
- Cold start < 3s on mid-range Android.
- Save file < 1MB even at endgame.
- APK size < 50MB.

These are checked in Phase 7 with `monitor` overlay + Android Studio profiler.
