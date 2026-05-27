# Alpha Lock — Starter Content (2026-05-25)

> **Authoritative source for what ships in alpha.** Locked in conversation 2026-05-25. Supersedes any conflicting starter-era content in `GAME_VISION.md`, `ERAS_AND_ECOSYSTEMS.md`, or the existing `data/` placeholders (Cryogenian/Devonian — now legacy).

## What this doc is

This is the single point-of-truth for alpha-scope content: which eras, biomes, maps, species, and interactions ship in the first publicly playable build. It exists to prevent scope creep and to anchor art commissions, content authoring, and tutorial work to a fixed target.

If a piece of content is not in this doc, it does not ship in alpha.

## Design principles (alpha-specific)

1. **Two eras, fully built, beats five eras half-built.** Depth over breadth.
2. **Plants and fungi are the protagonists.** Animals are 1–2 per era, in supporting roles.
3. **Universal recognition over deep-time accuracy.** Starter eras must be legible to a player who has never heard the geological-period name.
4. **One concept per tutorial moment.** No interaction lands in alpha unless it can be explained in one sentence.

## Era pair — locked

| Era | Player-facing name | Why it ships |
|---|---|---|
| Carboniferous | **Coal Forests** | Plants are unambiguously the protagonists; giant scale-trees and fungal towers create iconic silhouettes; signature insect (Meganeura) sells the era. |
| Pleistocene | **Ice Age** | Universal name recognition (every kid knows "Ice Age"); maximum visual contrast vs. Coal Forests; charismatic megafauna (Mammoth, Saber-Tooth). |

**Cryogenian deferred** — too abstract to introduce new players to. Reserved as a later "deep time" unlock.

## Biomes — locked (4 total)

| Biome | Type | Carbo presentation | Pleist presentation |
|---|---|---|---|
| `wetland` | shared | Black-brown water, mossy hummocks, amber resin, methane bubbles | Peat bog / muskeg, sphagnum, ice rime |
| `open_ground` | shared (pioneer biome) | Burn scar — black ash, char | Glacial retreat — blue-grey scree, thaw puddles |
| `lush_canopy` | Carbo signature | Dense lycopsid stack, dim understory, spore drift | — |
| `tundra` | Pleist signature | — | Pale ochre frozen grass, sparse, wind-blown |

**Cost discipline**: same biome ID across eras → same gameplay rules; era-specific visuals via tile-art variants + particle overlays.

### Per-biome gameplay properties

| Biome | Base yield | Decay rate | Pioneer rule |
|---|---|---|---|
| `wetland` | 0.9× | **0.4× (slow)** | only `wetland_pioneer` tagged species |
| `open_ground` | 0.7× | 1.3× (fast, exposed) | **PIONEER biome** — any `pioneer` tag claims |
| `lush_canopy` | **1.4× (highest)** | 1.1× (humid rot) | locked — successor only |
| `tundra` | 0.8× | **0.5× (cold = slow)** | `frost_tolerant` only |

## Maps — locked (6 total, 3 per era)

### Carboniferous — Coal Forests

| Map | Biome mix | Hero | One-line story |
|---|---|---|---|
| **Coal Swamp** *(first ship)* | wetland + open_ground | Calamites + Mycorrhizal Network | Drowned forest; biomass piles into coal |
| **Fern Glade** | open_ground dominant + lush_canopy edges | Tree Fern (Psaronius) + Lepidodendron | Dappled understory between fires |
| **Riverside Cathedral** | lush_canopy + wetland | Lepidodendron + Prototaxites | The mature climax forest |

### Pleistocene — Ice Age

| Map | Biome mix | Hero | One-line story |
|---|---|---|---|
| **Glacier's Edge** | open_ground (scree) + sparse tundra | Reindeer Lichen + Cushion Moss | Pioneer life on retreating ice |
| **Mammoth Steppe** | tundra dominant + open_ground | Steppe Sedge + Woolly Mammoth | Lost grassland, mammoth-engineered |
| **Taiga Border** | wetland (peat) + tundra | Dwarf Willow + Permafrost Yeast | Where forest creeps north |

## Species — locked (14 total, 7 per era)

### Carboniferous

