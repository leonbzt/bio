# Brief 02 — Step 2: HUD reduction + hero lifetime counter

You are working on the Bio-Fantasy RPG project. Before you write any code, read these files in order:
1. `docs/ARCHITECTURE.md` (contracts — must not violate)
2. `docs/V1_PROTOTYPE.md` (gameplay spec, especially § 2 currencies and § 6 UI principles)
3. `docs/V1_MIGRATION_PLAN.md` (full migration context)
4. `docs/briefs/phase_16/00_phase_16_entry.md` (phase scope + decisions locked)
5. `docs/briefs/phase_16/01_recipe_model_DONE.md` (what changed in step 1, including the carry-over notes)

## Goal

Replace the existing 5-resource HUD with a single huge biomass counter showing the player's **lifetime hero-biomass production** (monotonic from plant ticks, decremented only by placement costs — placement costs land in step 04, but the counter field must exist now).

Also disable the per-biome free injection of NUTRIENTS + DECAY in `NutrientSystem` so the bottleneck mechanic introduced in step 01 actually bites.

This is the "one number on screen" requirement from V1_PROTOTYPE.md § 6.

## Inputs (read-only)

- `docs/V1_PROTOTYPE.md` § 2 (currencies), § 3 (in-run dopamine), § 6 (UI principles)
- `scripts/autoloads/resource_ledger.gd` — existing biomass pool, do not refactor; just stop binding most resources in the HUD
- `scripts/autoloads/save_system.gd` — needs SAVE_VERSION bump + new field; **no migration path** (save break is acceptable, alpha audience)
- `scripts/autoloads/game_state.gd`
- `scripts/systems/growth_system.gd` — biomass production from plant species is where the lifetime counter ticks up
- `scripts/systems/nutrient_system.gd` — disable nutrient + decay injection here
- `scripts/systems/prestige_system.gd` `_reset_run_state()` — needs the new field in the fresh-run template

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/ui/hud.gd` | Rewrite ~80-120 lines (down from 420). Single biomass label + rate label + ecosystem name + pause button. Strip 5-resource binding, abilities bar, event toast, recipes button, structure_promoted handler, identity strip species portrait. Keep tick indicator. |
| `scenes/ui/hud.tscn` | Rewrite scene tree to match. New: `BiomassCounter` (Label, big font), `RateLabel` (Label, smaller), `EcosystemNameLabel` (Label, top corner). Remove: `Bar/Margin/ResourcesRow`, `AbilitiesBar`, `EventToast`, `RecipesButton`. Keep `PauseButton`, `TickIndicator`, `IdentityStrip` (repurposed for ecosystem name only). |
| `scripts/autoloads/save_system.gd` | Bump `SAVE_VERSION` to next value. Add `hero_biomass_lifetime_produced: 0.0` to the run-save schema. No migration path. |
| `scripts/systems/prestige_system.gd` | Add `"hero_biomass_lifetime_produced": 0.0` to the dict in `_reset_run_state()`. |
| `scripts/systems/growth_system.gd` | In `_apply_yields`, when adding biomass to ResourceLedger, ALSO add to `run_save.hero_biomass_lifetime_produced` — but ONLY for plant-kingdom species (gate on `species.kingdom_id == &"plantae"`). Arthropleura's biomass-consumption via `consume_input` must NOT affect this counter. |
| `scripts/systems/nutrient_system.gd` | In `_on_tick`, comment out or remove the `if biome.nutrient_per_tick != 0.0` and `if biome.decay_per_tick != 0.0` blocks. Leave sunlight injection alone (it's unused but harmless). |

## Constraints

- Godot 4, GDScript only.
- No new autoloads.
- No new EventBus signals unless necessary. If you add one (e.g., `lifetime_biomass_changed`), add a line to `docs/ARCHITECTURE.md` listing it. Otherwise drive HUD rate from existing `EventBus.tick` and read `run_save.hero_biomass_lifetime_produced` directly.
- Tick-driven, no `_process` for HUD updates.
- `FormatUtils.abbreviate` exists and should be used for the big biomass number.
- **Hero biomass counter MUST NOT decrement** when Arthropleura consumes biomass via `consume_input` — that's a global-pool flow only.
- The HUD's existing event-toast / abilities-bar / structure-banner subscriptions should be removed cleanly — disconnecting signals or simply not connecting them. No graceful-fallback code paths if those nodes are missing.

## Rate label computation

Show "+X.X/s" beneath the counter. Compute as the delta of `hero_biomass_lifetime_produced` over the last N ticks (suggest N = 10 ticks ≈ 1 second at default tick_hz). Smooth via a small ring buffer in the HUD script to avoid flicker. Keep the ring buffer to ~20 lines of code; don't over-engineer.

## Acceptance criteria

- [ ] HUD shows ONE big biomass number prominently at top of screen.
- [ ] Below the big number, a smaller rate label updates each tick (e.g., `+8.5/s`).
- [ ] Ecosystem name (`Coal Swamp`) shown small at top corner.
- [ ] Pause button remains functional.
- [ ] No 5-resource row, no abilities bar, no event toast, no recipes button visible anywhere in the HUD.
- [ ] Hero biomass counter accumulates as Calamites ticks — verify by placing Calamites and watching counter climb.
- [ ] Place Arthropleura on an adjacent tile; verify the ResourceLedger BIOMASS pool drops (Arthropleura is consuming it) but the HUD counter does NOT drop.
- [ ] Save round-trip preserves `hero_biomass_lifetime_produced` — bump SAVE_VERSION cleanly; existing saves get zeroed (acceptable).
- [ ] After disabling biome nutrient/decay injection, placing only Calamites (no Mycorrhizal Network yet) eventually stalls — nutrients in the pool deplete, Calamites' `consume_input` throttle drops to 0, biomass stops climbing. This is the bottleneck mechanic visibly biting.
- [ ] Code runs in editor without errors. Verify by opening `scenes/world/world.tscn` and pressing play.
- [ ] No console errors from cut HUD elements being absent.

## Out of scope

- Placement costs (Step 4 will deduct from the counter)
- Checkpoint UI (Step 4)
- Cycle closure visual (Step 5)
- Per-cluster status bars (Step 6)
- Removing the species panel — keep as-is for now
- Removing the goal banner — keep as-is for now (it'll show stale Coal Gauge progress; harmless until Step 3 slims RunGoalSystem)
- Stripping ResourceLedger's 11 constants — keep them, just don't bind them in HUD
- Renaming species, biomes, or ecosystems
- Adding starter pools (V1_PROTOTYPE.md mentions seeding N/B/D pools with 50 each on run start — that's step 3 or 4 work)

## Hand-back instructions

When done, paste the diffs for all 6 modified files to Leon for Claude diff review. **Save schema bump is the high-risk area** — Claude must verify the SAVE_VERSION bump and the field initialization across `_reset_run_state` and `SaveSystem`.

Stretch goal (optional, defer if running long): after this brief lands, the bottleneck mechanic should be visibly demonstrable. If you have time, take a screenshot of the HUD with the counter climbing and another with it stalled (no Mycorrhizal Network placed yet). Attach to PR description.
