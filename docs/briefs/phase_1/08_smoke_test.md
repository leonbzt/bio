# Brief 08 — End-to-end smoke test

**Suggested agent**: ChatGPT 5.2 via Copilot. Content for the test `.tres` can be passed to Kilo if you want.

Read `docs/ARCHITECTURE.md` sections 2 (data-driven principle) and 4 (Resource schemas).

## Goal
Prove the architecture works end-to-end with one validation flow: load a `TraitData` resource from disk, apply it to the ledger via the tick loop, and observe the result through the HUD.

This is a throwaway test bench — it will be deleted at the end of Phase 1. The point is to catch architectural breaks early.

## Outputs (create)
- `data/traits/test_photosynthesis.tres` — `TraitData` resource with id `test_photosynthesis`, modifiers `{"biomass_per_tick": 1.0}`.
- `scripts/systems/_smoke_growth.gd` — temporary node attached to `Systems` in `world.tscn`. Loads the trait, subscribes to `EventBus.tick`, on each tick calls `ResourceLedger.add(&"biomass", trait.modifiers["biomass_per_tick"])`.
- Add a debug label in HUD that shows "SMOKE: <tick_count>" updating on each tick.

## Acceptance criteria
- [ ] Launching world.tscn results in biomass climbing by 1 per second, visible in the HUD.
- [ ] Killing the app and restarting **does not** reset biomass — proves SaveSystem is wiring run state correctly.
- [ ] No system imports another system directly. `_smoke_growth.gd` only uses autoloads + EventBus.
- [ ] Removing `test_photosynthesis.tres` from disk and re-running prints a clear error and the smoke system does nothing (graceful failure).

## Cleanup
At the start of Phase 2 (or at the end of Phase 1 review), delete:
- `data/traits/test_photosynthesis.tres`
- `scripts/systems/_smoke_growth.gd`
- The SMOKE label from HUD.

## Why this matters
If this brief passes cleanly, every contract in `ARCHITECTURE.md` is wired correctly: data-driven resources, the EventBus, the tick clock, the save system, and the HUD reactivity. Phase 2 can build on these without surprise.
