# Brief 07 — Step 7: Prestige reskin + lineage list

You are working on the Bio-Fantasy RPG project. Before you write any code, read:
1. `docs/ARCHITECTURE.md`
2. `docs/V1_PROTOTYPE.md` § 4 (run end), § 5 (Lineage Tree)
3. `docs/briefs/phase_16/00_phase_16_entry.md`

## Goal

When a run ends, replace the existing prestige_screen and evolution_tree_canvas with:
1. A simple "Run complete" screen showing Evolution Points earned + run summary.
2. A flat lineage list (one entry per completed run, most recent at top) replacing the tree canvas.

Also remove the now-stale Coal Gauge goal banner from the world scene.

## Inputs (read-only)

- `scripts/ui/prestige_screen.gd` (current end-of-run UI)
- `scripts/ui/evolution_tree_canvas.gd` (current tree visualization)
- `scripts/autoloads/prestige_system.gd` — `trigger_prestige`, `calculate_prestige_reward`
- `scripts/autoloads/save_system.gd` — meta_save schema
- `scenes/world/world.tscn` (remove goal banner instance)

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/ui/prestige_screen.gd` | Reskin: show `Run #N complete. Biomass produced: X. Reproductions: Y. Cycle closed: yes/no. Evolution earned: +Z.` Single "Begin next run" button → returns to main menu, which auto-launches another run per step 3. |
| `scripts/ui/evolution_tree_canvas.gd` | Rewrite as `RunHistoryList` — vertical VBoxContainer of past runs (most recent at top). Each entry: `Run #N — biomass X — +Y EP — date`. ~80 lines (down from 271). |
| `scripts/autoloads/save_system.gd` | Add `meta_save.lineage_runs: Array` initialization (default empty). Each entry: `{ "run_index": int, "date_unix": int, "biomass": float, "reproductions": int, "cycle_closed": bool, "evolution_earned": int }`. |
| `scripts/autoloads/prestige_system.gd` | Replace `calculate_prestige_reward` formula (see § Reward formula). At end of `trigger_prestige`, append a record to `meta_save.lineage_runs`. |
| `scenes/world/world.tscn` | Remove the `GoalBanner` child instance. Leave the script file on disk (unwired). |

## Reward formula

Replace the existing biomass-based reward with:

```gdscript
static func calculate_prestige_reward(biomass: float, cycle_closed: bool, tier_mult: float = 1.0) -> int:
    var reproductions: int = int(biomass / 100.0)  # 100 biomass = 1 reproduction
    var closure_bonus: int = 50 if cycle_closed else 0
    return int(round((reproductions + closure_bonus) * tier_mult))
```

For v1 prototype, `tier_mult` is always 1.0. The formula matches V1_PROTOTYPE.md § 2 (currencies row 3): Evolution = reproductions × tier_mult + closure bonus.

A full run at 100,000 biomass + cycle closed = 1000 + 50 = **1050 Evolution**.

## Constraints

- No new autoloads.
- No new EventBus signals (reuses existing `prestige_triggered`).
- Goal banner removed from scene tree but file stays on disk (unwired strategy).
- `meta_save.lineage_runs` is new — back-compat handled by `meta_save.get("lineage_runs", [])` everywhere it's read.

## Acceptance criteria

- [ ] Reach 100k hero biomass + cycle closed → prestige screen appears.
- [ ] Screen shows: biomass produced, reproductions, cycle closed status, evolution earned.
- [ ] Click "Begin next run" → returns to main menu → auto-launches a fresh Calamites run (per step 3 flow).
- [ ] `meta_save.lineage_runs` grows by 1 entry per completed run; verified after at least 2 runs.
- [ ] Evolution tree menu (if accessed from anywhere) shows the run-history list, not the old tree graph.
- [ ] Goal banner no longer visible in world.tscn.
- [ ] Reward formula matches spec: 100k biomass + closure = 1050 EP.
- [ ] Save round-trip preserves `meta_save.lineage_runs`.

## Out of scope

- Real tree visualization (graph nodes + edges) — v2+
- Tier list / tier multipliers — v2+
- Failed-run resolution — runs that don't reach 100k just stay on world until player decides to prestige (no auto-fail in v1)
- Audio celebration sting (defer)
- Run summary statistics beyond biomass + reproductions (defer)

## Hand-back

Diff for 5 files to Leon for Claude review. The save-schema addition (`lineage_runs`) is the risk area — verify back-compat for runs saved before this field existed.
