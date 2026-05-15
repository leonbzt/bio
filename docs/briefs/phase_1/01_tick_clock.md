# Brief 01 — TickClock implementation

**Suggested agent**: ChatGPT 5.2 via Copilot.

You are working on the Bio-Fantasy RPG project. Before writing any code, read:
1. `docs/ARCHITECTURE.md` — sections 1, 2, 3 (especially the `TickClock` contract)
2. `scripts/autoloads/tick_clock.gd` — the existing stub. Implement against this; do not change the public interface.
3. `scripts/autoloads/event_bus.gd` — to confirm signal names.

## Goal
Implement `TickClock` so it emits `EventBus.tick(delta_seconds)` at exactly `tick_hz` Hz (default 1.0), with pause/resume and a `force_tick(n)` for offline-progress replay and debug stepping.

## Inputs (read-only)
- `docs/ARCHITECTURE.md`
- `scripts/autoloads/event_bus.gd`

## Outputs (modify)
- `scripts/autoloads/tick_clock.gd` — fill in the implementation behind the existing contract.

## Implementation notes
- Use a `_process(delta)` accumulator. When accumulated time ≥ `1.0 / tick_hz`, emit one tick (and decrement the accumulator). This means slow frames can emit multiple ticks in one frame — that's intended.
- `pause()` should freeze tick emission immediately and emit `EventBus.paused_changed(true)`.
- `force_tick(n)` ignores pause and emits `n` immediate ticks back-to-back. Use the fixed `1.0 / tick_hz` value as `delta_seconds`.
- Do **not** read from `Engine.time_scale` or `Engine.physics_ticks_per_second` — we want our own decoupled simulation clock.

## Acceptance criteria
- [ ] `tick_hz = 1.0` produces exactly ~1 `tick` signal per second when unpaused.
- [ ] `pause()` halts emissions; `resume()` restarts them; both emit `paused_changed`.
- [ ] `force_tick(5)` emits 5 ticks immediately even while paused.
- [ ] No new signals added to `EventBus` (this brief should not modify event_bus.gd).
- [ ] No `_process` logic outside of TickClock — all subscribers will receive via signal.

## Out of scope
- Wiring any system to consume the tick. That belongs to later briefs.
- Persisting `tick_count` to save — that's the SaveSystem's job (brief 03).
