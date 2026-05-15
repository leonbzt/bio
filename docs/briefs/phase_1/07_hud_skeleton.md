# Brief 07 — HUD skeleton

**Suggested agent**: ChatGPT 5.2 via Copilot. Visual styling can be passed to Kilo for polish later.

Read `docs/ARCHITECTURE.md` section 3 (`ResourceLedger` signal `resource_changed`) and section 6 (HUDLayer location in scene tree).

## Goal
A persistent HUD over the world scene that displays current resource amounts and a tick indicator. The HUD listens to `EventBus` and updates reactively — it never polls.

## Outputs (create)
- `scenes/ui/hud.tscn` — `Control` with a top bar showing resource readouts.
- `scripts/ui/hud.gd` — connects to `EventBus.resource_changed` and `EventBus.tick`.

## Layout
- Top of screen, anchored full-width, fixed height (e.g. 64px).
- Five labels side by side for: biomass, nutrients, sunlight, decay, spores. Use simple text "🌱 0" style — but no emoji, just `"Biomass: 0"` etc. Initial values pulled from `ResourceLedger.get_amount(id)` in `_ready()`.
- A tick indicator (small circle that pulses each `tick` signal — scale 1.0→1.2→1.0 over 200ms via `create_tween()`).

## Implementation notes
- Use a `Dictionary` `_labels: { StringName: Label }` to route updates by resource id. On `resource_changed(id, amt)`, look up the label and update its text.
- Format amounts with `"%d"` (integers) for now; we'll add abbreviated notation (`"1.2K"`) in Phase 2.
- The HUD scene should be added under `HUDLayer (CanvasLayer)` in `world.tscn` (brief 06 left this empty).

## Acceptance criteria
- [ ] All five resources display, starting at 0.
- [ ] Adding biomass via the debug console (`ResourceLedger.add(&"biomass", 50)`) updates the label immediately.
- [ ] Tick indicator pulses once per second while unpaused.
- [ ] No `_process` usage in `hud.gd`.

## Out of scope
- Resource cap warnings, abbreviated notation, settings/pause buttons. Later phases.
