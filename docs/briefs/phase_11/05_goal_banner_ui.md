# Brief 05 — Soft-goal banner UI + prestige-button highlight

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — mobile layout.

Read first:
1. `docs/briefs/phase_11/04_per_run_goal_system.md` (must land first).
2. `scenes/world/hud.tscn` — where the banner attaches.
3. `scripts/ui/hud.gd` — existing HUD logic.
4. Wherever the prestige-screen entry button lives (HUD has a "Prestige" button somewhere; verify in scene).

## Goal
Two pieces:
1. **Goal banner** at the top of the HUD showing "<display_text>: N / target" with a progress bar.
2. **Prestige-button highlight**: when `goal_met` fires, the prestige entry button gets a pulsing tint to congratulate the player and suggest prestige is now meaningful.

Banner is non-modal, always-visible during an active run. Empty if `get_active_goal()` is null (e.g., legacy run from before brief 04 shipped).

## Scene changes

### `scenes/world/hud.tscn`

Add at top of HUD VBox (above existing resource displays):

```
GoalBanner (PanelContainer)
├── custom_minimum_size = Vector2(0, 36)
└── HBox (HBoxContainer)
    ├── GoalText (Label, "Reach 30 tiles colonized")
    ├── Spacer
    └── ProgressLabel (Label, "12 / 30")
└── ProgressBar (ProgressBar, anchored bottom, height 4)
```

The progress bar is overlaid on the panel; alternative is to add a `ProgressBar` as a sibling above/below the HBox.

If the existing HUD already has a top-area HBox for kingdom/niche badges (Phase 8 added these), insert the GoalBanner *above* that. Players see goal first, then their identity.

## Script — `scripts/ui/goal_banner.gd` (new)

Attach to the GoalBanner node.

```gdscript
extends PanelContainer

@onready var _goal_text: Label = $HBox/GoalText
@onready var _progress_label: Label = $HBox/ProgressLabel
@onready var _progress_bar: ProgressBar = $ProgressBar

const MET_TINT: Color = Color(0.9, 0.85, 0.3, 1.0)
const NORMAL_TINT: Color = Color(0.3, 0.3, 0.35, 1.0)


func _ready() -> void:
    EventBus.goal_progress_changed.connect(_on_progress_changed)
    EventBus.goal_met.connect(_on_goal_met)
    EventBus.run_started.connect(_on_run_started)
    EventBus.run_loaded.connect(func(_v): _refresh_initial())
    _refresh_initial()


func _refresh_initial() -> void:
    var goal: PerRunGoalData = RunGoalSystem.get_active_goal()
    if goal == null:
        visible = false
        return
    visible = true
    _goal_text.text = goal.display_text
    var value: float = RunGoalSystem.get_progress()
    _progress_label.text = "%d / %d" % [int(value), int(goal.target)]
    _progress_bar.max_value = goal.target
    _progress_bar.value = value
    _apply_tint(RunGoalSystem.is_met())


func _on_progress_changed(progress: Dictionary) -> void:
    var value: float = float(progress.get("value", 0.0))
    var target: float = float(progress.get("target", 0.0))
    _progress_label.text = "%d / %d" % [int(value), int(target)]
    _progress_bar.max_value = target
    _progress_bar.value = value


func _on_goal_met() -> void:
    _apply_tint(true)
    # Brief congratulatory flash. 2-second tween.
    var tween := create_tween()
    tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
    tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)


func _on_run_started(_kingdom: StringName) -> void:
    _refresh_initial()


func _apply_tint(met: bool) -> void:
    var sb := StyleBoxFlat.new()
    sb.bg_color = MET_TINT if met else NORMAL_TINT
    sb.corner_radius_top_left = 4
    sb.corner_radius_top_right = 4
    sb.corner_radius_bottom_left = 4
    sb.corner_radius_bottom_right = 4
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 4
    sb.content_margin_bottom = 4
    add_theme_stylebox_override("panel", sb)
```

## Prestige-button highlight

Find the HUD's prestige entry button (the one that navigates to the prestige screen). Subscribe to `EventBus.goal_met`:

```gdscript
@onready var _prestige_button: Button = $PrestigeButton

func _ready() -> void:
    # ... existing wiring ...
    EventBus.goal_met.connect(_on_goal_met)
    EventBus.run_started.connect(func(_k): _reset_prestige_glow())
    _reset_prestige_glow()


func _on_goal_met() -> void:
    _start_prestige_glow()


func _start_prestige_glow() -> void:
    var tween := create_tween().set_loops()
    tween.tween_property(_prestige_button, "modulate", Color(1.0, 0.95, 0.55, 1.0), 0.8)
    tween.tween_property(_prestige_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)
    _prestige_button.set_meta("_glow_tween", tween)


func _reset_prestige_glow() -> void:
    var existing: Variant = _prestige_button.get_meta("_glow_tween", null)
    if existing is Tween:
        (existing as Tween).kill()
    _prestige_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
    _prestige_button.remove_meta("_glow_tween")
```

(Adapt to the actual HUD structure — the prestige entry might be elsewhere; brief 04 doesn't change the prestige flow itself.)

## Mobile considerations

- Banner is 36px tall; comfortable on 360×640.
- Touch-target: the banner is non-interactive (display only). No click handler.
- Tinted highlight + pulse modulate are both cheap; no per-frame cost.

## Acceptance criteria
- [ ] On fresh-load of an active run with a goal, banner shows "<goal text>: 0 / target" with empty progress bar.
- [ ] Colonize a tile → progress bar fills, label updates.
- [ ] Reach target → banner tint flips to yellow-ish, brief flash; prestige button starts pulsing.
- [ ] Prestige → new run → banner shows a fresh goal; prestige button glow clears.
- [ ] Legacy run (no `goal_id` set) → banner is hidden, not crashing.
- [ ] Mobile screen at 360×640: banner doesn't push other HUD elements off-screen.

## Out of scope
- Goal-met → discovery log entry ("you reached a goal for the first time"). Could be added in Phase 12 by authoring a new entry; defer.
- Goal-met → bonus EP reward. The roadmap deliberately keeps soft-goals soft; rewards would change incentive structure.
- Multi-goal display (one goal per run at v1).
- Tap-to-see-goal-details tooltip (defer).
