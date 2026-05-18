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
| 7 | Polish: cleanup, drought/cool_spell, audio, backups, perf, balance, release | 🔄 partial — see notes below |

**Exit**: 5 testers complete a plantae → fungi → symbiosis cycle on the internal-test track.

### Phase 7 status (as of Phase 8 plan)

| Brief | Status | Notes |
|---|---|---|
| 01 cleanup nits | ✅ | Shipped |
| 02 drought / cool_spell handlers | ✅ | Shipped via `AmbientModifierSystem` |
| 03 audio SFX | ✅ | Shipped |
| 04 audio music | ✅ | Crossfading per kingdom |
| 05 save robustness | ✅ | Tmp + backup rotation |
| 06 performance audit | 🟡 partial | Spot-checked, no formal device-perf pass |
| 07 balance pass | ⏭ skipped | Deferred to post-Tier-1 polish window |
| 08 release readiness | ⏭ skipped | Internal-beta release deferred until Tier 1 lands |

**Why this is OK**: Tier 1 (Phases 8–10) reshapes the play loop substantially (niches, the cross-kingdom progression web, symbiosis reframe, animals). Balancing or shipping a beta of the pre-niche game would burn time on numbers that are about to change. The Phase 7 exit criterion ("5 testers complete plant → fungi → symbiosis") is parked, not abandoned. Revisit after Phase 10's Lichen run + Animal foundation prove out — that's the new "first releasable surface area".

**What this means for testers**: no public/internal beta until after Phase 10. Solo dev-testing on personal device(s) only through Tier 1.

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

### Phase 9 — Interconnected progression web *(in progress, 10 briefs written 2026-05-16)*
See `PROGRESSION_WEB.md` and `STORY_AND_TONE.md`.

**Locked decisions (2026-05-16)**:
- Tree UI: single scrollable canvas, no tabs.
- `requires_kingdom_played`: hard purchase gate.
- Discovery log fires on all four sources: kingdom unlocks, niche first-play, evolution-node purchases, event first-fires + milestones.
- Locked entries are hidden; only the denominator hints at total count.
- Discovery entry voice text is authored by Claude directly in brief 07 (no Kilo flavor pass).
- No tree-node refunds / respec.

**Deliverables**:
- Save schema v5 → v6: `meta.discovery_log`, `meta.kingdoms_played`, `meta.niches_played`, `run.event_first_fires_seen`.
- `EvolutionNodeData` gains `wing`, `tier`, `requires_kingdom_played` fields.
- Existing 10 nodes tagged with wings/tiers.
- 12 new cross-kingdom nodes authored (~50% of mid+ tier nodes are cross-wing).
- Tree visualization UI: single scrollable canvas, wings as columns, prereq lines drawn via `Control._draw()`, lines colored by destination wing, gated nodes show informative tooltip.
- `DiscoveryLog` autoload + `EventBus.discovery_unlocked` signal + trigger wiring for all four sources.
- 28 authored discovery entries (above the ≥25 target) in mythic-scientific voice.
- Discovery log UI: pause-menu entry with denominator, full-screen overlay grouped by category, HUD toast on unlock.

**Exit**: a fungi run is mechanically rewarding for a plantae-focused player and vice versa. Discovery log has ≥ 25 entries.

### Phase 10 — Symbiosis reframe + Animal foundation + niche signatures *(planned)*
See `GAME_VISION.md` and `KINGDOMS.md`. Reshaped 2026-05-16, refined 2026-05-17 (Lichen → Fungi, hybrid niche+species model).

**Deliverables**:
- **Layered-lifeform foundation (hybrid niche+species model)**:
  - `NicheData` gains `expects_layered: bool` — flags niches that drive multi-layer placement.
  - `SpeciesData` gains `layer_count: int` and `layer_species: Array[SpeciesData]` — the layer count + per-layer roster.
  - The first 2-layer playable is **Lichen**, implemented as a niche under **Fungi** (biologically the fungus dominates structurally). Cascade at run start: Fungi → Lichen niche → Common Lichen species. The species carries `layer_count = 2`, `layer_species = [mycelium_thread, pioneer_grass]`.
  - `unlock_symbiosis` evolution node redirected to `unlock_lichen` (grants the Lichen niche, not a kingdom).
