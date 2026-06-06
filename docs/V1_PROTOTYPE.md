# Bio v1 Prototype — locked spec

> **Team-loadout Carboniferous wetland; pick 3 species (one per role: Producer/Harvester/Recycler); per-tile local resource flow; tap-to-harvest; throughput-based run goal with ecosystem scoring (S/A/B/C/D grades).**

This is the implementation spec for the first playable. It is a concrete narrowing of [GAMEPLAY_DESIGN.md](GAMEPLAY_DESIGN.md) — the prototype validates the core loop before any v2 work is scoped.

Locked 2026-05-27. Updated 2026-06-06 (Phase 19: team loadout, RPG stats, stat leveling, ecosystem scoring).

---

## 1. Scope

| Aspect | Decision |
|---|---|
| Biome | **Wetland** (`data/biomes/wetland.tres`), themed Carboniferous "coal swamp." |
| Team loadout | Pick **3 species** at run start — one **Producer**, one **Harvester**, one **Recycler** |
| Total species | 7 Carboniferous species across 3 roles |
| Active engagement | ~5–10 minutes total across 4–6 checkpoints |
| Wall-clock run length | 4–12 hours (mostly idle) |
| Run end | Sustain **+5.0 biomass/s** for **30 consecutive ticks** after cycle closure |
| Ecosystem grade | S/A/B/C/D based on throughput (40%) + diversity (30%) + sustainability (30%) |

### Species by role

| Role | Species | Notes |
|---|---|---|
| Producer | Calamites (free starter), Tree Fern, Lepidodendron | Plants — consume nutrients, produce biomass + decay |
| Harvester | Arthropleura, Meganeura | Animals — consume biomass, auto-harvest to hero counter |
| Recycler | Mycorrhizal Network, Prototaxites | Fungi — consume decay, produce nutrients |

---

## 2. Resource model — per-tile local flow

Resources flow **locally between adjacent tiles**, not through global pools.

### Per-tile output buffer

Every occupied tile has an output buffer (cap 50 units). Each tick, the species produces resources into its own buffer based on its tick_yield, throttled by local input satisfaction. When the buffer is full, excess biomass drips to hero at 25% efficiency (overflow).

### Soil nutrients & depletion

Each tile starts with 120 soil nutrients. Plants consume soil each tick after a 60-tick grace window (new tiles produce freely for ~1 minute). When soil depletes, production drops to a 20% ambient floor. Mycorrhizal fungi restore soil by draining nutrients from their own buffer and distributing them to adjacent plant tiles (symbiotic auto-transfer). Manual harvesting returns 10% of drained biomass back to soil (harvest kickback).

### Resource flow direction

```
SOIL → plants → BIOMASS buffer → animals drain adjacent → HERO
                   ↓ (detritus side output)
              fungi consume → NUTRIENTS buffer → adjacent plant soil
```

| Resource | Produced by | Consumed by | Flow |
|---|---|---|---|
| **Nutrients (N)** | Fungi | Plants (via soil) | Fungi buffer → adjacent plant soil (auto-transfer) |
| **Biomass (B)** | Plants | Animals + player harvest | Plant buffer → adjacent animal consumption OR player tap |
| **Detritus (D)** | Animals + plants (side output) | Fungi | Produced to buffer, consumed by adjacent fungi |

### Bootstrapping

Plants start at full production rate from ambient soil nutrients (120 units). No global starter pool needed — the soil IS the bootstrap. A 60-tick grace window lets new tiles produce freely. After the grace window, soil depletes, creating urgency to place fungi before production collapses to the 20% floor.

---

## 3. Biomass wallet & run goal

### Biomass as currency (not score)

Hero biomass is a **wallet** — spend it to place species. It increases through extraction, decreases on placement.

| Source | Mechanic |
|---|---|
| **Player tap-to-harvest** | Tap any occupied tile → drain its buffer, add biomass to wallet. Combo: +10%/level, max +50%. Harvesting returns 10% to soil. |
| **Animal auto-harvest** | Animals consume adjacent biomass each tick → consumed amount adds to wallet |
| **Buffer overflow** | Full buffers drip to wallet at 25% efficiency |

### Run goal: sustained throughput

The run completes when the ecosystem sustains **+5.0 biomass/s** for **30 consecutive ticks** after cycle closure. This replaces the old "accumulate 15k biomass" target.

A goal progress bar on the HUD shows sustained ticks / 30. If throughput drops below threshold, the counter resets.

