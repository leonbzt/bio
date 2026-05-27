# Brief 05 — Step 5: Cycle closure detection

You are working on the Bio-Fantasy RPG project. Before you write any code, read:
1. `docs/ARCHITECTURE.md`
2. `docs/V1_PROTOTYPE.md` § 4 (cycle closure), § 4 closing event ("the climactic run moment")
3. `docs/briefs/phase_16/00_phase_16_entry.md`

## Goal

Detect when the trophic cycle is closed (all 3 species placed, all 3 pools non-empty for ≥ 5 consecutive ticks) and apply a ×1.5 throughput bonus to all species. Visible cue: HUD biomass counter pulses gold for 2 seconds.

This is the climactic moment of the run per V1_PROTOTYPE.md § 4.

## Inputs (read-only)

- `scripts/systems/growth_system.gd`
- `scripts/autoloads/territory_system.gd` — need access to per-kingdom tile counts
- `scripts/autoloads/resource_ledger.gd` — pool reads
- `scripts/ui/hud.gd` — pulse the counter

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/autoloads/event_bus.gd` | Add signal `cycle_closed()`. List in ARCHITECTURE.md. |
| `scripts/systems/growth_system.gd` | Detect cycle-closed state each tick. When detected, set `run_save.cycle_closed = true`, emit `EventBus.cycle_closed` once, persist via `SaveSystem.save_now`. In `_apply_yields`, multiply `base_mult` by 1.5 when `run_save.cycle_closed` is true. |
| `scripts/ui/hud.gd` | On `EventBus.cycle_closed`, tween BiomassCounter `modulate` to gold (Color(1.3, 1.15, 0.6)) for 0.3s, hold 1.4s, return to white in 0.3s. |
| `scripts/autoloads/territory_system.gd` | If `get_kingdom_tile_count(kingdom_id)` doesn't exist, add a thin wrapper around existing tile-tracking. |

## Detection algorithm

Add to GrowthSystem `_on_tick` after the per-species yield loop:

```gdscript
const CYCLE_CLOSURE_CONFIRM_TICKS: int = 5
var _closure_ticks_held: int = 0

func _check_cycle_closure() -> void:
    if bool(GameState.run_save.get("cycle_closed", false)):
        return  # idempotent — fires once
    var has_plant: bool = _territory.get_kingdom_tile_count(&"plantae") > 0
    var has_fungus: bool = _territory.get_kingdom_tile_count(&"fungi") > 0
    var has_animal: bool = _territory.get_kingdom_tile_count(&"animals") > 0
    if not (has_plant and has_fungus and has_animal):
        _closure_ticks_held = 0
        return
    if ResourceLedger.get_amount(ResourceLedger.NUTRIENTS) <= 0.0 or \
       ResourceLedger.get_amount(ResourceLedger.BIOMASS) <= 0.0 or \
       ResourceLedger.get_amount(ResourceLedger.DECAY) <= 0.0:
        _closure_ticks_held = 0
        return
    _closure_ticks_held += 1
    if _closure_ticks_held >= CYCLE_CLOSURE_CONFIRM_TICKS:
        GameState.run_save["cycle_closed"] = true
        EventBus.cycle_closed.emit()
        SaveSystem.save_now()
```

The 5-tick confirmation prevents flicker from transient pool emptying.

## Constraints

- One new EventBus signal (`cycle_closed`). List in ARCHITECTURE.md.
- `get_kingdom_tile_count(kingdom_id)` — verify or add. If TerritorySystem already tracks `_occupants_by_coord` or similar, a simple aggregation works.
- ×1.5 multiplier applies to all species' production (whole ecosystem accelerates).
- No new autoloads.
- Cycle closure is **monotonic** — once true, stays true. No un-closure in v1.

## Acceptance criteria

- [ ] Place Calamites + Mycorrhizal Network + Arthropleura, wait for resource flow → `cycle_closed` fires once (after ~5 ticks of stable flow).
- [ ] HUD BiomassCounter pulses gold for ~2s.
- [ ] Hero biomass rate visibly increases ~50% after closure (×1.5 multiplier).
- [ ] Save/load preserves the cycle_closed flag.
- [ ] If only 2 of 3 kingdoms are placed, cycle_closed does NOT fire.
- [ ] If a pool empties for one tick (transient), cycle_closed does NOT fire — needs 5 consecutive ticks of stability.
- [ ] After cycle_closed = true, a transient pool empty does NOT un-close (flag stays true).
- [ ] Code runs in editor without errors.

## Out of scope

- Audio sting on closure (defer)
- World canvas particle effect (defer to polish)
- Un-closure / closure-loss mechanic (not in v1)
- Multiple closure tiers (e.g., bigger bonus for diverse webs) — v2+

## Hand-back

Diff for the 4 modified files to Leon for Claude review. Verify `get_kingdom_tile_count` is wired up correctly if it didn't exist before.
