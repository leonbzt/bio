# Brief 06 — Evolution tree UI + prestige flow

**Suggested agent**: ChatGPT 5.2 via Copilot. Visual polish (spacing, colors) → Kilo afterwards.

Read first:
1. `scripts/systems/prestige_system.gd` (brief 04) — public API.
2. `data/evolution_tree/*.tres` — node ids and prerequisites.
3. `scenes/main/main_menu.tscn` — to wire prestige access from the menu.
4. `scenes/ui/hud.tscn` — to add a "Prestige" pause-menu access from the HUD.

## Goal
Two new UI surfaces:
1. **Pause/options popup on HUD** — small button (top-left or top-right corner) that opens a popup with "Prestige" and "Main Menu" buttons.
2. **Prestige + Tree screen** — modal scene showing the prestige summary, then the evolution tree, with kingdom selection at the bottom.

## Outputs (create)
- `scenes/ui/pause_menu.tscn` + `scripts/ui/pause_menu.gd`
- `scenes/ui/prestige_screen.tscn` + `scripts/ui/prestige_screen.gd`
- Small modifications to `hud.tscn` (add a corner button to open pause), and `world.tscn` (instance pause overlay into HUDLayer).

## Pause menu

A small overlay anchored top-left.

```
PauseMenu (Control, full-screen, mouse_filter=STOP, hidden by default)
├── Backdrop (ColorRect, full-screen, modulate alpha 0.5)
└── Panel (PanelContainer, centered, ~280×200)
    └── VBoxContainer
        ├── TitleLabel ("Paused")
        ├── PrestigeButton  ("Prestige (earn N EP)")
        ├── ResumeButton    ("Resume")
        └── ResetSaveButton ("Reset Save")
```

Behavior:
- Toggle visibility via a button on HUD (use a small ColorRect with a label "≡" or just "MENU" anchored top-left).
- When opened: pause via `TickClock.pause()`. When closed: `TickClock.resume()`.
- "Prestige (earn N EP)" — label uses `PrestigeSystem.get_pending_reward()`; updates on `_ready` and whenever popup opens.
- Tap Prestige → opens `prestige_screen.tscn` as an overlay; this screen handles `trigger_prestige` itself.
- Tap Reset Save → confirmation dialog → `SaveSystem.reset_save()` → return to main menu.

## Prestige screen

A full-screen overlay. Three sections, top to bottom:

### Section 1 — Summary
- "Prestige" header
- "This run earned: N EP" — from `PrestigeSystem.get_pending_reward()`
- "Total biomass earned: X" — from `run.statistics.total_biomass_earned`
- A "Confirm Prestige" button. Tapping it calls `PrestigeSystem.trigger_prestige()` and transitions to Section 2.

### Section 2 — Tree
Visible after prestige is triggered. Shows every node:

```
Tree (HFlowContainer or GridContainer, 2 columns)
└── NodeButton (per evolution node)
    ├── Title label
    ├── Cost label ("3 EP")
    ├── Status indicator (locked/unaffordable/affordable/owned)
```

For each node:
- **Owned** (already unlocked): button disabled, label "✓ Owned" (or just dim).
- **Locked** (prereqs not met): button disabled, label "Locked".
- **Unaffordable** (prereqs met, balance < cost): button disabled, label shows cost.
- **Affordable** (prereqs met, balance ≥ cost): button enabled, label shows cost.

Tapping an affordable button calls `PrestigeSystem.purchase_node(id)`. Refresh all node statuses + the balance display on success.

Display the balance prominently: "Balance: N EP" at the top of section 2.

### Section 3 — Kingdom select
Below the tree. One button per entry in `meta.unlocked_kingdoms`:
- "Begin run as Plantae" — always available.
- "Begin run as Fungi" — appears only after `unlock_fungi` purchased; for Phase 4 the button works but the resulting run still plays as plantae mechanically (note this in a small subtitle: "Fungi mechanics coming soon"). The button still calls `PrestigeSystem.start_run(&"fungi")`.

After kingdom is chosen: close the overlay, return to `world.tscn` for a fresh run. If world.tscn is already loaded, the `run_started` signal triggers re-hydration in all systems; otherwise scene-change to world.tscn.

## HUD pause button
Add to hud.tscn:
```
PauseButton (Button, anchored top-left, offset_left=8, offset_top=8, offset_right=64, offset_bottom=40)
  text = "Menu"
```
Pressed → opens pause menu.

## Implementation notes for prestige_screen.gd
```gdscript
extends Control

@onready var _prestige_system: Node = get_node("/root/...")  # find PrestigeSystem at runtime
# OR: pass via a setup() method when this scene is instanced
```

Since PrestigeSystem isn't an autoload, the prestige_screen needs a reference. Cleanest: when opening, call `prestige_screen.setup(prestige_system_node)`. Or: use group lookup `get_tree().get_first_node_in_group("prestige_system")`. **Add `PrestigeSystem` to the group `"prestige_system"` in world.tscn** (`groups = ["prestige_system"]` in the node's `_ready`).

## Acceptance criteria
- [ ] HUD shows a Menu button top-left.
- [ ] Tapping Menu pauses ticks and opens the pause overlay; pulse stops; HUD numbers freeze.
- [ ] Closing the pause menu resumes ticks.
- [ ] Tapping Prestige in the pause menu opens the prestige screen.
- [ ] Pending reward displayed correctly (verify by running for a few minutes and checking against `floor(sqrt(total_biomass_earned/10))`).
- [ ] Confirming prestige clears run state; the prestige screen transitions to the tree section.
- [ ] Tree section correctly shows locked/affordable/owned states.
- [ ] Buying an affordable node deducts EP and immediately updates the tree.
- [ ] After buying `unlock_fungi`, a "Begin run as Fungi" button appears in the kingdom section.
- [ ] Tapping a kingdom button starts a new run as that kingdom.

## Out of scope
- Animations between sections (snap is fine).
- Visual tree branches connecting nodes (text-only is fine; Phase 7 polish).
- Confirmation modal for prestige (the explicit Confirm button is enough).
