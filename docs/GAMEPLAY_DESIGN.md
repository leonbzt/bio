# Bio v1 — Gameplay Design

> **You play life, optimizing for one species' reproduction by building the trophic web around it.** Each run is one map, one starter species, one closed cycle. The lineage tree records who you played, across runs.

Authoritative v1 spec. Locked 2026-05-27.

This doc supersedes the 2026-05-22 Hero / Pressure / two-clock design in its entirety after Reddit playtest feedback (2026-05-27) showed the god-curator UI was confusing players within 60 seconds. v1 narrows agency to one species per run, anchors the player on a single biomass number, and adopts a Factorio-style nutrient-web build loop. See § 8 for the full list of what changed vs the prior design.

---

## 1. Core loop

```
Pick a starter species (from Lineage Tree)
  ↓
Place it on one home tile on a fresh map
  ↓
Build the trophic web around it (place supporting species)
  ↓
Biomass throughput rises → reproduction events tick silently
  ↓
Cycle closes (producer → consumer → decomposer → soil → producer)
  ↓
Run completes; Evolution points awarded
  ↓
Pick next starter; new map; new run
```

Each run is **idle-capable** — biomass accumulates while AFK. Runs span roughly an overnight session up to a day of real time. One continuous clock; no active/offline multiplier.

---

## 2. Currencies

| Currency | Layer | Purpose | Where it shows |
|---|---|---|---|
| **Biomass** | In-run | Hero species' accumulating mass; throughput rate is the game's main optimization target | **Huge number, top of screen — the ONLY HUD number** |
| **Reproduction events** | In-run, silent | Tallied when hero biomass crosses population thresholds | Visual feedback on canvas only (cluster grows); not numeric |
| **Evolution points** | Between-run | Run-end yield = reproduction events × tier multiplier + milestone bonuses | Spent on Lineage Tree progression: new starter species, tier-list unlocks |
| **Web inputs** (sun, water, soil nutrients, litter) | World-side | Implied flows between species | Icons on tiles; never numeric HUD counters |

**One number on screen.** Population is internal. Reproduction is silent until run-end totals. Web inputs live in the world.

Biomass is hero-species-only. Supporting species have their own internal biomass driving their throughput, but it is shown only as cluster size/vigor — never as a HUD number.

---

## 3. In-run engagement — where the dopamine comes from

The moment-to-moment satisfaction during a run is **building the web**, not population growth. Specifically:

1. Placing a new species (a new node in your factory) → immediate visual change on the canvas
2. Seeing biomass throughput jump after closing a bottleneck
3. Unlocking a new placeable species at a biomass milestone
4. Discovering a symbiosis combo (visual glow when it triggers, never announced in advance)
5. Closing the cycle — the climactic event of the run

Reproduction events themselves stay quiet so they don't compete for attention with the build verbs. The big payoff is end-of-run Evolution.

---

## 4. The run

### Start — first tile
- One starter species, one home tile, biomass counter at the top, one "place" arrow.
- Nothing else visible. No menus, no biomes, no eras, no tree.

### Build — close the cycle
- Player places adjacent species to feed the web (producer → consumer → decomposer).
- Each placed species draws inputs from neighbors and produces outputs.
- Hero biomass throughput rises as bottlenecks are filled.

### Unlock — progressive reveal
- New species become placeable at biomass milestones.
- New web tools/views unlock at later milestones.
- **Onboarding rule**: nothing is visible until earned by a milestone.

### Cycle closure — run end
- Run completes when the trophic cycle is closed AND a biomass / population target is hit.
- Evolution points awarded.
- Lineage Tree gets a new node.

---

## 5. The Lineage Tree — meta progression

The persistent record across all runs:
- One node per completed run.
- Successor relationships drawn between runs when a species descends from a prior run's species.
- Branches represent kingdom / era specialization.
- TierZoo-style tier list (deferred to v2) uses the tree as its species roster.

Failed runs (closed without reproducing, or abandoned) yield 0 Evolution but don't damage the tree.

---

## 6. UI principles