| Kingdom | Species | Latin (tooltip) | Role |
|---|---|---|---|
| Plants | **Lepidodendron** | *Lepidodendron aculeatum* | Scale tree — diamond bark, 30m tall, era signature silhouette |
| Plants | **Calamites** | *Calamites suckowii* | Giant horsetail — bamboo-like, wetland hero |
| Plants | **Tree Fern (Psaronius)** | *Psaronius infarctus* | Classic fern shape, understory all-rounder |
| Fungi | **Prototaxites** | *Prototaxites loganii* | 8m fungal tower — extinct mystery, signature visual |
| Fungi | **Mycorrhizal Network** | *Glomus carboniferensis* | Underground buff, adjacency synergy |
| Animals | **Meganeura** | *Meganeura monyi* | 70cm dragonfly — apex insect, universally recognized |
| Animals | **Arthropleura** | *Arthropleura armata* | 2m millipede — detritivore, processes leaf litter |

### Pleistocene

| Kingdom | Species | Latin (tooltip) | Role |
|---|---|---|---|
| Plants | **Dwarf Willow** | *Salix herbacea* | Knee-high tree, signature taiga-margin shape |
| Plants | **Steppe Sedge** | *Carex pleistocenica* | Grassland productive base, mammoth food |
| Plants | **Cushion Moss** | *Racomitrium lanuginosum* | Tundra ground cover, freeze-tolerant |
| Fungi | **Reindeer Lichen** | *Cladonia rangiferina* | Slow-growing crust, herbivore food; symbiotic bridge species |
| Fungi | **Permafrost Yeast** | *Cryptococcus albidus* | Cold-adapted decomposer |
| Animals | **Woolly Mammoth** | *Mammuthus primigenius* | Megaherbivore — universally recognized, era visual anchor |
| Animals | **Saber-Tooth** | *Smilodon fatalis* | Apex predator, pressure agent |

## Interactions — locked (5 total)

| # | Interaction | Plain-English | Map where it first teaches |
|---|---|---|---|
| 1 | **Pioneer claim** | Pioneer species on `open_ground` get a big head-start growth bonus | Coal Swamp (tutorial step 1) |
| 2 | **Mycorrhizal bond** | Fungus + plant adjacent → both grow faster (+0.2 yield each) | Coal Swamp (tutorial step 2) |
| 3 | **Slow-decay biomass pile** | Plants dying on `wetland` pile biomass into a coal/peat gauge (1 unit; Tree Fern = 1.5) | Coal Swamp (tutorial step 3) |
| 4 | **Apex predation** | Saber-Tooth adjacent to Mammoth → periodic cull, biomass dropped onto tundra | Mammoth Steppe |
| 5 | **Detritivore recycling** | Arthropleura adjacent to dead plant tile → recycles faster, Arthropleura grows | Coal Swamp (tutorial step 4) |

**Deferred mechanics** (cut for alpha-simplicity, return post-feedback): succession drift, methane ignition event, high-O₂ surge, lichen weathering, mammoth grazing maintenance, forest_edge biome, mineral_substrate biome, microbe kingdom.

## First map to ship — Coal Swamp (full spec)

### Identity
- **Era**: Carboniferous
- **Theme**: "Drowned forest; biomass piles into coal"
- **Hero**: Calamites
- **Supporting**: Tree Fern, Mycorrhizal Network, Arthropleura
- **Pressure**: slow decay (environmental, resolves via detritivore loop)
- **Player feeling target**: satisfying positive-feedback growth → gauge fill → "I made coal"

### Biome layout
- ~80% `wetland` (peripheral ring)
- ~20% `open_ground` (central pocket, centripetal seeding bias)

### Starter state
| | |
|---|---|
| Pre-placed | 1× Calamites on central `open_ground`, half-energy |
| Inventory | 3× Calamites · 2× Mycorrhizal Network · 2× Tree Fern · 1× Arthropleura |
| Locked species | Lepidodendron, Prototaxites, Meganeura (later Carbo maps) |
| Coal gauge | 0 / 1000 (win condition) |
| Lose condition | **none** — tutorial map is untimed and unfailable |

### Tutorial sequence (5 prompts)