- **Retire symbiosis kingdom**: `&"symbiosis"` kingdom_id removed from UI and game state. Save migration v7 → v8 strips it from `unlocked_kingdoms`; any in-flight `current_kingdom_id == &"symbiosis"` migrates to `&"fungi"` with `current_niche_id = &"lichen"`.
- **Per-niche signature mechanics** for the two non-default niches (lifts the gap-1 finding from Phase 9 review):
  - **Parasite plantae**: gains a *biomass-steal* tick effect — adjacent non-parasite tiles lose a small biomass amount per tick that the parasite cluster gains. Replaces the flat 2× yield multiplier.
  - **Mycorrhizal fungi**: gains a *substrate-claim* placement mode — tap an existing plantae tile to bond with it, mutually boosting yield, instead of behaving almost identically to decomposer.
- **Animal kingdom foundation**: kingdom registration, one species (generic herbivore), one niche (Herbivore), one niche (Predator — per locked open question, ships in Phase 10 not 14). Herbivore animal is a **separate stat-block from the herbivore-wave agents**, not a reuse. Predator's prey selection deferred to Phase 14 polish.
- **Insect agents** as the first cross-kingdom autonomous agent (passive boosts to pollinator-host plant tiles; no playable pollinator niche yet).
- **Stub resources introduced** (no gameplay impact yet, just `ResourceLedger` IDs + **visible-but-greyed HUD display**): **Protein**, **Cellulose**, **Chitin**, **Phosphate**, **Lifeforce**, **Pollination**. Each is biologically grounded — see `GAME_VISION.md` resource section.
- Light graphics pass: niche icons, animal sprites at placeholder quality.

**3+ layer model deferred**: the layered-lifeform architecture supports any `layer_count`, but the *design decision* of whether 3+ layer packs are picked at run start (locked-yesterday "pre-authored packs" model) or dynamically assembled (pack + intra-run layer unlocks) is deferred to Phase 14 when Coral actually needs the answer. Lichen ships as 2-layer-only.

**Exit**: player can play a **Lichen** run as a Fungi niche (no kingdom called "symbiosis" in UI), and an **Animal Herbivore** and **Animal Predator** run. Parasite plantae *feels* parasitic (steals from neighbors). Mycorrhizal fungi *feels* mutualistic (must bond with plants). Insects appear in some plant runs based on niche. Stub resources visible in HUD.

---

## TIER 2 — World feedback + eras (Phases 11–15)

**Target**: 3–4 months. Adds the world-feedback layer first (the lightest cohesive phase), then the time/world meta axis. See `ERAS_AND_ECOSYSTEMS.md`.

### Phase 11 — World feedback layer *(briefs written 2026-05-16, scope refined 2026-05-17)*

The smallest cohesive phase in Tier 2. Three mutually reinforcing pieces that lift Pillar 5 (mobile tempo + active gameplay) and the "long arc" identity.

**Deliverables**:
- **Active-event interventions** — each ambient event (`drought`, `cool_spell`, `spore_infection`) defaults to passive impact (current behavior). Evolution-tree nodes unlock *active counter-play actions* keyed to events. Examples:
  - `deep_roots` (plantae) unlocks "Irrigate" tap-action during Drought.
  - `cold_tolerance` (fungi) unlocks "Bundle" tap-action during Cool Spell (joins five adjacent tiles for shared warmth).
  - `quarantine` (fungi) unlocks "Cull" tap-action during Spore Infection.
  Generalizes the existing `AbilitySystem` pattern (Toxin Bloom is the prototype).
- **Soft prestige goal** — per-run goal banner ("Reach 30 tiles" / "Earn 500 biomass" / "Survive 2 events"). Banner highlights when met; doesn't *force* prestige but congratulates and lights up the prestige button. Goals drawn from a small per-niche pool (tied to niche signatures — parasite plantae's goal might be "Steal 200 biomass from neighbors").
- **Generations counter** on title screen with evolving descriptor ("Pioneers" → "Settled Colonies" → "Networked Life" → "The Anthropocene Watches"). Cheap; sells the long arc.

**Dropped from Phase 11 (2026-05-17)**: **tile history**. Per-tile colored tints would be visually noisy on the 32×48 portrait grid, and without a long-press tooltip (deferred) players wouldn't understand the difference. `soil_memory` stays as the Phase 9 global 15% bonus (an acceptable balance leak in the interim). A different "world remembers" mechanic will revisit in Phase 12 alongside the ecosystem/era system — likely at **ecosystem-level granularity** rather than per-tile (subtler, less visual noise, more meaningful when ecosystems require specific kingdom combinations to complete).

**Exit**: a 10-minute session contains at least one active-intervention moment beyond herbivore wave; soft-goal banner gives runs shape; prestige feels like *closing a chapter*, not "I guess I should restart now."

