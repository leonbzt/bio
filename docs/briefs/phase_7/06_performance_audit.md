# Brief 06 — Performance audit + targeted optimizations

**Suggested agent**: do this yourself with ChatGPT as a sounding board for fixes. Profiling can't be agent-automated.

Read first:
1. `docs/TECHNICAL_SCOPE.md` — performance targets: 60fps mid-range Android, <5% idle CPU, cold start <3s.
2. `scripts/systems/growth_system.gd` and `nutrient_system.gd` — most expensive per-tick code.

## Goal
Measure actual perf on the device, identify the worst hot spots, fix only what fails the targets. Don't optimize speculatively.

## Procedure

### Step 1 — Establish baseline
On your test device (Pixel-class mid-range Android), build a release APK. Avoid debug builds for measurement — debug performance is misleading.

```
Project → Export → Android preset → Export Project (uncheck "Export with Debug")
```

Install on the device. Launch and play through a full plant + fungi + symbiosis cycle. Record:
- **Cold start time**: from tapping the icon to seeing the main menu. Stopwatch is fine.
- **FPS during gameplay**: enable Godot's Monitor overlay (Project Settings → Debug → Settings → Profile Frames On Foreground = on). Or use `adb shell dumpsys gfxinfo <package>` for a more accurate read.
- **Idle CPU**: leave the app open on the main menu for 5 minutes. Check `adb shell top -p $(pidof <package>)`.
- **Save file size**: after a full symbiosis run with 50+ tiles and one wave defeated.

### Step 2 — Check against targets

| Target | Threshold | Actual |
|---|---|---|
| Cold start | < 3s | ___ |
| In-game FPS (active play, 30+ owned tiles) | ≥ 55fps avg | ___ |
| Idle CPU (main menu) | < 5% | ___ |
| Save size | < 1MB | ___ |
| APK size | < 50MB | ___ |

If everything passes: skip step 3, proceed to brief 07. If anything fails, debug:

### Step 3 — Common hot spots and fixes

#### FPS drop on tick
GrowthSystem and NutrientSystem iterate every owned tile each tick. With many owned tiles, this can hitch.

- **Diagnose**: add `print(Time.get_ticks_msec())` at the start of each `_on_tick`. If any system exceeds 5ms consistently, it's a problem.
- **Fix**: cache `_territory.get_surface_owned_coords()` result instead of recomputing each tick. Invalidate cache on `tile_colonized` / `tile_lost`.

#### FPS drop during herbivore wave
HerbivoreManager processes each herbivore per tick, doing nearest-tile distance calculations. With 3 spawn_count this is fine; if you've tuned higher, it can be expensive.

- **Fix**: cap simultaneous herbivores. Or: precompute the nearest-target distance every N ticks, not every tick.

#### Slow cold start
The asset import phase on first install can take 5–10s. After import, cold start should be 1–2s.

- **Diagnose**: separate first launch from subsequent launches.
- **Fix (if subsequent launches are slow)**: defer non-critical autoload work. AudioManager doesn't need to load streams in `_ready` — load on demand.

#### Large save file
A run with many tiles + many corpses + many active events writes a long JSON. Goal is <1MB.

- **Diagnose**: `wc -c save.json`.
- **Fix**: drop redundant data. Each tile entry shouldn't carry a full `data: {}` if it's empty. Each organism shouldn't carry empty `data` either.

#### Large APK
- **Diagnose**: `ls -lh build/your.apk`.
- **Fix**: in export preset, ensure unused exporter features are disabled. Disable engine modules you don't use (3D physics, etc.) via custom build.

### Step 4 — Re-measure
After any fix, re-export and re-measure. Don't ship without verifying the fix worked AND didn't regress something else.

## Acceptance criteria
- [ ] All five thresholds in Step 2 pass on the actual test device.
- [ ] Any optimization committed has measurements before AND after, recorded in the commit message.
- [ ] No regressions: full symbiosis smoke test (Phase 6 brief 07) still passes.

## Out of scope
- Frame-time hitching during the offline-replay burst. That's a cold-start one-shot; not user-visible during play.
- WebGL / desktop optimization. Mobile-only target.
- GPU profiling. CPU is the bottleneck for this game's scale.
