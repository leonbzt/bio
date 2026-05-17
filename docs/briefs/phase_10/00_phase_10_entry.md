# Brief 00 — Phase 10 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 9 smoke test passed.
- [ ] Phase 11 implementation landed + smoke test passed (Phase 11 was briefed and shipped *before* Phase 10 because it was smaller and more cohesive — Phase 10 picks up the remaining Tier 1 work).
- [ ] Save at `save_version: 9`.

## What Phase 10 is

The largest single phase to date and the last unbriefed Tier 1 work. Reshapes symbiosis from a kingdom into the long progression axis, introduces animals, makes the two existing non-default niches feel distinct, and seeds the resource expansion that Tier 2 needs.

Six bundled deliverables:

1. **Layered-lifeform foundation (hybrid niche+species model)** — `NicheData.expects_layered`, `SpeciesData.layer_count` + `layer_species`. The cascade Player picks: kingdom → niche → species, where some niches (Lichen) drive a multi-layer placement experience via the species' layer roster.
2. **Lichen as a Fungi niche** — the first 2-layer playable. Biologically the fungus dominates structurally, so Lichen lives under Fungi. Pack: mycelium_thread (subsurface) + pioneer_grass (surface).
3. **Retire `&"symbiosis"` kingdom** — removed from UI, removed from `unlocked_kingdoms`, retired from hardcoded references in `growth_system.gd`/`prestige_system.gd`. Save v8 → v9 (wait — Phase 11 already used v9; this is v9 → v10) migrates in-flight symbiosis runs to fungi/lichen.
4. **Per-niche signature mechanics** for the two non-default niches:
   - **Parasite plantae**: biomass-steal tick effect — adjacent non-parasite plantae or fungi tiles lose biomass that the parasite cluster gains. Replaces the flat 2× yield multiplier.
   - **Mycorrhizal fungi**: substrate-claim placement mode — tap an existing plantae tile to bond with it (bond gives mutual yield boost), instead of just adjacency-placement.
5. **Animal kingdom foundation** — kingdom registration, two niches (Herbivore + Predator), two species (one each), separate stat-block from herbivore-wave agents.
6. **6 stub resources** — Protein, Cellulose, Chitin, Phosphate, Lifeforce, Pollination. ResourceLedger IDs + greyed HUD display + voice text. No gameplay impact yet; wires up in Phases 13–14.

Plus a **graphics pass** (niche icons + animal sprites + Lichen visual at placeholder quality) and a smoke test.

## Decisions locked

From 2026-05-16 and 2026-05-17 conversations:

1. **Lichen kingdom**: Fungi (not Plantae).
2. **Lichen model**: hybrid niche+species — niche owns the UI entry + `expects_layered: bool`, species owns `layer_count` + `layer_species`.
3. **3+ layer model**: deferred to Phase 14 when Coral actually needs it. Lichen ships as 2-layer-only.
4. **Animal Herbivore**: separate stat-block from herbivore-wave agents.
5. **Animal Predator scope**: spawn + move only (placeholder). "Feels predatory" deferred to Phase 14 polish.
6. **Insects**: **deferred to Phase 14** alongside Pollinator-Host plantae niche. Drop from this phase.
7. **Parasite plantae steal-source**: adjacent non-parasite tiles owned by **plantae or fungi** (not symbiosis kingdom — it's gone; not animals — first-pass scope). Per-species override via a `parasitic_targets` array on the niche, future-extensible to per-species in Phase 14+.
8. **Stub resource HUD visibility**: visible-but-greyed with tooltip "Coming in Phase N".

## Save schema bump rationale

This is the second v9-touching phase. To keep migrations linear, **Phase 10 bumps to v10**. Note: the docs say "v7 → v8" in older roadmap text — that text predates Phase 11. Phase 11 already bumped to v9. This phase bumps v9 → v10.

## Contracts landing in Phase 10

- **Save schema v9 → v10**: removes `&"symbiosis"` from `meta.unlocked_kingdoms` (defensive); rewrites in-flight `run.kingdom_id == "symbiosis"` to `"fungi"` with `run.niche_id = "lichen"`; adds the 6 stub resource IDs to `run.resources` with value 0.0.
- **`NicheData` schema extension**: `expects_layered: bool = false`, `parasitic_targets: Array[StringName] = []`.
- **`SpeciesData` schema extension**: `layer_count: int = 1`, `layer_species: Array[SpeciesData] = []`.
- **Animal kingdom_id**: new `&"animals"` registered in the kingdom system; new species type `AnimalSpeciesData` or fields on existing `SpeciesData`.
- **HUD ability bar** stays as-is (Phase 11 work); animal niches' active gameplay comes through that bar.
- **No new EventBus signals** in Phase 10.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v9 → v10 migration | ChatGPT 5.2 / Copilot | **Claude** (save format) |
| 02 | Schema extensions (NicheData + SpeciesData) + 6 stub ResourceLedger constants | ChatGPT 5.2 / Copilot | Claude (contracts) |
| 03 | Retire `&"symbiosis"` kingdom from code + data | ChatGPT 5.2 / Copilot | Claude (refactor blast radius) |
| 04 | Multi-layer placement engine (generalize Phase 6's dual-layer to N) | ChatGPT 5.2 / Copilot | Claude |
| 05 | Lichen niche + species pack + integration | Kilo (data) + ChatGPT (logic) | Claude |
| 06 | Parasite plantae signature mechanic | ChatGPT 5.2 / Copilot | Claude (balance) |
| 07 | Mycorrhizal fungi signature mechanic | ChatGPT 5.2 / Copilot | Claude (UX) |
| 08 | Animal kingdom registration + Herbivore niche + species | ChatGPT 5.2 / Copilot | Claude |
| 09 | Animal Predator niche + species (placeholder) | Kilo (data) + ChatGPT (mover) | Claude |
| 10 | 6 stub resources: HUD greyed display + voice text tooltips | ChatGPT 5.2 / Copilot | — |
| 11 | Graphics pass: niche icons, animal sprites, Lichen visual | Kilo (assets + scene wiring) | — |
| 12 | Phase 10 manual smoke test | you on device | — |

## Internal phase checkpoints

This phase is large enough that two sanity-checks help:
- **After brief 05**: Lichen plays as a 2-layer Fungi niche. Validates layered-foundation + symbiosis-retirement before animals enter the picture.
- **After brief 09**: Animal Herbivore + Predator runs work. Validates animal foundation before the polish briefs (10, 11).

If something breaks at either checkpoint, fix before continuing.

## Out of scope

- Insect agents (Phase 14 with Pollinator-Host).
- 3+ layer species packs (Coral, Termite Mound — Phase 14).
- Cordyceps fungi parasite niche (Phase 14).
- Predator actively hunting (Phase 14 polish — placeholder in this phase).
- Animal-specific events (Phase 13 with the ecosystem system).
- Era system, ecosystem selector (Phase 12).
- Resource wiring for Protein/Cellulose/Chitin/Phosphate/Lifeforce/Pollination (Phase 14 makes them load-bearing; Phase 10 just introduces the IDs + display).
- Algae as a microbial sub-species (Phase 14 with Coral).
- Wiring the persistent-structures escape hatch (parked design; revisit when structures phase commits).