### Ecosystem scoring

A composite grade (S/A/B/C/D) evaluates the run:
- **Throughput** (40%): rolling average biomass/s over 30 ticks, normalized to 10.0/s = 100%
- **Diversity** (30%): species placed / total available in era
- **Sustainability** (30%): average input satisfaction across all tiles

Grade thresholds: S ≥ 90, A ≥ 75, B ≥ 60, C ≥ 40, D < 40. Grade multiplies prestige rewards (S = 2x, A = 1.5x, B = 1x, C = 0.75x, D = 0.5x).

---

## 4. Species rates (sketch — to playtest)

All rates fill per-tile output buffers (cap 50). Production throttles based on local input satisfaction.

| Species | Role | Output (to buffer) | Input | Notes |
|---|---|---|---|---|
| **Calamites** (starter) | Producer | +2.0 B/tick, +0.2 D/tick | -1.0 N/tick (from soil) | Free to introduce; colonize cost 5 biomass |
| **Tree Fern Psaronius** | Producer | +1.2 B/tick, +0.15 D/tick | -0.6 N/tick (from soil) | Introduce 25 biomass; colonize 8 |
| **Lepidodendron** | Producer | +1.8 B/tick, +0.25 D/tick | -1.2 N/tick (from soil) | Premium producer; introduce 80 biomass |
| **Mycorrhizal Network** | Recycler | +1.5 N/tick | -1.5 D/tick from adjacent tiles | Auto-transfers N to adjacent plant soil |
| **Prototaxites** | Recycler | +1.0 N/tick | -1.0 D/tick from adjacent tiles | Introduce 60 biomass |
| **Arthropleura** | Harvester | +1.5 D/tick | -1.5 B/tick from adjacent tiles | Consumed B → hero counter (auto-harvest) |
| **Meganeura** | Harvester | +0.8 D/tick | -1.0 B/tick from adjacent tiles | Consumed B → hero counter; introduce 50 biomass |

### Throttling rule

Per-tile input satisfaction (0.0–1.0) scales production. A plant with depleted soil produces at 20% (ambient floor). A fungus with no adjacent detritus produces nothing. Throttle is visible via buffer fill bars (green/yellow/red).

### Initial single-species behavior (hero only)

- Calamites starts at full rate from ambient soil (120 units, 60-tick grace window).
- After grace window, soil depletes → production drops to 20% ambient floor.
- Player must place fungi before soil runs out, or manually harvest the diminishing buffer.
- Calamites produces 0.2 D/tick from litter — slow bootstrap for fungi.

### Post-cycle-closure steady state

With all 3 species placed adjacently:
- Fungi drain D from adjacent buffers, produce N, auto-transfer to adjacent plant soil → soil replenished
- Plants produce at full rate, buffers fill → animals drain adjacent biomass → hero counter rises
- Player can also tap-harvest plant tiles for bonus hero biomass

### Profitable consumer rule

Adding a consumer is **a short-term cost, long-term gain**:
- Placement deducts hero biomass (immediate visible dip — see § 5)
- The grazer drains adjacent plant buffers → that biomass goes to hero counter (auto-harvest)
- Grazer produces D → fungi can operate → soil stays replenished → plants stay at full rate
- Net: hero counter rate **increases** post-grazer via auto-harvest + sustained soil

---

## 5. Placement costs

Every placement (except the initial hero spawn, which is free) costs hero biomass:

| Action | Cost |
|---|---|
| Initial Calamites | **Free** (run starter) |
| Tree Fern Psaronius | 25 introduce + 8/tile |
| Lepidodendron | 80 introduce + 15/tile |
| Mycorrhizal Network | 30 introduce + 6/tile |
| Prototaxites | 60 introduce + 12/tile |
| Arthropleura | 50 introduce + 8/tile |
| Meganeura | 50 introduce + 10/tile |

Placement cost is visible — the hero counter ticks DOWN by the cost amount on placement, then resumes its production tick. This is the "short-term hit" the player feels before long-term gain kicks in.

---

## 6. UI — what the player sees

**HUD (top bar):**
- **Throughput rate** (primary, large): "+X.X/s" with trend arrow (^ green rising, v red falling)
- **Biomass wallet** (secondary, small): "Wallet: X" — currency for placement
- **Goal progress bar**: thin bar showing sustained ticks / 30
- **Ecosystem grade badge**: S/A/B/C/D letter, color-coded (gold/green/blue/gray/red)
- **Ecosystem name**: Coal Swamp

