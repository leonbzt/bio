# Brief 02 — Step 2: HUD reduction + hero lifetime counter

You are working on the Bio-Fantasy RPG project. Before you write any code, read these files in order:
1. `docs/ARCHITECTURE.md` (contracts — must not violate)
2. `docs/V1_PROTOTYPE.md` (gameplay spec, especially § 2 currencies and § 6 UI principles)
3. `docs/V1_MIGRATION_PLAN.md` (full migration context)
4. `docs/briefs/phase_16/00_phase_16_entry.md` (phase scope + decisions locked)
5. `docs/briefs/phase_16/01_recipe_model_DONE.md` (step 1 changes + carry-over notes)

## Goal

Replace the existing 5-resource HUD with a single huge biomass counter showing **lifetime hero biomass production** (monotonic from plant ticks, decremented only by placement costs — placement costs land in step 04, but the counter field must exist now).

Also disable the per-biome free injection of NUTRIENTS + DECAY in `NutrientSystem` so the bottleneck mechanic from step 1 actually bites.

## Inputs (read-only)

- `docs/V1_PROTOTYPE.md` § 2 (currencies), § 3 (in-run dopamine), § 6 (UI principles)
- `scripts/autoloads/resource_ledger.gd` — existing biomass pool; do not refactor
- `scripts/autoloads/save_system.gd` — bump SAVE_VERSION; no migration path
- `scripts/autoloads/game_state.gd`
- `scripts/systems/growth_system.gd` — biomass production from plant species feeds the new counter
- `scripts/systems/nutrient_system.gd` — disable nutrient + decay injection here
- `scripts/systems/prestige_system.gd` `_reset_run_state()` — needs the new field

## Outputs (create or modify)

| File | What |
|---|---|
| `scenes/ui/hud.tscn` | Rewrite scene tree (see § Scene tree below). |
| `scripts/ui/hud.gd` | Rewrite ~80-120 lines (down from 420). |
| `scripts/autoloads/save_system.gd` | Bump `SAVE_VERSION`. Add `hero_biomass_lifetime_produced: 0.0` to run-save schema. No migration. |
| `scripts/systems/prestige_system.gd` | Add `"hero_biomass_lifetime_produced": 0.0` to `_reset_run_state()` dict. Also add `"cycle_closed": false` (used in step 5; cheap to add now). |
| `scripts/systems/growth_system.gd` | When adding biomass to ResourceLedger inside `_apply_yields`, ALSO add to `run_save.hero_biomass_lifetime_produced` — but ONLY for plant-kingdom species (`species.kingdom_id == &"plantae"`). |
| `scripts/systems/nutrient_system.gd` | In `_on_tick`, remove/comment out the NUTRIENTS + DECAY injection blocks. Leave sunlight alone (unused but harmless). |

## Scene tree (locked layout)

```
HUD (Control, full rect, CanvasLayer-hosted)
├── TopBar (PanelContainer, anchor TOP_WIDE, offset 4/4/4/-)
│   └── Margin (MarginContainer, all margins 8)
│       └── ColumnLayout (VBoxContainer, alignment CENTER)
│           ├── EcosystemNameLabel (Label, font_size 14, color #cccccc)
│           ├── BiomassCounter (Label, font_size 48, color #ffffff, h-alignment CENTER)
│           └── RateLabel (Label, font_size 20, color #88dd88, h-alignment CENTER)
├── PauseButton (Button, anchor TOP_RIGHT, offset -56/8, size 48×32, text "II")
└── TickIndicator (ColorRect, anchor TOP_LEFT, size 6×6, offset 4/4)
```

**Removed**: `Bar`, `Bar/Margin/ResourcesRow`, `AbilitiesBar`, `RecipesButton`, `EventToast`, `IdentityStrip` (its ecosystem-label content moves into `EcosystemNameLabel`).

## Rate computation

Maintain a 10-tick ring buffer in `hud.gd`:

```gdscript
const RATE_WINDOW_TICKS: int = 10
var _rate_history: Array[float] = []
var _last_lifetime_biomass: float = 0.0

func _on_tick(_delta: float) -> void:
    var current: float = float(GameState.run_save.get("hero_biomass_lifetime_produced", 0.0))
    var delta: float = current - _last_lifetime_biomass
    _last_lifetime_biomass = current
    _rate_history.push_back(delta)
    if _rate_history.size() > RATE_WINDOW_TICKS:
        _rate_history.pop_front()
    var per_tick_avg: float = 0.0
    for d in _rate_history:
        per_tick_avg += d
    per_tick_avg /= float(maxi(1, _rate_history.size()))
    var per_sec: float = per_tick_avg * TickClock.tick_hz
    _biomass_label.text = FormatUtils.abbreviate(current)
    _rate_label.text = "+%.1f/s" % per_sec if per_sec > 0.0 else "0.0/s"
```

Don't over-engineer the smoothing.

## Constraints

- Godot 4, GDScript only.
- No new autoloads.
- **No new EventBus signals.** Drive HUD updates from `EventBus.tick` and read `run_save` directly. (Decision: 2026-05-27.)
- Tick-driven, no `_process` for HUD updates.
- `FormatUtils.abbreviate` exists in the codebase — use it for the big number.
- Hero biomass counter MUST NOT decrement when Arthropleura consumes biomass via `consume_input`.
- Remove the HUD's cut-element signal subscriptions cleanly — disconnect or don't connect. No graceful-fallback for missing nodes.

## Acceptance criteria

- [ ] HUD shows ONE big biomass number prominently at top.
- [ ] Below, a smaller rate label updates each tick (e.g., `+8.5/s`).
- [ ] Ecosystem name ("Coal Swamp") shown small in the TopBar.
- [ ] Pause button functional in top-right corner.
- [ ] No 5-resource row, abilities bar, event toast, or recipes button anywhere.
- [ ] Hero biomass counter accumulates as Calamites ticks.
- [ ] Place Arthropleura → global `ResourceLedger.BIOMASS` pool drops, HUD counter does NOT drop.
- [ ] Save round-trip preserves `hero_biomass_lifetime_produced` after SAVE_VERSION bump.
- [ ] After disabling biome N+D injection, placing only Calamites (no Mycorrhizal Network) eventually stalls — nutrients deplete, throttle drops to 0, biomass stops climbing.
- [ ] Code runs in editor without errors.
- [ ] No console errors from cut HUD elements being absent.

## Out of scope

- Placement costs (step 4 deducts from the counter)
- Checkpoint UI (step 4)
- Cycle closure visual (step 5)
- Per-cluster status bars (step 6)
- Removing species panel — keep as-is
- Removing goal banner — keep as-is (stale but harmless)
- Stripping ResourceLedger constants — keep them, just don't bind in HUD
- Starter pools (step 3 will seed N/B/D at 50 each)

## Hand-back

Diffs for all 6 modified files to Leon for Claude review. **Save schema bump is the high-risk area** — verify SAVE_VERSION bump and field init in `_reset_run_state` + `SaveSystem`.

Stretch (defer if long): screenshot the HUD climbing → stalled → resumed. Attach to PR description.
