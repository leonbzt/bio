# Tests

GUT-based (Godot Unit Test) tests for autoloads and systems.

## Setup
1. Install the **GUT** addon via Godot's AssetLib (`Gut` by Butch Wesley).
2. Enable in **Project → Project Settings → Plugins**.
3. Open the GUT panel, point it at `res://tests/`.

## Naming
- One test file per autoload or system: `test_<thing>.gd`.
- Class extends `GutTest`.
- Each test method begins with `test_`.

## Scope
- Unit tests for autoloads: `ResourceLedger`, `SaveSystem`, `TickClock` math.
- Integration tests for system contracts where realistic.
- No tests for UI scenes (manual / device testing).

## Running on Android
GUT runs in the editor. For Android-specific regressions (save paths, app pause autosave), test manually on device with debug builds.
