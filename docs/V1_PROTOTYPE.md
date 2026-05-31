# Bio v1 Prototype — locked spec

> **Single-hero Carboniferous wetland; 3 species, one per ecological role; per-tile local resource flow; tap-to-harvest; checkpoint-paced active/idle rhythm.**

This is the implementation spec for the first playable. It is a concrete narrowing of [GAMEPLAY_DESIGN.md](GAMEPLAY_DESIGN.md) — the prototype validates the core loop before any v2 work is scoped.

Locked 2026-05-27. Updated 2026-05-31 (Phase 18: local flow + tap-to-harvest).

---

## 1. Scope

| Aspect | Decision |
|---|---|
| Biome | **Wetland** (`data/biomes/wetland.tres`), themed Carboniferous "coal swamp." No new biome file; flavor only. |
| Hero species (locked for prototype) | **Tree fern stem** — plant role, iconic Carboniferous |
| Supporting species (NPC) | **Mycelium thread** (decomposer) + **Common grazer** (consumer) |
| Total species | 3 — one per role |
| Active engagement | ~5–10 minutes total across 4–6 checkpoints |
| Wall-clock run length | 4–12 hours (mostly idle) |
| Run end | Hero biomass ≥ 15,000 (number subject to playtest tuning) |

A **predator** (4th species, animal role) is a candidate for adding *after* the first prototype playtests well. Common grazer can later be re-themed/renamed to Arthropleura or similar Carboniferous-appropriate species — flavor only, no mechanical change.

---

## 2. Resource model — per-tile local flow

Resources flow **locally between adjacent tiles**, not through global pools.

### Per-tile output buffer

Every occupied tile has an output buffer (cap 20 units). Each tick, the species produces resources into its own buffer based on its tick_yield, throttled by local input satisfaction. When the buffer is full, production stalls.

### Soil nutrients & depletion

Each tile starts with 60 soil nutrients. Plants consume soil each tick; when soil depletes, production drops to a 20% ambient floor. Mycorrhizal fungi restore soil by draining nutrients from their own buffer and distributing them to adjacent plant tiles (symbiotic auto-transfer).

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

Plants start at full production rate from ambient soil nutrients (60 units). No global starter pool needed — the soil IS the bootstrap. Depletion over ~60 ticks creates urgency to place fungi before production collapses to the 20% floor.

---

## 3. Hero biomass counter — extraction only

Hero biomass increases **only** through extraction:

| Source | Mechanic |
|---|---|
| **Player tap-to-harvest** | Toggle to Harvest mode, tap an occupied tile → drain its buffer, add biomass to hero counter |
| **Animal auto-harvest** | Animals consume biomass from adjacent plant buffers each tick → consumed amount adds to hero counter |

Hero biomass decreases when the player spends it as a placement cost (see § 5). There is no passive hero income — without harvesting or animals, the counter stays flat even while production fills tile buffers.

---

## 4. Species rates (sketch — to playtest)

All rates fill per-tile output buffers (cap 20). Production throttles based on local input satisfaction.

| Species | Role | Output (to buffer) | Input | Notes |
|---|---|---|---|---|
| **Tree fern stem** (hero) | Plant | +2.0 B/tick | Soil nutrients (depletes over ~60 ticks) | Also +0.2 D/tick from leaf litter |
| **Mycelium thread** | Fungus | +1.5 N/tick | -1.5 D/tick from adjacent tiles | Auto-transfers N to adjacent plant soil |
| **Common grazer** | Animal | +1.5 D/tick | -1.5 B/tick from adjacent plant buffers | Consumed B goes to hero counter (auto-harvest) |

### Throttling rule

Per-tile input satisfaction (0.0–1.0) scales production. A plant with depleted soil produces at 20% (ambient floor). A fungus with no adjacent detritus produces nothing. Throttle is visible as the tile status overlay (green/yellow/red).

### Initial single-species behavior (hero only)

- Tree fern starts at full rate from ambient soil (60 units).
- Soil depletes over ~60 ticks → production drops to 20% ambient floor.
- Player must place fungi before soil runs out, or manually harvest the diminishing buffer.
- Tree fern produces 0.2 D/tick from litter — slow bootstrap for fungi.

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
| Initial hero tree fern | **Free** (run starter) |
| Additional tree fern | 50 hero biomass |
| Mycelium thread | 30 hero biomass |
| Common grazer | 50 hero biomass |

