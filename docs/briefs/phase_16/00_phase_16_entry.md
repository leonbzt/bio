# Brief 00 — Phase 16 entry (v1 prototype migration)

**Suggested agent**: read-only; Leon executes the brief routing below.

## Pre-flight

- [ ] `docs/V1_PROTOTYPE.md` read (the locked v1 spec).
- [ ] `docs/V1_MIGRATION_PLAN.md` read (keep/rework/cut + 7-step sequence).
- [ ] Existing build verified runnable on `main` before starting.
- [ ] Feature branch recommended — destructive cuts ahead.

## What Phase 16 is

Migration of the existing Coal Swamp Carboniferous build from the 2026-05-22 god-curator design (`[[project-hero-loop-design]]`, pre-2026-05-27) to the 2026-05-27 sandbox-factorio biomass-throughput model.

**Locked shape:** single hero (Calamites) in the Coal Swamp wetland biome, supported by Mycorrhizal Network (decomposer) + Arthropleura (consumer). Three global resources (Nutrients / Biomass / Detritus, internal only). One HUD number (hero biomass, monotonic from production minus placement costs). Idle-capable. Checkpoint-paced.

This phase **deletes (does not stub)**:
- 2026-05-22 Hero/Pressure systems: hero stat sheet, pressure HP drain, two-clock active/offline, mutation/event prompts
- Multi-resource HUD (5 → 1)
- Era system, adaptation system, structure registry, ecological pressure events, herbivore entities, fog, abilities, discovery log
- Recipe Book, Evolve Modal, World Map

Per `[[feedback-no-beta-preservation]]`: cut files stay on disk but unwired; no preservation hooks for future re-introduction.

## Decisions locked

1. **Single starter species**: Calamites (plant role). No starting-species picker — auto-launch run from main menu.
2. **Three internal resources**: Nutrients / Biomass / Detritus, global pools (V1_PROTOTYPE.md § 2 Option A). No spatial flows in v1.
3. **HUD shows ONE number**: hero biomass, accumulating monotonically from Calamites production, decremented only on placement cost.
4. **Run end**: hero biomass ≥ 100,000 AND cycle closed. Numbers playtest-tunable.
5. **Checkpoint flow**: milestones OR bottleneck detection trigger active prompts. Suggestions, not gates — manual placement always allowed.
6. **Idle**: continuous, single-rate. No active multiplier. Same throughput whether watched or not.
7. **Save break acceptable** — alpha audience. Bump SAVE_VERSION, no migration path.

## Contracts landing in Phase 16

- **`SpeciesData`** new field: `consume_input: Dictionary` — per-tile-per-tick input rates. Landed in step 01.
- **`GrowthSystem`** new throttling: input availability throttles `tick_yield` proportionally. Landed in step 01.
- **`NutrientSystem`** disable per-biome injection of NUTRIENTS + DECAY (biomes no longer free-produce the recipe inputs).
- **`run_save`** new field: `hero_biomass_lifetime_produced: float` — monotonic from plant production; decremented only on placement cost.
- **`ResourceLedger`** keep constants but slim HUD-visible to BIOMASS / NUTRIENTS / DECAY only.
- **HUD scene** rewrite: single biomass counter + rate label + ecosystem name + pause button. Strip 5-resource row, abilities bar, event toast, recipes button.
- **`RunGoalSystem`** slimmed: hard-coded biomass-threshold + cycle-closure check.
- **`OnboardingOverlay`** rewrite: drive checkpoint cadence (place hero → unlock fungus → unlock animal → cycle closes → run end).
- **Cycle-closure event**: when all 3 species placed AND all 3 pools flowing → visual glow + ×1.5 throughput multiplier.
- **Per-cluster status bar**: green/yellow/red availability indicator on each species cluster.
- **`prestige_screen`**: Evolution Points + lineage tree node (flat list).

## Brief routing

| # | Brief | Agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Step 1 — Recipe model in data | **DONE** (Claude, 2026-05-27) | — |
| 02 | Step 2 — HUD reduction + hero lifetime counter | ChatGPT 5.2 | **Claude** (save schema + counter wiring) |
| 03 | Step 3 — Auto-launch + slim RunGoalSystem | ChatGPT 5.2 | Claude |
| 04 | Step 4 — Placement costs + checkpoint flow | ChatGPT 5.2 | **Claude** (checkpoint state machine) |
| 05 | Step 5 — Cycle closure detection | ChatGPT 5.2 | — |
| 06 | Step 6 — Per-cluster status indicators | ChatGPT 5.2 | — |
| 07 | Step 7 — Prestige reskin + lineage list | ChatGPT 5.2 | Claude |
| 08 | Phase 16 smoke test | Leon on device | — |

## Order of work

Sequential — each step ends with a runnable build. If a step takes longer than ~1 day, scope down before proceeding.

1. **01** recipe model (DONE).
2. **02** HUD reduction (next).
3. **03** run lifecycle.
4. **04** placement costs + checkpoints.
5. **05** cycle closure.
6. **06** cluster status bars.
7. **07** prestige reskin.
8. **08** smoke test.

## Exit criteria

- Player launches game → auto-starts Calamites run in Coal Swamp.
- Onboarding teaches: place Calamites → unlock + place Mycorrhizal Network → unlock + place Arthropleura → cycle closes.
- HUD shows ONE big biomass number + rate.
- Biomass accumulates over time from Calamites ticks (plant-only).
- Placing supports costs hero biomass (visible counter dip).
- After cycle closes, throughput ×1.5; biomass climbs faster than before placement.
- Run ends at biomass ≥ 100,000; Evolution awarded; lineage tree node added.
- Idle test: 30 min unfocused → return to higher biomass.
- No errors from unwired cut systems on load.

## Out of scope (deferred to v2+)

Per `[[feedback-no-beta-preservation]]` — these stay deleted, not stubbed:

- Multiple hero species / starting picker
- Multiple biomes / ecosystems
- Era forks, era transitions
- Trait drafting / mutations
- Symbiont duos (paired hero+partner runs)
- Per-tile or zonal resource flows (still Option A global pools)
- Structures-as-machines
- Hero abilities
- TierZoo voice rollout
- Recipe book / Field Guide
- Adaptation / leveling per species
- Tier-list challenge mode