| Step | Prompt | Action | Teaches |
|---|---|---|---|
| 1 | "Calamites prefers wet ground. Place one on a wetland tile next to the swamp edge." | Place Calamites on wetland | Biome affinity + pioneer rule |
| 2 | "Plants grow faster with fungal partners. Place a Mycorrhizal Network next to your Calamites." | Place fungus adjacent | Mycorrhizal bond |
| 3 | "When plants die on the swamp, biomass piles into coal. Watch the gauge." | Wait/observe | Slow-decay biomass pile |
| 4 | "Decay is too slow — the nutrient loop is stuck. Place Arthropleura to recycle." | Place Arthropleura | Detritivore recycling |
| 5 | "Now grow your forest. Fill the coal gauge." | Free play | Combine all four |

### Win condition
Coal gauge reaches 1000 units (raised from 50 after smoke test 2026-05-25). Each plant death on `wetland` = 1 unit (Tree Fern = 1.5). Arthropleura speeds the death/regrowth cycle.

### Playtime
~6–9 minutes first play, ~3–4 minutes replays.

### Hero loop (per `docs/GAMEPLAY_DESIGN.md`)
| Role | Element |
|---|---|
| Hero | Calamites |
| Supporting | Tree Fern + Mycorrhizal Network + Arthropleura |
| Pressure | Slow decay (resolves on detritivore placement) |

## Step-order roadmap to alpha

> **Revised 2026-05-25** after audit of current codebase. Most infrastructure assumed missing in the initial draft is already shipped (Phase 12 era system, Phase 14 biome affinity + mass extinction, world map UI, starting species picker, onboarding overlay scaffold, goal-banner widget, save migration to v18). Authoring `.tres` data + small reskins is most of the remaining work.

| # | Step | Size | Exit gate |
|---|---|---|---|
| 1 | **Author Carbo + Pleist data** — 4 biomes + 2 eras + 6 ecosystems + 14 species + index files | 2-3 sessions | Project loads new content; `world_map` shows Coal Swamp |
| 2 | **Save migration v18→v19** — map legacy era/ecosystem IDs to new ones | 0.5 session | Existing test saves load without losing prestige meta |
| 3 | **Coal Swamp tuning + gauge reskin** — verify `biomass_earned` target plays right; flavor-reskin existing goal_banner for Coal Swamp's "coal gauge" feel | 0.5-1 session | Coal Swamp clears end-to-end with placeholder art |
| 4 | **Tutorial reskin** — replace global `onboarding_overlay.STEPS` with Coal-Swamp-specific 5 prompts | 0.5-1 session | Fresh tester completes Coal Swamp from prompts alone |
| 5 | **Art commissions in flight** *(parallel to 1-4)* — Tier 1 list sent to artist; coding continues | n/a (artist lead time) | Art assets in hand |
| 6 | **Apex predation + remaining 5 maps polish** — wire Mammoth/Smilodon interaction; verify the other 5 maps play | 1-2 sessions | All 6 maps clearable |
| 7 | **Polish pass** — final balance + visual cleanup. (Telemetry cut from alpha scope 2026-05-25.) | 1 session | Build-ready |
| 8 | **Alpha release** — Play Console internal-test + itch.io page | release | Build is live |

**Revised total estimate**: **3-5 weeks of solo dev** + ~4-6 weeks parallel art lead time → **~5-7 weeks to alpha**.

### Critical path

Art commission lead time is now the longest-pole item. **Commission Tier 1 art the day the species list locks** — that's the biggest schedule lever.

### Audit-driven notes

What was assumed to-be-built but is already shipped:
- `NutrientSystem._generate_biome_map` already honors `biome_recipe` from ecosystem files; `biome_cluster_size` is also live.
- `EcosystemTracker` exists — lives inside `EraSystem` autoload, emits `ecosystem_completed`.
- `world_map.gd` is shipped (Phase 12 done).
- `onboarding_overlay.gd` is shipped (Phase 16 alpha-polish work) — 7-step tap-to-advance with `meta.onboarding_step` persistence.
- `goal_banner.gd` + `RunGoalSystem` is shipped — 12 pre-built goals; "Coal gauge" can reskin this rather than build new.
- Save migration system is at v18 with 17 migrations live; v18→v19 follows established pattern.
- `era_requires` field exists on `SpeciesData` but is **not yet enforced anywhere** — gating happens via `ecosystem.starting_species_filter`. Step 1 will set `era_requires = &"deferred"` on legacy species and add a 1-line filter in two pickers (~5 minutes) to enforce hard gate.

