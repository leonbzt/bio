# Bio v1 Prototype — locked spec

> **Single-hero Carboniferous wetland; 3 species, one per ecological role; 3 interlocking nutrient resources; checkpoint-paced active/idle rhythm.**

This is the implementation spec for the first playable. It is a concrete narrowing of [GAMEPLAY_DESIGN.md](GAMEPLAY_DESIGN.md) — the prototype validates the core loop before any v2 work is scoped.

Locked 2026-05-27.

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
| Run end | Hero biomass ≥ 100,000 (number subject to playtest tuning) |

A **predator** (4th species, animal role) is a candidate for adding *after* the first prototype playtests well. Common grazer can later be re-themed/renamed to Arthropleura or similar Carboniferous-appropriate species — flavor only, no mechanical change.

---

## 2. Resource model — three global pools (Option A)

The whole map shares **three resource pools**:

```
NUTRIENTS → plants → BIOMASS → animals → DETRITUS → fungi → NUTRIENTS
   (N)                  (B)                  (D)
```

| Resource | Produced by | Consumed by | Biological reading |
|---|---|---|---|
| **Nutrients (N)** | Fungi | Plants | Recycled minerals in soil |
| **Biomass (B)** | Plants | Animals | Sugars / leaves / edible plant mass |
| **Detritus (D)** | Animals (waste) + dead plants (small side output) | Fungi | Dung, carcasses, fallen litter |

Pools are **global** for the prototype — no per-tile flows. Spatial flows (Option B / C) are explicitly deferred. Risk: this may feel too abstract / not Factorio enough — see § 8.

### Starter pools

On run start, all three pools are seeded with 50 units each so the cycle can bootstrap before any species is placed.

---

## 3. Hero biomass counter — how it relates to the sim

Two distinct things share the name "biomass." Keep them apart:

| Concept | Definition | Visible to player |
|---|---|---|
| **Hero biomass counter (HUD)** | Cumulative biomass produced by the player's hero species, minus placement costs | **Yes — the only HUD number** |
| **Global B pool** | Current stock of edible plant matter in the ecosystem; animals drain it, plants refill it | **No** (visible only via cluster bars showing availability — see § 6) |

The hero counter increases monotonically from production, decreases only when the player spends it as a placement cost (see § 5). Animal consumption from the B pool does **not** reduce the hero counter — the hero counter tracks *production*, not stockpile.

---

## 4. Species rates (sketch — to playtest)

| Species | Role | Output | Input | Notes |
|---|---|---|---|---|
| **Tree fern stem** (hero) | Plant | +2.0 B/sec to pool, +2.0 to hero counter | -1.0 N/sec | Also +0.2 D/sec from leaf litter (bootstrap path for fungi without animals) |
| **Mycelium thread** | Fungus | +1.5 N/sec | -1.5 D/sec | Stalls if D pool empty |
| **Common grazer** | Animal | +1.5 D/sec | -1.5 B/sec | Stalls if B pool empty |

### Throttling rule

If any species' input pool is empty (= 0), it produces nothing that tick. This is the bottleneck mechanic — the chain runs at the rate of the slowest link.

### Initial single-species behavior (hero only, no supports yet)

- Tree fern consumes 1.0 N/sec; starter N pool of 50 lasts ~50 sec at full output.
- Tree fern produces 0.2 D/sec from leaf litter — slow bootstrap path for mycelium.
- Without mycelium: N pool depletes, hero stalls. **First checkpoint** must fire before this happens to keep player engaged.

### Post-cycle-closure steady state

With all 3 species placed and balanced:
- N pool stable; mycelium produces 1.5/sec, plants consume 1.0/sec → small surplus
- B pool stable; plants produce 2.0/sec, grazers consume 1.5/sec → small surplus going to hero counter
- D pool stable; grazers produce 1.5/sec + plant litter 0.2/sec, mycelium consumes 1.5/sec → small surplus
- Hero counter rate: ~2.0/sec sustainable

### Profitable consumer rule