### Phase 12 — Era system + ecosystem selector *(was Phase 11)*
- `EraData` and `EcosystemData` resources.
- "World map" UI replacing the simple Play button: era + ecosystem selector.
- 2 eras to start (Cryogenian — fungi-only; Devonian — current MVP scope).
- 3 ecosystems per era; completion criteria; meta tracking.
- **Per-ecosystem completion gating** uses the layered-lifeform model: some ecosystems are flagged solvable only by specific species packs (a coral-reef ecosystem requires a 3-layer Coral pack to "complete," even if single-layer kingdoms can survive there).
- Era-transition narrative passages (see `STORY_AND_TONE.md`).

### Phase 13 — Species-first model migration *(briefs in progress 2026-05-18, see `docs/SPECIES_MODEL.md`)*

Architectural reshape. **No new player-visible content.** Collapses kingdom/niche/species into species-as-first-class entity; kingdom becomes a tag; niche becomes a runtime-derived label; multi-species coinhabitation becomes the default per-tile state; in-run species introduction loop replaces the niche selector.

**Deliverables**:
- `SpeciesData` extension (placement_rule, introduce_cost, kingdom_id-as-tag, tags array, recipe_components, rendering hints).
- `EcosystemData` reshape (biome_recipe + cluster_size; species/biome completion gates).
- `TerritorySystem` per-tile state: `occupants: Dictionary[StringName, StringName]` (kingdom → species).
- `GrowthSystem` generalized to tick all introduced species, not one kingdom.
- `ColonizationRulesRegistry` reads species directly; recipe rule added (Lichen).
- Niche files deleted; `MultiLayerPlacement` deleted; `parasite_steal_system` + `parasite_decay_system` generalized into per-species tick effects.
- Run flow: world map → ecosystem → starting-species picker → in-run "Introduce species" panel.
- Diversity multiplier on prestige (×1.0 / ×1.1 / ×1.2 for 1/2/3+ species cultivated).
- Tile rendering: plantae/fungi share base color (blended for both); animals render as border.
- Save migration v11 → v12 (lossless for normal Phase 12 runs).

**Exit (behavior parity)**: every Phase 12 gameplay path still works in the new model. Plantae photosynth, plantae parasite, fungi decomposer, fungi mycorrhizal, lichen, animal herbivore + predator runs all play through to prestige; all 6 ecosystems still complete; mass extinction narrative still fires; save migration is lossless.

**Originally-scoped Phase 13 content briefs** (biomes, mass extinction teeth, era nodes, per-era visuals) — paused, archived at `docs/briefs/phase_13_paused/`, revive as Phase 14.

### Phase 14a — Species roster foundation + biome affinity *(briefs written 2026-05-18, see `docs/SPECIES_ROSTER.md`)*

Layered tier rollout, Tier 1 starter (~15 species). Hybrid era gating (most carry over, some signature era-locked). Soft biome preference via per-species multipliers. Hybrid naming (poetic display + Latin tooltip).

**Deliverables**:
- Schema: `SpeciesData.biome_affinity`, `latin_name`, `lineage_id`.
- 5 new species: Cyanobacterial Mat, Vent Archaeon, Cryo-Lichen, Tree-Fern Stem, Wood-Rot Bracket.
- Existing 7 species updated with Latin tooltips, lineage ids, biome affinity.
- `GrowthSystem` reads `biome_affinity` per tile (single-line stack on top of biome multipliers).
- `pioneer` tag predicate in ColonizationRulesRegistry — bare-tile placement without adjacency.
- 8 new discovery entries (5 species + 3 lineage milestones).
- Save migration v12 → v13 (lineages_played seeded from species_played).

**Exit**: each new species playable in its eligible ecosystems; biome affinity visibly shifts yields; lineage milestone fires after cultivating across 2 eras.

### Phase 14b — Era teeth: biomes + events + mass extinction + era nodes + visuals *(briefs written 2026-05-18)*

Era progression gains mechanical + visual weight. Translates paused-Phase-13 content into species-first language.

