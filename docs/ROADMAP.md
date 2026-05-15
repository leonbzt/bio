# Development Roadmap

Phase plan with concrete deliverables. Each phase is bracketed by a Claude session that authors briefs at the start and reviews contracts at the end.

## Phase 1 — Foundation
**Goal:** Godot project running on Android with the architectural spine wired up.

Briefs: `docs/briefs/phase_1/` (00–08).

Deliverables:
- Godot project created, Android export working.
- Six autoloads registered and implemented: EventBus, TickClock, ResourceLedger, GameState, SaveSystem, AudioManager.
- All Resource schema classes in `scripts/data/`.
- Boot → main menu → world scene flow.
- Touch camera rig (pan + pinch).
- 32×48 tile grid renders.
- HUD shows resources, updates reactively.
- Smoke test: data-driven trait increments biomass per tick, persists across restart.

Exit criterion: smoke test from brief 08 passes.

---

## Phase 2 — Plant Prototype
**Goal:** First playable kingdom. Player taps to colonize tiles; biomass accumulates.

Deliverables:
- `TerritorySystem` — tap an adjacent tile to colonize. Validates cost via `ResourceLedger.spend_bundle`.
- `GrowthSystem` — tick-driven biomass generation per owned tile, modified by traits.
- `NutrientSystem` — biome-based sunlight/nutrient yields per tile.
- 2–3 `SpeciesData` files in `data/species/`.
- HUD: abbreviated numeric notation (`1.2K`, `3.4M`).
- Offline progress: replay up to 8h of ticks on cold start.

Exit criterion: a player can leave the app for 5 min, return, and see accumulated biomass + visible territory growth.

---

## Phase 3 — Active Gameplay
**Goal:** Tension and engagement; a reason to actually open the app.

Deliverables:
- `EcologicalPressure` system — schedules events from `data/events/` based on world state.
- One concrete event: `HerbivoreWave` — spawns moving herbivore organisms that eat owned tiles.
- One active ability: `ToxinBloom` — button on HUD, costs biomass, damages herbivores in radius.
- Event alert UI: toast + optional pause prompt on critical events.

Exit criterion: the player must intervene during a herbivore wave or lose territory.

---

## Phase 4 — Prestige
**Goal:** First long-term progression loop.

Deliverables:
- `PrestigeSystem` — resets `RunSave`, advances `MetaSave`.
- `MetaSave` schema: unlocked kingdoms, evolution-tree nodes, lifetime stats.
- Evolution tree UI: 5–10 nodes, branching tree visual, tap to spend meta-currency.
- One unlocked node grants Fungi kingdom.
- Save migration test: build a v1 save, bump to v2, confirm migrate() works.

Exit criterion: completing a plant run unlocks fungi as a playable kingdom.

---

## Phase 5 — Fungi
**Goal:** Second kingdom with mechanically distinct play.

Deliverables:
- Fungi colonization mode: spread *under* existing plant tiles or on corpses.
- New resources online: decay, spores.
- Infection event: spores spread between tiles based on humidity/proximity.
- Decomposition loop: dead organisms produce decay over N ticks.

Exit criterion: a fungi run feels fundamentally different from a plant run (per Design Pillar #3).

---

## Phase 6 — Symbiosis
**Goal:** First major complexity leap (per `docs/KINGDOMS.md`).

Deliverables:
- Composite tile state: a tile can hold both plant + fungus simultaneously.
- Symbiosis multipliers: shared nutrient bonus when both kingdoms occupy a tile.
- Hybrid evolution-tree nodes that grant cross-kingdom traits.
- 2–3 new species that are explicitly symbiotic.

Exit criterion: player can build a measurably stronger ecosystem with symbiosis than without.

---

## Phase 7 — Polish
**Goal:** Shippable.

Deliverables:
- Balancing pass via data files only.
- Mobile perf profiling — target 60fps, low idle CPU on a mid-range Android.
- Sound/music pass.
- Save backup rotation + cloud sync optional.
- iOS export (if Mac/Apple dev account available).
- Internal closed beta on Play Console.

Exit criterion: stable build on Play Console internal track, 5 testers complete one full plant→fungi→symbiosis loop.
