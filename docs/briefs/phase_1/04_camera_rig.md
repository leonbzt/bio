# Brief 04 — Touch camera rig

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read `docs/ARCHITECTURE.md` section 7 (input model) before starting.

## Goal
A `CameraRig` scene that wraps a `Camera2D` and handles single-finger pan and two-finger pinch zoom, clamped to the world bounds.

## Outputs (create)
- `scenes/world/camera_rig.tscn`
- `scripts/entities/camera_rig.gd`

## Implementation notes
- The rig is a `Node2D` with a child `Camera2D` (`current = true`, `enabled = true`).
- Use `_unhandled_input(event)` so UI elements consume taps first.
- Pan: on `InputEventScreenDrag` with one active touch, translate the rig by `-event.relative / camera.zoom.x`.
- Pinch: on `InputEventScreenTouch` track `{index → position}` in a dict. When two touches are active, on each `InputEventScreenDrag` compute the new pairwise distance vs previous distance, multiply zoom by the ratio. Clamp zoom to `[0.5, 2.0]`. Reset tracking on touch release.
- Expose two `@export` `Vector2` properties: `world_min` and `world_max`. Clamp the rig's position so the visible viewport stays inside.
- For desktop testing, also handle `InputEventMouseButton` wheel for zoom and `InputEventMouseMotion` with right-button-held for pan. Guard with `OS.has_feature("mobile")` so phones use only touch.

## Acceptance criteria
- [ ] One-finger drag pans smoothly with no jitter.
- [ ] Two-finger pinch zooms about the midpoint of the two fingers (zoom toward the gesture).
- [ ] Zoom clamps at 0.5×–2.0×.
- [ ] Camera position clamps within `world_min`/`world_max`.
- [ ] No `_process` usage — all logic is event-driven.

## Out of scope
- Inertia / momentum.
- Double-tap zoom.