**Deliverables**:
- New biomes: tundra, mineral_vent, swamp + `BiomeData.chemosynthesis_per_tick`.
- Per-era visual identity: tile palette tint + background tint via `EraData.tint_color`.
- Axis-scoped events: `EventData.scope` + `scope_target` (`world` / `kingdom` / `species_tag` / `era` / `ecosystem`).
- 4 new scoped events: cold_snap, sulfur_bloom, wildfire, swamp_fever.
- Mass extinction gameplay teeth: post-extinction recovery debuff (0.5× → 1.0× over 120 ticks) + +25 EP Extinction Survivor bonus on first prestige in new era.
- 5 era-gated evolution nodes: cryotolerance, chemosynthetic_pathway, vascular_network, mass_fruiting, extinction_survivor (`EvolutionNodeData.requires_era`).
- 10 new discovery entries (biomes, events, nodes, milestones).
- Save migration v13 → v14 (post_extinction, first_run_in_era_completed, first_era_seen).

**Exit**: era-specific play feels mechanically distinct; mass extinction has real weight; era-gated nodes shape build paths.

### Phase 15 — Multi-species ecosystems mature *(was Phase 15)*
- **Coral** as a 3-component recipe (animal × plantae-algae × fungi-symbiont).
- **Termite Mound** as a 3-component recipe (animal × fungi × bacteria-microbe).
- **Mycorrhizal Forest** capstone — emergent multi-tile structure built from dense plantae+fungi+mycorrhizal_bond clusters (links to `docs/STRUCTURES.md`).
- **Apex predator cascade** wired (predator-tag suppresses herbivore pressure → plantae yields recover).
- **Nitrogen fixation** + **allelopathy** + **pioneer succession** predicates wired (each tied to a specific authored species).
- Expanded discovery entries — target 60+.

**Exit**: 3+ eras playable, multi-species runs are the dominant play pattern, layered/recipe species span tiers 1–3, the biological-interactions table (§SPECIES_MODEL.md) is at least 70% wired.

---

## Parked design ideas 🅿

Ideas the user wants captured but hasn't committed to a phase. Move to a tier/phase when scope and motivation align.

### Tile history / "world remembers" (parked 2026-05-17)

Originally a Phase 11 deliverable; dropped because per-tile colored tints would be visually noisy on a 32×48 portrait grid and the supporting tooltip wasn't in scope. Concept worth keeping:

- `meta.tile_history: Dictionary` — per-tile (or per-region) record of every kingdom/niche that has owned a cell across runs.
- Render as subtle visual feedback (faint tint, or per-region background shade — both lighter than per-tile colored tints).
- Powers tile-local versions of `soil_memory`-style bonuses, breaking the Phase 9 global-multiplier balance leak.
- Powers "ruin" semantics when structures (see below) are destroyed.

Most likely revisit: **Phase 12** (alongside the era/ecosystem system) at **ecosystem-level granularity** rather than per-tile — fewer entities, easier to render meaningfully ("this ecosystem has seen 3 generations of plant runs"), more naturally tied to ecosystem-completion gating.

### Emergent multi-tile structures (parked 2026-05-17)

When the player places certain combinations of tiles + layers, the engine **promotes** those cells into a single multi-cell structure (Mycorrhizal Hub, Old-Growth Tree, Fairy Ring, Coral Reef, Termite Mound). The tilemap visibly transforms; structures have their own visual, yield, status, events. Substantiates "the tilemap feels alive and changing."

See `docs/STRUCTURES.md` for the full design sketch — schema, examples, system interactions, open questions.

Most likely revisit: **Phase 13–14** alongside layered-lifeform packs (Coral and Termite Mound are natural structure candidates), per-ecosystem completion gating (some ecosystems require a specific structure), and per-axis events (events can target structures as a unit).

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

## Open questions for the user before Phase 10 starts

1. **Animal Herbivore reuse**: do you want Herbivore animals to *be* the existing herbivore-wave agents (so the wave is now a hostile playable kingdom on the other side), or a separate stat-block? Reusing them is cleaner; separating is more flexible.
separate
2. **Lichen as a species pack vs. a "kingdom-shaped" mode**: when Lichen is the active species, does the player still pick a niche, or is the pack itself the niche-equivalent? Locked answer per `KINGDOMS.md` is: the pack *is* the niche-equivalent at v1 — no separate niche selector for layered species. Confirm before Phase 10 starts. A: a lichen is already the symbiosis between algae and fungi, it could be a niche
3. **Animal niche set for Phase 10**: Herbivore is locked. Should Phase 10 also ship Predator, or save it for Phase 14 with Cordyceps? Reach vs. depth in the same window. Phase 10
4. **Stub resource visibility**: the 6 new resources land as `ResourceLedger` ids in Phase 10 with no gameplay impact. Should the HUD also display them (greyed-out, "Coming in Phase X") or stay hidden until wired? Visible-but-greyed teases content; hidden stays clean.display already