What's still risky:
- `biomass_earned` criterion counts all biomass, not just wetland-decay. If the Coal Swamp "feeling" requires only wetland deaths to count, a new criterion `&"biomass_on_biome"` adds ~0.5 session.
- Per-map tutorial vs. global tutorial decision: cheaper path is reskin global STEPS (alpha will only ship Coal Swamp tutorial-grade; later maps get short "new mechanic" toasts). Decision: replace global with Coal Swamp tutorial for alpha; per-map system is post-alpha.

## Execution plan (current sprint)

1. **Overwrite this roadmap section** ✅ (this update)
2. **Rename existing biomes**: `swamp.tres` → `wetland`, `forest_edge.tres` → `lush_canopy`, `grassland.tres` → `open_ground`. Keep `tundra.tres`. Leave `mineral_vent.tres` + `rich_soil.tres` as legacy in `data/biomes/` but remove from `_index.tres`.
3. **Author 2 eras**: `data/eras/carboniferous.tres`, `data/eras/pleistocene.tres`. Update `data/eras/_index.tres` to canonical Carbo→Pleist order. Legacy `cryogenian.tres` + `devonian.tres` stay in folder as legacy but drop from index.
4. **Author 6 ecosystems**: with `biome_recipe`, `completion_criterion = &"biomass_earned"`, `completion_target` per map, `starting_species_filter` per map. Coal Swamp = priority.
5. **Author 14 species**: 7 Carbo (Lepidodendron, Calamites, Tree Fern, Prototaxites, Mycorrhizal Network, Meganeura, Arthropleura) + 7 Pleist (Dwarf Willow, Steppe Sedge, Cushion Moss, Reindeer Lichen, Permafrost Yeast, Woolly Mammoth, Saber-Tooth). All with biome affinity, lineage_id, tags, latin_name.
6. **Gate legacy species**: set `era_requires = &"deferred"` on 14 existing species. Add 1-line filter in `starting_species_picker.gd` + `species_panel.gd` to skip species whose `era_requires` doesn't match current era (treating `&""` as "any").
7. **Reskin tutorial**: replace `onboarding_overlay.STEPS` with the 5 Coal-Swamp-specific prompts from the spec section.
8. **(Next sprint)** save migration v18→v19, gauge reskin, apex predation wiring, telemetry.

## Art commission summary (priority order)

### Tier 1 — Coal Swamp ship-blocker (commission first)

| Asset | Spec | Reference notes |
|---|---|---|
| **Calamites sprite** | 48×48px, side-view, segmented vertical stalk, jointed nodes, sparse whorled leaves at top | Modern horsetail × bamboo; readable silhouette = segmented stalk |
| **Mycorrhizal Network sprite** | 48×48px, low-profile, root-like spreading filaments emerging from soil, small fruiting bodies | Earthy underground feel, not mushroom-cap dominant |
| **Tree Fern (Psaronius) sprite** | 48×48px, distinct fronded crown atop slim trunk, must differ in silhouette from Calamites | Crown vs. stalk silhouette contrast — critical |
| **Arthropleura sprite** | 48×48px, segmented millipede, slight perspective, brown-orange exoskeleton | "Giant bug" reads instantly |
| **`wetland` Carbo biome tile** | 48×48px tile (potentially tiling), dark water + mossy hummock palette, methane bubble particle frames (3) | Mood: dark wet, organic |
| **`open_ground` Carbo biome tile** | 48×48px tile, charred black-grey with ash + ember accents | Burn-scar look |
| **Coal gauge UI** | Vertical or horizontal gauge widget with coal-vein fill animation, "0/50" counter, coal-vein background art | Sells the win moment; player sees this constantly |

**Estimated cost** (pixel artist rates ~$25–50 per 48px sprite, ~$75–150 per tile, ~$100 UI element):
- 4 species: $100–200
- 2 biome tiles: $150–300
- Coal gauge: $100
- **Tier 1 total: $350–600**

### Tier 2 — Pleistocene + remaining Carbo (commission once Tier 1 lands)

