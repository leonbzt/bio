# Brief 00 — Phase 6 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 5 smoke test passed.
- [ ] Save at `save_version: 4`.
- [ ] Fungi runs work standalone (no plantae stuff bleeds in).
- [ ] No regressions in plantae runs.

## What lands during Phase 6

Symbiosis is the **first real complexity leap** (Pillar #2 + KINGDOMS.md). The data model already supports co-occupied tiles since Phase 5; Phase 6 adds:
- A third **symbiosis kingdom** that lets you place both layers in one run.
- A layer-toggle HUD that swaps `placement_target` between plantae and fungi.
- Symbiosis bonuses in GrowthSystem — co-occupied tiles yield more.
- 2–3 hybrid evolution nodes that unlock and amplify symbiosis.

## Contracts that landed during setup
Already applied to `event_bus.gd`, `game_state.gd`, and `ARCHITECTURE.md`:
- `EventBus.placement_target_changed(target: StringName)` signal.
- `GameState.placement_target: StringName` field.
- PlantColonization/FungiColonization subscription criteria extended to handle symbiosis kingdom.

## Out of scope
- New kingdoms beyond symbiosis.
- Cross-kingdom abilities (Toxin Bloom stays plantae-flavored).
- New ecological events for symbiosis runs.
- Symbiotic species are deferred to Phase 7 polish — for MVP, the existing pioneer_grass + mycelium_thread combo is enough to demonstrate the mechanic.

## Out of scope (definitely Phase 7+)
- Multi-tile symbiosis chains (mycorrhizal networks spanning multiple tiles).
- Visual indicators for symbiotic tiles (the dual overlay is already visible — that's enough).
- Tutorial / onboarding UI for symbiosis. Players figure it out from the unlock description.
