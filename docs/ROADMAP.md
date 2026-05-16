# Development Roadmap

## Status legend
- ✅ **Done**: shipped on `main`.
- 🔄 **In progress**: briefs written, implementation underway.
- 📋 **Planned**: briefs not yet written.
- 💭 **Aspirational**: directionally agreed; commit only after upstream phases prove themselves.

---

## MVP — Phases 1–7 ✅

Single-player Android-first build. Plantae + Fungi + Symbiosis (as a kingdom), prestige loop, evolution tree, herbivore wave + Toxin Bloom defense, save versioning, corpse decay, spore infection, audio + music, save backup rotation, Play Console internal beta.

| Phase | Goal | Status |
|---|---|---|
| 1 | Foundation: Godot, autoloads, save, HUD | ✅ |
| 2 | Plant prototype: territory, biomes, growth, offline catch-up | ✅ |
| 3 | Active gameplay: events, herbivores, Toxin Bloom | ✅ |
| 4 | Prestige + flat evolution tree + kingdom selection | ✅ |
| 5 | Fungi kingdom, dual-layer tiles, corpse decay, spore infection | ✅ |
| 6 | Symbiosis (as kingdom), layer toggle, growth bonus, mutualism | ✅ |
| 7 | Polish: cleanup, drought/cool_spell, audio, backups, perf, balance, release | 🔄 |

**Exit**: 5 testers complete a plantae → fungi → symbiosis cycle on the internal-test track.

---

## TIER 1 — Make the MVP a real game (Phases 8–10)

**Target**: 2–3 months. Transforms the MVP from "complete demo" to "shippable indie game with replay depth". Most leverage per unit of effort.

Order chosen by dependency and to minimize concurrent refactors.

### Phase 8 — Niche system *(planned)*
The single highest-leverage addition. See `NICHES.md`.

**Deliverables**:
- `NicheData` resource + `data/niches/_index.tres`.
- 3 plantae niches (Photosynthesizer / Carnivore / Parasite). Pollinator-host deferred until insect agents land.
- 2–3 fungi niches (Decomposer / Parasite / Mycorrhizal).
- Niche-aware colonization (a `ColonizationRulesRegistry` swaps logic per niche).
- Run-setup UI: kingdom → niche → species cascading selection.
- `GameState.current_niche_id` field + save schema bump.
- Small visual: each niche has a distinct overlay color/icon variant in HUD.

**Exit**: each kingdom has at least 2 niches playable. Carnivore plantae plays measurably differently from Photosynthesizer plantae.

### Phase 9 — Interconnected progression web *(planned)*
See `PROGRESSION_WEB.md`.

**Deliverables**:
- `EvolutionNodeData` gains `wing`, `tier`, `requires_kingdom_played` fields.
- Existing 8 nodes tagged with wings/tiers.
- ~10–15 new cross-kingdom nodes authored to seed the web.
- Tree visualization UI redo: wings as columns, prereq lines drawn across, locked-but-visible nodes for teasing.
- Discovery log scaffold (see `STORY_AND_TONE.md`) with entries for every kingdom/niche/event milestone.

**Exit**: a fungi run is mechanically rewarding for a plantae-focused player and vice versa. Discovery log has ≥ 25 entries.

### Phase 10 — Symbiosis reframe + Animal kingdom foundation *(planned)*
See `GAME_VISION.md` and `KINGDOMS.md`.

**Deliverables**:
- Symbiosis reframe: `SpeciesData` gains symbiotic partner fields. `unlock_symbiosis` evolution node → `unlock_lichen` (grants species, not kingdom). Lichen species drives dual-layer mode.
- Symbiosis kingdom_id stays internally but hides from UI; PrestigeSystem.start_run sets it automatically when a symbiotic species is chosen.
- Migration: existing saves with `&"symbiosis"` in unlocked_kingdoms migrate cleanly.
- Animal kingdom *foundation*: kingdom registration, one species (generic herbivore), one niche (Herbivore). Animal organisms exist as mobile range-tile occupants — initial implementation can reuse herbivore mover logic.
- Insect agents as the first cross-kingdom autonomous agent (passive boosts to pollinator-host plant tiles).
- Light graphics pass: niche icons, animal sprites at placeholder quality.

