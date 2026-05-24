# Gameplay Design — Hero, Pressure, and the Two Clocks

> **You play a Hero species; active sessions expand the ecosystem; the ecosystem produces life while you sleep; pressure drains it whether you watch or not.**

This document specifies the gameplay shape of Bio. It builds on [GAME_VISION.md](GAME_VISION.md) (which establishes "you play life as a category" + kingdoms × niches × species + eras + ecosystems) and supersedes earlier per-run-goal sketches (the "boss" framing is replaced by the Pressure system below).

> **Terminology note (2026-05-22):** in this doc, **biome** = a large landscape with a unifying climate (e.g. Tundra, Frozen Crust, Inland Swamp) carrying its own Pressure. **Ecosystem** = a smaller substrate community within a biome (e.g. rich_soil, mineral_vent, peat) that flavors individual tiles. This matches real-world ecological terminology but **INVERTS the current code conventions** (Bio's codebase currently uses "biome" for substrate types and "ecosystem" for the larger container). A code/data rename is deferred until after the visual migration; until then, the docs use the new terminology and the code uses the old. Watch for the conflict.
>
> **Phase naming**: "Phase A/B/C" below refers to gameplay implementation phases. The visual migration uses VM-A/B/C (see `docs/MIGRATION_PLAN.md`) to disambiguate. The two phase systems are largely orthogonal.

---

## 1. Core principle — two clocks

The game runs on two clocks that progress on different timescales:

| Layer | What lives here | Clock | What ending means |
|---|---|---|---|
| **Active layer** | Hero + supports during a run | Active session time | Hero death = run ends |
| **Substrate layer** | Tree of Life, biomes, established populations | Real wall-clock time (incl. offline) | Never ends |

**Heroes die. Ecosystems persist.** Death matters at the run-layer; the world keeps spinning at the substrate-layer.

---

## 2. The three actors

Every run has three actors and only three:

| Actor | Role | HUD presence |
|---|---|---|
| **Hero species** | The player's avatar. One species, one stat sheet, one HP pool. | Big portrait + stat radar, top of HUD. |
| **Supporting ecosystem** | 3–8 species occupying tiles around the Hero, providing buffs/yield/cover/decomposition. | Smaller icons in action bar. |
| **Pressure (Antagonist)** | The biome's environmental drain. Reduces Hero HP at a configured rate. | Top banner, damage-type icon, timer/depth. |

Real ecology: a wolf needs deer (prey), grass (food for deer), fungi (decomposing kills), pines (cover). The Hero + Support model is how ecosystems actually work, and it's how MMOs work — class + party.

---

## 3. The Hero system

Each Hero has a stat sheet. Six core stats — biology-native, RPG-legible:

| Stat | Biological term | RPG analog | Role |
|---|---|---|---|
| **Mass** | Body size | HP | Damage capacity |
| **Speed** | Mobility | DEX | Movement, escape |
| **Predation** | Jaws / claws / venom | ATK | Kill damage |
| **Defense** | Armor / hide | DEF | Damage reduction |
| **Metabolism** | Energy efficiency | Mana regen | Resource cost per action |
| **Cognition** | Nervous system | INT | Niche flexibility, tool use |

Plus environmental **resistances** as sub-stats: cold, drought, heat, salt, predation, disease, decay. Each resistance is a % reduction against its damage type.

Heroes are drawn from the **Tree of Life** — each branch is a species you've unlocked across all runs. Starting a run = picking a branch and taking a cutting from it.

---

## 4. The supporting ecosystem

Up to 8 supporting species can be placed on tiles around the Hero. Each provides one or more roles:

| Role | Examples | Effect |
|---|---|---|
| **Resistance** | Pine, Lichen | Adjacency reduces an environmental damage type |
| **Yield** | Grass, Algae | Produces biomass passively |
| **Prey** | Deer, Insects | Hero hunts to gain protein resource |
| **Symbiosis** | Mycorrhiza | Paired buffs with specific Heroes |
| **Decomposition** | Fungus | Cleans up Hero kills, recycles biomass |
| **Distraction** | Filler plants | Absorbs predation, protects Hero core |

**Adjacency matters.** Pine next to the Hero tile = cold resistance. Deer next to Pine = grazing yield. Clusters compound.

---

## 5. The Pressure system

Pressure is the antagonist. It's a per-biome environmental drain that ticks constantly:

```
FROZEN CRUST — pressure ramp by stratum
  S1   10 cold/min
  S2   25 cold/min
  S3   60 cold/min
  S4  150 cold/min
  S5  400 cold/min  ← capstone
```

Mitigation is computed each tick as:

```
incoming = stratum_rate × (1 − hero_resistance) × (1 − adjacency_buff)
hero_HP -= incoming × dt
```

When `hero_HP → 0`, the run ends. **This is the single new mechanic that turns Bio from a placid idle game into a survival game.**

Pressure damage ticks **in both active and offline time**. The Hero takes damage whether you're watching or not.

---

## 6. Tier progression — short-term + long-term

Two scales of tiered progression run in parallel:

### Short-term — Pressure strata within a biome

Each biome has **5 strata** (S1 → S5) with escalating pressure (see above). You push deeper by surviving higher strata. Each cleared stratum:
- Permanently improves that biome's offline biomass income
- Unlocks the next stratum
- Top stratum (S5) is the **capstone** — one-time mythic reward (new Tree branch, Hero unlock, or Mythic-tier gene)

### Long-term — Eras

The game advances through eras (Cryogenian → Devonian → Carboniferous → ... → Anthropocene → speculative/alien). Each era:
- Unlocks new biomes on the Planet
- Unlocks new Hero archetypes
- Shifts the **Tier List meta** — old Heroes become less viable, new Heroes appear

**Eras advance silently.** No "Reach the Anthropocene" goal is ever announced — they just unfold as you accumulate adaptations.

The **Tier List** is rarity-aware AND era-aware. Common Wolf might be S-tier in Era 2 and D-tier in Era 5. Your old build gets patched out by the meta moving on — exactly the TierZoo dynamic.

---

## 7. Active sessions — what you do

| Action | Active only? | Effect |
|---|---|---|
| Place a new support tile | **YES** | The expansion lever — placed tiles tick offline forever |
| Hero hunts adjacent tile | **YES** | Hero acts when piloted |
| Tap Hero portrait | **YES** | Burst manual hunt — ~3s cooldown |
| Receive mutation prompt | **YES** | Picks 1 of 3 stat-boost options. Auto-defaults if ignored |
| Receive event prompt | **YES** | Crisis response. Auto-defaults if ignored |
| Biomass income ticks | All time | **2× during active, 1× offline** |
| Pressure damage ticks | All time | Continuous, unaffected by active/offline |

Active sessions are **5–30 minutes** of attention. The player composes, pilots, harvests, responds. Every active action **compounds** — placing a tile now means more biomass tomorrow morning.

---

## 8. Offline — what happens between sessions

When the app is closed:

- All placed tiles continue producing biomass at **1× rate** (capped at ~6–8 h of accumulation)
- The Hero rests — doesn't hunt, doesn't expand
- **Pressure continues to drain Hero HP** at full rate
- Mutation/event prompts queue silently OR auto-resolve using player-set defaults
- If pressure overwhelms the comp → Hero dies offline → run ends → discovered at next login

Offline is **maintenance mode**. The substrate provides; the Hero defends; the player is absent.

---

## 9. Why active >> offline (the compounding lever)

| Metric | Active | Offline |
|---|---|---|
| Biomass income | 2× | 1× (capped 6–8h) |
| New tile placement | Available | Disabled |
| Hero hunts / expansion | Available | Disabled |
| Manual tap bursts | Available | Disabled |
| Mutation prompts | Resolved live | Queued / auto-default |
| Pressure damage | Same rate | Same rate |

Active play yields ~3–4× the progress of equivalent offline time. The compounding effect — active-placed tiles produce passively forever — creates the "one more upgrade before bed" hook without punishing absence.

---

## 10. Death matters

| Event | Run-layer effect | Substrate-layer effect |
|---|---|---|
| Hero survives target stratum | Run wins. Mutation banks. | Tree branch grows. Biome heals on Planet. Patch note logged. |
| Hero dies before target | Run loses. Small failure XP on branch. | Population partially established stays on tile. May decay if neglected. |
| Biome neglected too long | — | Population decays. May extinct → biome reverts to barren. |
| Total biome extinction | — | Biome lost. Must be reconquered from zero. |

Failed runs cost the would-be mutation and active time. They don't nuke world progress. Long-term ecosystems are durable; per-run attempts are fragile.

---

## 11. Prestige = run resolution

Prestige is not a separate menu — it's the **run resolution event**. Every Hero death or stratum-clear triggers:

1. Hero resolves (success or death).
2. Mutation banks (if success) → Tree branch updates → permanent stat boost on that branch.
3. Biome state updates → Planet view changes.
4. Patch note logged → discoveries log appended.
5. Player returned to Compose phase for next run.

The Tree of Life and the Planet are the persistent meta. They never reset.

---

## 12. Rarity system (sketch — Phase C)

Each species has a rarity tier (gear-style):

```
COMMON      gray     baseline stats
UNCOMMON    green    +20% stats, +1 gene slot
RARE        blue     +50% stats, +2 gene slots
EPIC        purple   +100% stats, +3 gene slots, 1 ability
LEGENDARY   orange   +200% stats, +4 slots, 2 abilities
MYTHIC      gold     era-defining apex; unique ability
```

Acquired via:
- **Mutation drops** — post-run rolls, odds scale with stratum survived
- **Fusion** — 3 duplicates → next rarity (the "I have 2/3 wolves, one more run" loop)
- **Era unlocks** — new rarities appear as eras advance

---

## 13. Voice — TierZoo / patch notes

Text surfaces use a deadpan-analytical voice borrowed from TierZoo and r/outside, alongside the mythic flavor from `STORY_AND_TONE.md`:

```
DISCOVERY ENTRY
"Wolf — Cold tolerance trained. Boreal viability: A → A+.
Frozen Crust pressure unlocked."

DEATH SCREEN
"Wolf build deprecated. Glass cannon failed to scale into
late game. Try a sustain spec next run."

PATCH NOTES — ERA TRANSITION
"PATCH 47.2 — THE CARBONIFEROUS UPDATE
- Atmospheric oxygen: +30%. Insect builds: max size raised.
- Photosynthesis: efficiency rebalanced.
- Decomposer fungi: now spawn in Old-Growth structures."
```

The two voices alternate. Mythic for moments of weight; TierZoo for moments of mechanics.

---

## 14. The rhythm — a player's day

| Time | Action | Active duration | Player feels |
|---|---|---|---|
| Morning | Check overnight run, bank mutation, pick Hero/biome, place starting tiles, begin | 4 min | "Set up for the day" |
| Midday | Quick check, resolve a mutation prompt, place 2 more tiles | 2 min | "Compounded a bit" |
| Evening | Push frontier, resolve queued events, expand to new stratum | 15 min | "Real progress made" |
| Pre-bed | Final placement, set sustain comp for overnight | 3 min | "One more upgrade before bed" |
| Sleeping | Offline tick — pressure ramps, supports hold | — | — |

~25 active min/day in a game that ticks for 24h. Idle ratio: ~50:1.

---

## 15. Implementation priorities

### Phase A — sooner (mechanical core)

Foundation. Everything else stacks on top.

- Hero designation per run (one species flagged, gets stat sheet)
- Hero stat sheet (6 stats + resistances + HP pool)
- Pressure damage tick (per-biome environmental drain, both active and offline)
- Active vs. offline distinction (2× active biomass income, active-only tile placement)
- Hero auto-hunts adjacent yielding tiles during active play
- Mutation prompts (firing every ~60–90s of active play, 3-choice modal)
- Event prompts (sparse, with default-pick presets configurable in settings)
- Death-matters resolution (Hero HP → 0 = run end, even offline)
- Tree of Life — basic version (a list/menu of unlocked branches per kingdom, no fancy tree visual)
- Planet — basic version (a biome selector — list or simple icon row, no globe)
- **Short-term tier framework** — 5 strata per biome with pressure scaling, capstone marker
- **Long-term tier framework** — eras advance silently, gating biome and Hero unlocks

### Phase B — middle (engagement layers)

Layered on top once the Phase A loop feels good.

- **Active tap on Hero portrait** — burst biomass, ~3s cooldown
- **TierZoo voice** — rolled across all text surfaces (death screens, unlock popups, discoveries)
- **Tier List view** — ranks Heroes in the current meta (era × biome)
- **Rarity tier indicators** — visual labels (color + name) on species, base stats only (no fusion yet)
- **Patch notes log** — reframe the Discoveries log to alternate mythic + patch-note voice

### Phase C — later (depth and visual)

Final polish layer.

- **Full rarity system** — Common → Mythic with stat scaling and gene slots
- **Fusion mechanic** — 3 duplicates → next rarity
- **Depth strata fully fleshed** — capstone rewards, mythic gene drops, stratum-specific events
- **Tree of Life visual** — a real branching tree replaces the list view
- **Planet visual** — a real spinning globe replaces the biome selector
- **Era transitions** — animated patch-note moments at era boundaries

---

## 16. Out of scope

Owned by other docs or deferred:

- Scale ascension (cell → organism → ecosystem → planet) — `GAME_VISION.md`
- Multiple worlds / alien biospheres — `GAME_VISION.md`
- Sentient kingdom — far horizon
- Layered lifeforms (Lichen, Coral) — `GAME_VISION.md`; integrates with Hero system as multi-class Heroes in a future phase
- Monetization model — pre-launch decision
- Multiplayer / cloud sync — no plans

---

## 17. Resolved design questions (2026-05-22)

| # | Question | Resolution |
|---|---|---|
| 1 | Is the Hero anchored to ONE tile or to its species across all instances? | **Species-wide.** All tiles of the Hero species are Hero tiles; HP pool is shared. Adjacency mitigation applies when buff sources are next to *any* Hero tile. New tile placement can expand the Hero population. |
| 2 | Hero portrait — new commission, or reuse cluster art? | **Procedural placeholder for Phase A.** Real portrait commission deferred to Phase B or later. |
| 3 | Pressure damage-type icons (7 types) — commission or procedural? | **Procedural for Phase A.** Commission when alpha is shaping. |
| 4 | Multiple adjacency interaction types (symbiosis, resistance, yield, distraction) — same marker or distinct? | **Same marker shape, differentiated by color.** Start with: gold (symbiosis), and additional colors for other interaction types as they land. Tooltip carries the detail. |
| 5 | Cluster density × Pressure interaction — does maturity affect buff strength? | **Defer.** Cluster density is purely cosmetic for alpha. Maturity → mechanics interaction added later. |
| 6 | Era progression / "aging out" of tiles — what happens when a Hero's meta era passes? | **Defer until Phase C.** Long-term mechanic, doesn't block alpha. |

## 18. Alpha gate priorities (2026-05-22, Leon)

From the Phase A list, **MUST ship for alpha**:
- Hero designation per run + stat sheet
- Pressure damage tick (active + offline)
- Active vs offline distinction (2× active income; active-only tile placement)
- Mutation prompts (3-choice modal, auto-default if ignored)
- Event prompts (sparse, with default presets)
- Death-matters resolution (HP → 0 = run end, including offline)
- Planet basic selector (biome picker UI)

**NOT must-ship for alpha (defer to post-alpha)**:
- Strata (the 5-tier pressure ramp within a biome)
- Era progression (single-era alpha is fine; eras unlock later)
- Tier List view
- TierZoo voice rollout across text surfaces (placeholder voice is fine)
- Tree of Life — possibly defer to post-alpha if scope is tight

A formal `docs/ALPHA_GATE.md` is still pending. The priorities above are the current intent.

## 19. Glossary

| Term | Meaning |
|---|---|
| Hero | The single playable species in a run |
| Support / Supporting ecosystem | Species placed around the Hero providing buffs |
| Pressure | Per-biome environmental drain (the antagonist) |
| Stratum | A pressure tier within a biome (5 per biome) |
| Capstone | The S5 stratum's one-time reward |
| Era | Long-term game progression (Cryogenian → Anthropocene → ...) |
| Tree of Life | The persistent meta — all branches (species) unlocked across runs |
| Planet | The persistent world state — biomes and their health |
| Branch | A species/lineage on the Tree |
| Cutting | A "seed" taken from a branch to start a run |
| Mutation | A stat/trait gained at end of successful run; banks to a branch |
| Active session | Player has the app open and engaged |
| Offline | App closed; substrate ticks at 1× |
| Tier List | Rarity- and meta-aware ranking of available Heroes |
| Compose phase | Pre-run setup — pick Hero, supports, biome |
| Unfold phase | The run itself — mostly passive with bursty prompts |
| Resolve phase | Post-run — bank mutation, review patch notes |
