# Brief 04 — Step 4: Placement costs + checkpoint flow

You are working on the Bio-Fantasy RPG project. Before you write any code, read:
1. `docs/ARCHITECTURE.md`
2. `docs/V1_PROTOTYPE.md` § 5 (placement costs) and § 7 (checkpoint cadence)
3. `docs/briefs/phase_16/00_phase_16_entry.md`

## Goal

Three deliverables:
1. Switch placement cost from `ResourceLedger.BIOMASS` to the `hero_biomass_lifetime_produced` counter (from step 2). The counter ticks DOWN on placement and back UP from production.
2. Build a `CheckpointSystem` autoload that fires `checkpoint_triggered(id)` on milestones OR bottleneck conditions.
3. Rewrite onboarding overlay to listen to checkpoint signals (replacing the hard-coded 6-step ladder).

## Inputs (read-only)

- `docs/V1_PROTOTYPE.md` § 5, § 7
- `scripts/ui/species_panel.gd` (placement flow lives here)
- `scripts/ui/onboarding_overlay.gd` (current 6-step ladder)
- `scripts/autoloads/resource_ledger.gd` (read pool states for bottleneck detection)
- `scripts/autoloads/event_bus.gd` (add new signal here)
- `scripts/autoloads/tick_clock.gd` (for tick→time conversion)
- `project.godot` (register the new autoload)

## Outputs (create or modify)

| File | What |
|---|---|
| `scripts/autoloads/event_bus.gd` | Add signal `checkpoint_triggered(id: StringName, payload: Dictionary)`. List in ARCHITECTURE.md. |
| `scripts/autoloads/checkpoint_system.gd` (NEW) | See § CheckpointSystem spec. ~120 lines. |
| `project.godot` | Register `CheckpointSystem` as autoload after `ResourceLedger` and `GameState`. |
| `scripts/autoloads/game_state.gd` | Add helpers: `get_hero_biomass() -> float`, `can_afford_hero_biomass(amount) -> bool`, `spend_hero_biomass(amount) -> bool` (returns false if insufficient; mutates `run_save.hero_biomass_lifetime_produced`). |
| `scripts/ui/species_panel.gd` | Switch `_introduce_species` from `ResourceLedger.spend_bundle(species.introduce_cost)` to `GameState.spend_hero_biomass(_get_biomass_cost(species))`. Disable button if `can_afford_hero_biomass` is false. Helper `_get_biomass_cost` reads `float(species.introduce_cost.get("biomass", 0.0))`. |
| `scripts/ui/onboarding_overlay.gd` | Replace `STEPS` array + signal handlers with a checkpoint listener. Show bubble for the latest unprocessed checkpoint; dismiss on player action (e.g., placing the suggested species). |

## CheckpointSystem spec

Autoload, loaded after ResourceLedger + GameState + TickClock.

State (cleared on `run_started`):
```gdscript
var _fired: Dictionary[StringName, bool] = {}
var _bottleneck_age_ticks: Dictionary[StringName, int] = {}
```

Listens:
- `EventBus.run_started` — clear state, immediately fire `place_hero`
- `EventBus.tick` — check milestone + bottleneck conditions

Checkpoints (fire once per run, in order; subsequent same-ID checks no-op):

| ID | Trigger condition |
|---|---|
| `place_hero` | fired on run_started |
| `unlock_mycorrhizal` | hero_biomass ≥ 50 OR nutrients pool ≤ 5 for 60s |
| `unlock_arthropleura` | hero_biomass ≥ 500 OR detritus pool ≤ 5 for 60s |
| `bottleneck_nutrients` | nutrients ≤ 5 for 5 min AND cycle_closed |
| `bottleneck_detritus` | detritus ≤ 5 for 5 min AND cycle_closed |
| `run_complete` | hero_biomass ≥ 100,000 AND cycle_closed |

60s and 5min = constants `STARVATION_GRACE_TICKS_SHORT` (60 × tick_hz) and `STARVATION_GRACE_TICKS_LONG` (300 × tick_hz). Named, tunable.

Emits: `EventBus.checkpoint_triggered(id, {})`. Empty payload for v1; reserved for future enrichment.

## Onboarding overlay rewrite

- Drop the `STEPS` array.
- Listen to `EventBus.checkpoint_triggered`.
- Maintain a queue of unread checkpoints; show the front one as a bubble.
- Dismiss when player performs the relevant action (place a species, etc.).

Bubble text by checkpoint ID:
- `place_hero`: "Place your first Calamites on a wetland tile (dark green-brown). It thrives in wet ground."
- `unlock_mycorrhizal`: "Soil nutrients run thin. Mycorrhizal Network turns dead litter into nutrients. Place it adjacent to your Calamites."
- `unlock_arthropleura`: "Dead matter piling up. Arthropleura eats litter and feeds the fungi. Place it nearby."
- `bottleneck_nutrients`: "Your nutrients pool is depleted. Place another Mycorrhizal Network."
- `bottleneck_detritus`: "Your detritus pool is depleted. Place another Arthropleura."
- `run_complete`: "The forest is self-sustaining. Run complete." (Brief celebratory; prestige screen handles the rest in step 7.)

Existing `meta_save.onboarding_step` field becomes obsolete — leave it (unwired strategy).

## Constraints

- One new autoload (`CheckpointSystem`). Update `project.godot`.
- One new EventBus signal (`checkpoint_triggered`). List in ARCHITECTURE.md.
- Bottleneck-detection thresholds (5 sec, 5 min, etc.) are playtest-tunable — use named constants at top of CheckpointSystem.
- Manual placement always allowed if the player can afford it — checkpoints are suggestions, not gates.

## Acceptance criteria

- [ ] On run start, `place_hero` bubble shows.
- [ ] After placing Calamites + hero biomass ≥ 50, `unlock_mycorrhizal` bubble shows.
- [ ] After placing Mycorrhizal Network + hero biomass ≥ 500, `unlock_arthropleura` bubble shows.
- [ ] Placing Mycorrhizal Network costs 30 hero biomass (visible counter dip).
- [ ] Placing Arthropleura costs 50 hero biomass (visible counter dip).
- [ ] If hero biomass < cost, species panel "Introduce" button is disabled.
- [ ] Arthropleura consuming biomass via `consume_input` reduces the global B pool but NOT the hero counter.
- [ ] Post-closure, if a pool stays empty 5 min → corresponding `bottleneck_*` checkpoint fires.
- [ ] `run_complete` fires at biomass ≥ 100k + cycle_closed.
- [ ] Save round-trip preserves which checkpoints have fired.

## Out of scope

- Cycle closure detection (step 5) — `cycle_closed` is just read here, written in step 5
- Cluster status indicators (step 6)
- Audio cue on checkpoint fire (defer)
- Animated bubble transitions (defer)

## Hand-back

Diffs for all 6 modified files + 1 new autoload to Leon for Claude review. **CheckpointSystem state machine** is the high-risk piece — verify the `_fired` dictionary correctly prevents re-firing across save/load round-trips.