**Species panel (bottom dock):**
- Introduced species as 48x48 icon buttons with level badge + role label (Producer/Harvester/Recycler)
- "+" button opens stat choice popup: Production / Efficiency / Resistance / Spread
- Available species section (collapsible) with role tags and P/C stat preview
- Tooltip shows full stat card: Prod/Cons/Res/Spr + kingdom-specific stat

**Per-tile (on-canvas):**
- **Buffer fill bar**: thin bar at tile bottom, fills left→right (green → yellow → red), pulses when full
- **Species color outline**: 1.5px border in species.tile_marker_color around occupied tiles
- **Flow arrows**: lines between adjacent producer→consumer tiles showing active resource transfer
- **Harvest floats**: "+X" labels drift up when tapping (combo scales size/color) or animals auto-harvest (amber)

**Interaction:**
- Tapping an empty tile colonizes it with the selected species (costs biomass)
- Tapping an occupied tile harvests its buffer → biomass wallet increases
- Consecutive taps within 2s build combo for bonus harvest (+10%/level, max +50%)

**No HUD counters for N, B, D.** The player diagnoses bottlenecks by *looking at the canvas* — buffer bars and flow arrows tell you which tiles are starving.

---

## 7. Active/idle rhythm — checkpoint cadence

With team loadout, all 3 species are available from run start. Checkpoints nudge the player to place each role and respond to bottlenecks.

| # | Trigger | What player does |
|---|---|---|
| CP1 | t=0 | Place producer on starting tile |
| CP2 | Producer placed | Place recycler (fungi) adjacent to producer |
| CP3 | Recycler placed | Place harvester (animal) adjacent to producer → cycle closes |
| CP4 | 3+ tiles starving after cycle closure | Bottleneck nudge: expand the throttled role |
| CP5 | 3+ tiles starving (detritus) | Bottleneck nudge: more recyclers |
| CP6 | Throughput sustained for 30 ticks | Run complete. Ecosystem graded. Prestige. |

Total active engagement: ~5–8 minutes spread across 4–12 hours of wall-clock.

**Player can always place species manually** between checkpoints — checkpoints are suggestions, not gates.

---

## 8. Known risks — to watch in playtest

1. **Local flow adjacency may be hard to discover.** Players need to learn that species must be placed adjacent to interact. Mitigation: onboarding text + flow arrows make adjacency visible.
2. **Team picker with limited species may feel restrictive.** With only 7 Carboniferous species (3 producers, 2 harvesters, 2 recyclers), some slots have limited choice. More species in v2.
3. **Checkpoints may feel arbitrary if too rigid.** Mitigation already in spec: checkpoints are suggestions, manual placement always allowed.
4. **Throughput goal may be hard to understand.** Mitigation: goal progress bar + tooltip explaining the threshold. The "sustained ticks" mechanic rewards stable ecosystems, not spike-and-crash.
5. **Tap-to-harvest may feel tedious at scale.** Animals auto-harvest to reduce the need for manual tapping. If still tedious, consider area-harvest or harvest-all button as v2 feature.
6. **Buffer bar visual clutter** with many tiles. Current implementation redraws every frame for pulse animation — may need optimization for large grids.

---

## 9. Open questions deferred to playtest

1. **Numbers (everything in § 4 and § 5)** — rates and costs are sketches. Tune after first run.
2. **Throughput threshold (5.0/s) and sustained ticks (30)** — may need tuning. Too easy = no challenge; too hard = frustrating idle wait.
3. **Bottleneck detection thresholds** — "3+ tiles satisfaction < 0.3" is a guess. Refine based on actual sim behavior.
4. **Grade thresholds** — S≥90, A≥75, B≥60, C≥40 need playtesting. May need per-era tuning.
5. **Buffer cap tuning (50)** — may need to vary by species or scale with cluster size.
6. **Stat derivation formulas** — current formulas produce reasonable 1-10 values but may cluster too tightly once more species exist.

---

## 10. Out of scope for the prototype

Anything beyond § 1–7 is **explicitly out**:
- Multiple biomes
- Multiple starter species / hero choice
- Predator species (4th animal)
- Era forks
- Trait drafting / mutations
- Symbiont duos
- Tier-list mode
- TierZoo voice
- Lineage Tree visualization (a flat list of completed runs is sufficient)

These exist in [GAMEPLAY_DESIGN.md](GAMEPLAY_DESIGN.md) as v2+ scope and should not be hooked in pre-emptively.