| Rule | Why |
|---|---|
| One number on screen at all times | Reddit feedback: "what am I supposed to do?" answered by "watch this number." |
| Hide UI until milestone | Progressive reveal; minute-1 must be empty of options. |
| Web inputs live in the world, not the HUD | Avoid clutter; preserve visual focus on biomass and cluster art. |
| Combos discovered visually, never told in advance | Show, don't tell — symbiosis glows under your cluster when it kicks in. |
| TierZoo voice on text surfaces (v2+) | Deadpan-analytical voice for run-end summaries, lineage notes, tier list. |

The 48 px cluster-in-biome canvas locked 2026-05-22 is preserved. The hero species' cluster is visually emphasized (size / brightness / mark) but not via a separate HUD overlay.

---

## 7. v1 scope

**In:**
- One biome, one map shape
- 3–5 species spanning a minimum-viable cycle (producer + herbivore + decomposer) across the 3 kingdoms
- Biomass counter (one HUD number)
- Idle accumulation while AFK
- Run-end on closed cycle + biomass / population target
- Lineage Tree: bare list / graph of completed runs
- Species unlock by biomass threshold (placeholder placement mechanic)
- One starter species per run

**Out — deferred to v2+:**
- Era forks within a run
- Trait drafting / mutations
- Symbiont duos (paired hero+partner runs)
- Multiple biomes beyond cosmetic
- Structures as machines (one species = one machine in v1)
- Tier-list challenge mode
- TierZoo voice rollout
- Pressure / scarcity systems
- RPG stats (no Mass / Speed / etc — biomass is the only meaningful stat)
- Within-run species death from neglect
- Visual web overlay (arrows between species clusters)
- In-run upgrades / decisions beyond placing species

---

## 8. What this supersedes

This doc replaces the 2026-05-22 Hero + Pressure + two-clock design. The following concepts are **removed from v1**:

| Old (2026-05-22) | New (2026-05-27) |
|---|---|
| Six-stat Hero sheet (Mass/Speed/Predation/Defense/Metabolism/Cognition) | No stats. Biomass throughput is the only meaningful number. |
| Pressure as per-biome HP drain | No HP, no pressure system. Pacing comes from web bottlenecks. |
| Two clocks (active 2× / offline 1×) | One continuous idle clock. |
| Hero dies = run ends | No death state. Run ends on cycle closure + biomass / population target. |
| 5 strata per biome (S1 → S5) | No strata. |
| In-run mutation / event prompts | Evolution happens only between runs. |
| Phase A/B/C alpha-gate scheme | Replaced by v1 / v2 / later scope. |

**Preserved from 2026-05-22:**
- 48 px cluster-in-biome canvas (see `docs/VISUAL_DIRECTION.md`)
- Lineage Tree / Tree-of-Life concept as between-run progression
- TierZoo voice as a future text-surface rollout (v2+)
- Hero species + supporting ecosystem framing (now expressed as factory + recipe network)
- Carboniferous + Pleistocene starter-era pair as the species pool

---

## 9. Open questions deferred from this lock

1. **Web visibility** — explicit arrows / flow overlays between species clusters, or implicit through colocation? Decided per first playable.
2. **Species placement mechanic** — biomass-threshold unlock is the placeholder. Full placement design (cost? adjacency rules? hand-of-cards draft?) deferred.
3. **In-run upgrades** — Leon flagged that some in-run decisions / upgrades could land later. Scope TBD post-v1.
4. **Run-end trigger** — closed cycle vs population target vs both. Set by first playable.
5. **Idle pacing** — biomass / sec rates, population thresholds, run length. Resolved during recipe-table design.

---

## 10. Glossary

| Term | Meaning |
|---|---|
| Hero species | The single starter species of a run; the species whose biomass is optimized |
| Supporting species | Other species placed during the run to feed / recycle in the web |
| Trophic web / Nutrient cycle | The graph of input / output relationships between placed species |
| Recipe | A species' inputs and outputs (e.g., grass: sun + water → biomass + seeds + litter) |
| Run | One play session on one map with one starter species |
| Cycle closure | The trophic web has a complete loop producer → consumer → decomposer → soil → producer |
| Lineage Tree | The persistent record of completed runs and their successor relationships |
| Evolution points | Between-run currency, earned from reproduction events + milestone bonuses |
| Biomass | The hero species' accumulating life-mass; the in-run currency |
| Reproduction event | A silent pop when hero biomass crosses a population threshold; tallied for Evolution |
