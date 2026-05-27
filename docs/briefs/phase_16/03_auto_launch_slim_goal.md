# Brief 03 — Step 3: Auto-launch + slim RunGoalSystem

You are working on the Bio-Fantasy RPG project. Before you write any code, read:
1. `docs/ARCHITECTURE.md`
2. `docs/V1_PROTOTYPE.md` § 4 (the run)
3. `docs/briefs/phase_16/00_phase_16_entry.md`

## Goal

Bypass the starting-species picker and world-map ecosystem picker. From the main menu, "Start Run" goes directly to `world.tscn` with Calamites as the locked hero in the Coal Swamp wetland biome.

Slim `RunGoalSystem` from 176 lines to ~30 — it just emits `goal_met` when `hero_biomass_lifetime_produced ≥ 100_000` AND `run_save.cycle_closed` is true.

Also seed the global pools with 50 units each (N, B, D) at run start to bootstrap the cycle (V1_PROTOTYPE.md § 4 calls for this).

## Inputs (read-only)

- `scripts/ui/main_menu.gd`
- `scripts/ui/starting_species_picker.gd` (unwiring, not deleting)
- `scripts/ui/world_map.gd` (unwiring)
- `scripts/autoloads/prestige_system.gd` `start_run` — invoke with calamites.tres
- `scripts/autoloads/run_goal_system.gd` (slim target)
- `scripts/autoloads/resource_ledger.gd` — for seeding pools

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/ui/main_menu.gd` | Add "Start Run" button at top of menu. On press: load `data/species/calamites.tres`, set ecosystem to `carbo_coal_swamp`, call `PrestigeSystem.start_run(calamites)`, then `get_tree().change_scene_to_file("res://scenes/world/world.tscn")`. Hide/remove buttons that go to world_map or picker. |
| `scripts/autoloads/run_goal_system.gd` | Rewrite to ~30 lines. Only check: `hero_biomass_lifetime_produced ≥ 100_000 AND run_save.get("cycle_closed", false)`. Emit `goal_met` once. Keep `is_met()` and `get_progress()` (returns biomass / 100,000 ratio capped at 1.0). Drop the goal-index loading, niche maps, tile-colonized tracking, and event-resolved tracking. |
| `scripts/autoloads/prestige_system.gd` | At end of `start_run`, after `EventBus.run_started.emit`, seed pools: `ResourceLedger.add(BIOMASS, 50.0)`, `add(NUTRIENTS, 50.0)`, `add(DECAY, 50.0)`. |

## Constraints

- Godot 4, GDScript only.
- No new autoloads.
- No new EventBus signals — keep existing `goal_met` and `goal_progress_changed`.
- Unwire but don't delete: `world_map.gd`, `starting_species_picker.gd` stay on disk.
- `RunGoalSystem` is an autoload — can't delete its file. Just rewrite its body.
- `run_save.cycle_closed` is written in step 5; for now, RunGoalSystem just reads it (defaults to false until step 5 lands).

## Acceptance criteria

- [ ] Main menu shows "Start Run" prominently. Old picker entry hidden.
- [ ] Click Start Run → world.tscn loads with Calamites pre-introduced.
- [ ] HUD shows starting biomass 50 (seeded pool) and rate ticks up as Calamites placed.
- [ ] Hero biomass reaches 100,000 + cycle_closed flag is true → `goal_met` fires.
- [ ] Without cycle_closed, `goal_met` does NOT fire even past 100,000.
- [ ] `RunGoalSystem.get_progress()` returns 0.0–1.0 as ratio.
- [ ] No errors from unwired pickers on main-menu load.

## Out of scope

- Placement of additional species (step 4)
- Cycle closure detection (step 5) — only the `cycle_closed` flag needs to exist in run_save (Step 2 adds it)
- Goal banner updates (step 7 cuts the banner)

## Hand-back

Diffs for 3 files to Leon for Claude review. The slim of RunGoalSystem is the highest-risk piece — verify no other system imports the cut methods.