Placement cost is visible — the hero counter ticks DOWN by the cost amount on placement, then resumes its production tick. This is the "short-term hit" the player feels before long-term gain kicks in.

---

## 6. UI — what the player sees

**HUD:**
- Hero biomass counter (top): cumulative number + current rate (e.g., `1,392 (+2.5/s)`)
- Mode toggle button: switches between **Place** and **Harvest** mode

**Per-tile (on-canvas):**
- **Buffer fill bar**: thin bar at tile bottom, fills left→right (green → yellow → red), pulses when full
- **Species color outline**: 1.5px border in species.tile_marker_color around occupied tiles
- **Status overlay**: green/yellow/red dot showing input satisfaction (producing/throttled/starving)
- **Flow arrows**: lines between adjacent producer→consumer tiles showing active resource transfer

**Mode toggle:**
- In **Place** mode: tapping a tile colonizes it (costs hero biomass)
- In **Harvest** mode: tapping an occupied tile drains its buffer → hero biomass increases

**No HUD counters for N, B, D.** The player diagnoses bottlenecks by *looking at the canvas* — red status dots and empty buffer bars tell you which tiles are starving.

---

## 7. Active/idle rhythm — checkpoint cadence

Checkpoints are triggered by **either** a biomass milestone **or** a bottleneck condition (whichever fires first). They are **suggestions, not gates** — the player can place any unlocked species at any time if they can pay the cost.

| # | Trigger | Active duration | What player does |
|---|---|---|---|
| CP1 | t=0 | ~30 sec | Place hero tree fern on a starting tile |
| CP2 | Hero biomass ≥ 50 OR 3+ tiles satisfaction < 0.3 | ~30 sec | Place mycelium thread |
| CP3 | Hero biomass ≥ 500 OR 3+ tiles satisfaction < 0.3 | ~30 sec | Place common grazer → cycle closes (visible glow) |
| CP4 | 3+ tiles satisfaction < 0.3 after cycle closure | ~1 min | Bottleneck nudge: place additional support of the throttled role |
| CP5 | Hero biomass ≥ 5,000 | ~1 min | Optional expansion: place additional cluster of any species |
| CP6 | Hero biomass ≥ 15,000 | ~30 sec | Run end. Bank Evolution. |

Total active engagement: ~5–8 minutes spread across 4–12 hours of wall-clock. Players who actively engage finish faster; pure idle players finish overnight.

**Player can always place additional species manually** between checkpoints — checkpoints are just attention prompts, not the only way to act.

---

## 8. Known risks — to watch in playtest

1. **Local flow adjacency may be hard to discover.** Players need to learn that species must be placed adjacent to interact. Mitigation: onboarding text + flow arrows make adjacency visible.
2. **One species per role may feel monotone.** Variety lands in v2 (multiple plants, multiple fungi, multiple animals).
3. **Checkpoints may feel arbitrary if too rigid.** Mitigation already in spec: checkpoints are suggestions, manual placement always allowed.
4. **Hero counter going DOWN on placement may feel bad** to incremental-game players who expect monotonic growth. Mitigation: prominent tooltip framing it as investment; the recovery + overshoot should arrive within a minute.
5. **Tap-to-harvest may feel tedious at scale.** Animals auto-harvest to reduce the need for manual tapping. If still tedious, consider area-harvest or harvest-all button as v2 feature.
6. **Buffer bar visual clutter** with many tiles. Current implementation redraws every frame for pulse animation — may need optimization for large grids.

---

## 9. Open questions deferred to playtest

1. **Numbers (everything in § 4 and § 5)** — rates and costs are sketches. Tune after first run.
2. **Run-end target (15,000 biomass)** — may be too high or too low. Adjust to land at ~overnight + a bit of next-day play for a casual player.
3. **Bottleneck detection thresholds** — "3+ tiles satisfaction < 0.3" is a guess. Refine based on actual sim behavior.
4. **Visual cycle-closure feedback** — what does the glow look like? Animation, sound, banner copy? Decided in implementation.
5. **Buffer cap tuning (20)** — may need to vary by species or scale with cluster size.

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