| Asset | Notes |
|---|---|
| 10 species sprites (3 Carbo remaining + 7 Pleist) | Lepidodendron, Prototaxites, Meganeura, Dwarf Willow, Steppe Sedge, Cushion Moss, Reindeer Lichen, Permafrost Yeast, Woolly Mammoth, Saber-Tooth |
| 2 biome tiles (`lush_canopy`, `tundra`) + 2 variants (`wetland`-Pleist, `open_ground`-Pleist) | Tundra and lush_canopy are signature; Pleist variants of shared biomes can be tint-driven |

**Estimated cost: $750–1500**

### Tier 3 — Polish (post-alpha if budget allows)
- Era-transition cinematic stills
- Per-ecosystem ambient particle sets
- Animated mammoth-walk / saber-tooth-prowl frames

### Commission brief template (one paragraph per asset)

For each Tier 1 asset, the brief sent to the artist should include:
1. **Identity**: name + latin name + one sentence of biological role.
2. **Silhouette goal**: what makes this asset readable at 48px (e.g., "segmented stalk distinguishes from any fronded form").
3. **Palette**: 3–5 hex codes anchoring the look.
4. **Animation needs**: idle frames? particle effects? maturation stages?
5. **Reference image**: 1 photo + 1 art reference at most (avoid over-specifying).

A separate `docs/COMMISSION_ALPHA.md` should be authored once the artist is selected — this doc is the design lock, not the brief itself.

## Deferred (explicitly not in alpha)

Captured here so we don't accidentally re-add them.

### Content
- Cryogenian era (deferred to post-alpha as "deep time" unlock)
- Microbe kingdom (deferred — discussed and cut for alpha-simplicity)
- Mesozoic / Cretaceous era (future)
- Devonian era as standalone (its species absorbed into Carbo where biologically appropriate)
- `forest_edge` biome (folded into adjacent biomes for alpha)
- `mineral_substrate` biome (folded into `open_ground`-Pleist visual variant)

### Mechanics
- Succession drift (biome converts over time if neglected)
- Methane ignition event (Carbo wetland threshold event)
- High-O₂ surge event (Carbo lush_canopy event)
- Lichen weathering (mineral_substrate species conversion)
- Mammoth grazing maintenance (tundra preservation mechanic)
- Fire events (require oxygen-event system)

### Systems
- Active-event interventions (originally Phase 11 scope) — not blocking alpha
- Tile history / "world remembers" (parked in roadmap)
- Emergent structures (Mycorrhizal Hub, Old-Growth Tree, etc.)

## Risks tracked for alpha

| Risk | Mitigation |
|---|---|
| Calamites + Tree Fern silhouettes blur at 48px | Art brief requires explicit silhouette contrast (segmented stalk vs. fronded crown) |
| Coal gauge feels abstract without strong visual | Dedicated commission for gauge background art + fill animation |
| Tutorial step 4 (Arthropleura) feels arbitrary if decay bottleneck isn't visible | Prompt fires only after first 3 plant deaths, when nutrient bottleneck visibly slows growth |
| 80/20 biome ratio leaves too little open_ground for new players | Center pocket must be ≥5×5 tiles |
| Untimed tutorial bores experienced players | Optional hidden completion-time score on replays |
| Pleistocene plants visually quiet | Mammoth sprite must be the era's visual anchor — commission well |
| Saving with old Cryogenian save files | Save migration step in Phase 2 marks legacy saves as "Migrate to new era pair" with a default to Coal Swamp |

## Reference back to existing docs

This doc supersedes era/biome/species content in:
- `docs/GAME_VISION.md` (era examples section)
- `docs/ERAS_AND_ECOSYSTEMS.md` (full doc)
- `docs/SPECIES_ROSTER.md` (Tier 1 roster — now legacy)

This doc is consistent with and refers to:
- `docs/GAMEPLAY_DESIGN.md` (hero loop architecture)
- `docs/ROADMAP.md` (phase ordering)
- `docs/DESIGN_PILLARS.md` (mobile tempo, ecology-as-magic-system)
- `docs/VISUAL_DIRECTION.md` (48px cluster-in-biome rendering lock from 2026-05-22)

When in doubt, this doc wins for alpha-scope decisions; the others win for their own non-alpha topics.