Adding a consumer is **a short-term cost, long-term gain**:
- Placement deducts hero biomass (immediate visible dip — see § 5)
- The grazer eats B that would otherwise sit in pool (no direct hero counter loss, but pool dips)
- Grazer produces D, which un-starves mycelium, which produces more N, which lets plants run at full speed
- Net: hero counter rate **increases** post-grazer despite short-term placement cost

Tooltip copy when placing the grazer should make this explicit: *"Grazers eat plant biomass and produce detritus — feeding the fungi that keep your soil rich. Short-term cost, long-term gain."*

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
- Hero biomass counter (huge, top): cumulative number + current rate (e.g., `47,392 (+8.5/sec)`)
- Nothing else.

**Per-cluster (on-canvas):**
- Small input-availability indicator: green pulse = producing, yellow = throttled, red = starving
- Hover tooltip: current input/output rates and what the species needs

**No HUD counters for N, B, D, or detritus.** The player diagnoses bottlenecks by *looking at the canvas* — red clusters tell you which role is starving.

---

## 7. Active/idle rhythm — checkpoint cadence

Checkpoints are triggered by **either** a biomass milestone **or** a bottleneck condition (whichever fires first). They are **suggestions, not gates** — the player can place any unlocked species at any time if they can pay the cost.

| # | Trigger | Active duration | What player does |
|---|---|---|---|
| CP1 | t=0 | ~30 sec | Place hero tree fern on a starting tile |
| CP2 | Hero biomass ≥ 50 OR N pool ≤ 5 for 60 sec | ~30 sec | Place mycelium thread |
| CP3 | Hero biomass ≥ 500 OR D pool ≤ 5 for 60 sec | ~30 sec | Place common grazer → cycle closes (visible glow + ×1.5 throughput) |
| CP4 | Any pool starved 5+ minutes after cycle closure | ~1 min | Bottleneck nudge: place additional support of the throttled role |
| CP5 | Hero biomass ≥ 5,000 | ~1 min | Optional expansion: place additional cluster of any species |
| CP6 | Hero biomass ≥ 100,000 | ~30 sec | Run end. Bank Evolution. |

Total active engagement: ~5–8 minutes spread across 4–12 hours of wall-clock. Players who actively engage finish faster; pure idle players finish overnight.

**Player can always place additional species manually** between checkpoints — checkpoints are just attention prompts, not the only way to act.

---

## 8. Known risks — to watch in playtest

1. **Global pools may feel too abstract.** No spatial strategy means it may not deliver Factorio feel. Mitigation: escalate to local-zone resource flows (Option B from design discussion) if playtest confirms — cheap upgrade if the global core is already proven.
2. **One species per role may feel monotone.** Variety lands in v2 (multiple plants, multiple fungi, multiple animals).
3. **Checkpoints may feel arbitrary if too rigid.** Mitigation already in spec: checkpoints are suggestions, manual placement always allowed.
4. **Hero counter going DOWN on placement may feel bad** to incremental-game players who expect monotonic growth. Mitigation: prominent tooltip framing it as investment; the recovery + overshoot should arrive within a minute.
5. **D-from-plants bootstrap (+0.2 D/sec)** may be too small to keep mycelium meaningfully alive pre-grazer. Tune up if mycelium feels dead between CP2 and CP3.

---

## 9. Open questions deferred to playtest

1. **Numbers (everything in § 4 and § 5)** — rates and costs are sketches. Tune after first run.
2. **Run-end target (100,000 biomass)** — may be too high or too low. Adjust to land at ~overnight + a bit of next-day play for a casual player.
3. **Bottleneck detection thresholds** — "pool ≤ 5 for 60s" is a guess. Refine based on actual sim behavior.
4. **Visual cycle-closure feedback** — what does the glow look like? Animation, sound, banner copy? Decided in implementation.
5. **Cluster bar visual design** — green/yellow/red is the proposal; exact rendering TBD.

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
- Per-tile or zonal resource flows
- Lineage Tree visualization (a flat list of completed runs is sufficient)

These exist in [GAMEPLAY_DESIGN.md](GAMEPLAY_DESIGN.md) as v2+ scope and should not be hooked in pre-emptively.
