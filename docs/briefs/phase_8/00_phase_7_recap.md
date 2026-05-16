# Brief 00 — Phase 8 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 7 complete: cleanup nits, drought/cool_spell handlers, audio, save backups, perf audit, balance pass, release readiness.
- [ ] Save at `save_version: 4`.
- [ ] All five HUD resources display and are spent meaningfully (per-kingdom visibility from brief 7/01).
- [ ] No regressions in plantae/fungi/symbiosis runs.

## What Phase 8 is

Phase 8 implements the **niche system** — the first deliverable in Tier 1 of the post-MVP roadmap. See `docs/NICHES.md` for the full design.

The niche layer turns "play plantae again" into "play plantae as a parasite this time." Same kingdom, fundamentally different rules. This is the highest-leverage post-MVP addition: it multiplies replay variety by 4–6×.

## Decisions locked for Phase 8

These are from the open questions in `ROADMAP.md`:

1. **Test-bed niche**: **Parasite plantae**. Built first; the patterns established for it inform Mycorrhizal fungi and any later niches.
2. **Unlock gating**: **One evolution node per niche**. Each non-default niche has a dedicated unlock node. Default niches (Photosynthesizer plantae, Decomposer fungi) are unlocked from the start.
3. **Animal kingdom interaction**: deferred to Phase 10. Phase 8 covers plantae + fungi niches only.

## Niches landing in this phase

| Kingdom | Niche | Status | Brief |
|---|---|---|---|
| Plantae | Photosynthesizer | Refactor existing default | 03 |
| Plantae | Parasite | **New** | 04 |
| Fungi | Decomposer | Refactor existing default | 03 |
| Fungi | Mycorrhizal | **New** (foundation for Phase 10 symbiosis reframe) | 05 |

Mycorrhizal fungi will feel underpowered in pure-fungi runs — that's intentional. It shines in symbiotic combinations, which Phase 10 unlocks. Implementing it now gives Phase 10 a head start and validates the niche system across both kingdoms.

## Contracts that landed during setup
Already in `ARCHITECTURE.md`:
- `ColonizationRulesRegistry` autoload added to system map.

Landing in Phase 8 (per the briefs):
- `NicheData` resource schema + `data/niches/_index.tres` (the content-index pattern).
- `GameState.current_niche_id: StringName`.
- Save schema v4 → v5 (adds `run.niche_id` + tile parasite-decay fields).
- One new EventBus signal: `niche_changed(niche_id: StringName)` for HUD updates.

## Out of scope
- Animal kingdom (Phase 10).
- Symbiotic species via Lichen (Phase 10).
- Pollinator-host plantae niche (needs insect agents — Phase 10).
- Cordyceps fungi parasite niche (needs animals to parasitize — Phase 10).
- Era / ecosystem system (Tier 2).
- Tree-visualization UI redo for the evolution web (Phase 9).