**Exit**: a player can play a Lichen run (no kingdom called "symbiosis" in the UI), and an Animal Herbivore run. Insects appear in some plant runs based on niche.

---

## TIER 2 — Era + ecosystem progression (Phases 11–14)

**Target**: 3–4 months. Adds the time/world meta axis. See `ERAS_AND_ECOSYSTEMS.md`.

### Phase 11 — Era system + ecosystem selector
- `EraData` and `EcosystemData` resources.
- "World map" UI replacing the simple Play button: era + ecosystem selector.
- 2 eras to start (Cryogenian — fungi-only; Devonian — current MVP scope).
- 3 ecosystems per era; completion criteria; meta tracking.
- Era-transition narrative passages (see `STORY_AND_TONE.md`).

### Phase 12 — Ecosystem-specific biomes + events + graphics
- New biome types per era (tundra, mineral, swamp).
- Graphics pass: each era has visual identity (tile palettes, background, music variation).
- Era-locked events (mass extinction at era transitions).
- New evolution-tree nodes era-gated.

### Phase 13 — Predator + Scavenger niches for Animals; cordyceps niche for Fungi
- Animal kingdom matures with niche variety.
- Cross-niche interactions: predators reduce herbivore pressure on plant runs.
- Lifeforce resource fully online for parasitic fungi.

### Phase 14 — More symbiotic species
- Coral (animals × algae stand-in via plantae).
- Mycorrhizal forest (plantae × fungi capstone).
- Expanded discovery log entries — target 50+.

**Exit**: 3+ eras playable, ~30 hours of varied content, animals are a first-class kingdom.

---

## TIER 3 — Aspirational 💭

Commit to these only after Tier 2 ships and the audience justifies the work.

- **Multiple worlds**: alien planets, parallel petri dishes. Each world has its own era sequence with different ground rules (gravity, gases, resources).
- **Scale ascension**: cell-tier prequel (bacteria, viruses); planet-tier sequel (climate, atmospheres); civilization-tier endgame. Each is essentially a different game mode.
- **Microbial kingdom**: bacteria/archaea/protists. Operates on a faster tick. Plays as the substrate to all other kingdoms.
- **Civilization layer**: sentient species emerge; technology, agriculture, extinction — far horizon.
- **Cloud sync / leaderboards**: low priority. Offline-first stays the default.
- **iOS**: requires Mac + dev account. Optional always.

These are documented in `GAME_VISION.md` under "Deferred / aspirational" and referenced in discovery-log entries to seed narrative interest without committing engineering.

---

## How the roadmap is structured to avoid scope creep

- **One axis per tier.** Tier 1 adds the niche/web depth axis. Tier 2 adds the time axis. Tier 3 adds the world/scale axis. No tier tries to ship more than one new axis.
- **Each phase has a single exit criterion.** Phrased as a play-experience milestone, not a feature checklist.
- **Graphics are tied to content phases, not separate "polish" phases.** Niche icons in 8 and 10. Era visual identity in 11 and 12. Animation polish stays Tier 3.
- **Cross-kingdom features unlock incrementally.** Niches first (within-kingdom variety), then the web (between-kingdom progression), then eras (across-time progression), then worlds (across-place progression).

## Open questions for the user before Phase 8 starts

1. **Which niche to prototype first?** Plantae Carnivore is the most visceral mechanically. Fungi Mycorrhizal would test the symbiosis reframe simultaneously. Plantae Parasite has the most novel colonization rule (place on others). Pick one as the "test bed" for the niche system; the others fall in faster once the pattern is set.
2. **Niche-unlock gating**: are niches unlocked one-by-one (per evolution-tree node), or do you unlock the *concept* of niches once and then individual niches become available as you play? The former is more roguelike; the latter is more accessible.
3. **For the Animal foundation in Phase 10**, do you want Herbivore animals to *be* the existing herbivore-wave agents (so the wave is now a hostile playable kingdom on the other side), or a separate stat-block? Reusing them is cleaner; separating is more flexible.
