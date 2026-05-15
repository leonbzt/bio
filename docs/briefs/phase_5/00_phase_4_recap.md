# Brief 00 — Phase 5 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 4 smoke test passed (you confirmed).
- [ ] Save at `save_version: 3`.
- [ ] `meta.unlocked_kingdoms` contains `"plantae"` (and possibly `"fungi"` if you tested the full chain).

## What lands during Phase 5

Big-picture: fungi gets real mechanics, distinct from plantae per Pillar #3.

- **Save schema v3 → v4**: tile entries gain dual-layer ownership (`surface_owner` / `subsurface_owner`). One migration arm.
- **TerritorySystem refactor**: becomes a passive state holder. Tap handling moves into two new systems — `PlantColonization` and `FungiColonization`.
- **CorpseSystem**: when a herbivore dies, leave a decaying corpse tile that produces decay-per-tick for N ticks. Fungi can grow on corpses.
- **Fungi rules**: fungi grow under plant tiles (parasitic), on corpses (decomposer), or adjacent to fungi (network). They consume spores (not biomass) per colonize.
- **Spore infection event**: new ecological event spreads fungi to adjacent unowned tiles.
- **Kingdom-aware GrowthSystem**: routes by `GameState.current_kingdom_id`, loads the correct species, ticks the correct layer.

## What you don't need to do
- Phase 6 (symbiosis) is the next leap. Phase 5 just unlocks the *possibility* of co-occupied tiles in the data model. The bonuses come later.
- No new EventBus signals. All Phase 5 work uses existing signals.

## Out of scope
- Fungi-specific ecological events beyond spore infection (e.g. antifungal blooms) — Phase 7 polish.
- Multiple fungi species. One species this phase.
- Herbivore behavior against fungi. Herbivores chew surface tiles only; fungi runs are inherently less event-stressed. Tuning happens in Phase 7.
