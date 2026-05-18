# Species Roster (Tier 1)

> Canonical Tier 1 species list. Hybrid naming (poetic display + Latin tooltip), real paleo-era anchoring, soft biome preference via `biome_affinity`. Locked 2026-05-18.

## Naming convention

Each species has:
- **`display_name`** — short, poetic, mythic-scientific voice. What the player sees.
- **`latin_name`** — real or realistic Latin binomial + era hint. Surfaced in tooltips.
- **`lineage_id`** — groups era-variants (e.g., all parasitic climbers across eras share `parasitic_climber`).

Example: `display_name = "Climbing Bramble"`, `latin_name = "Trimerophyton robustius (Early Devonian)"`, `lineage_id = "parasitic_climber"`.

## Tier 1 roster — 15 species across Cryogenian + Devonian

### Cryogenian era (720–635 Mya, snowball Earth)

| Display name | Latin (tooltip) | Kingdom | Era-lock | Lineage | Biome affinity | Tags / placement_rule |
|---|---|---|---|---|---|---|
| **Cyanobacterial Mat** | *Oscillatoria princeps* (Proterozoic-Cambrian) | plantae | `cryogenian` | `pioneer_stem` | tundra 1.2, polar_ice 1.3, swamp 0.6 | `pioneer`, `nitrogen_fixer` / adjacent_empty |
| **Mycelium Thread** | *Glomeromycota basalis* (Ordovician-now) | fungi | carry-over | `mycorrhizal` | mineral_vent 1.2, all 1.0+ | (none) / fungi_substrate |
| **Vent Archaeon** | *Pyrolobus fumarii* (extremophile, all eras) | fungi | `cryogenian` | `extremophile` | mineral_vent 1.8, others 0.3 | `pioneer` / fungi_substrate |
| **Cryo-Lichen** | *Lecidea atrobrunnea* (Proterozoic-now) | recipe | `cryogenian` | `lichen` | polar_ice 1.5, tundra 1.3 | (none) / recipe (cyanobacterial_mat + mycelium_thread) |

### Devonian era (419–358 Mya, age of fishes + first forests)

| Display name | Latin (tooltip) | Kingdom | Era-lock | Lineage | Biome affinity | Tags / placement_rule |
|---|---|---|---|---|---|---|
| **Pioneer Stem** | *Cooksonia caledonica* (Silurian-Devonian) | plantae | carry-over | `pioneer_stem` | forest_edge 1.2, rich_soil 1.1, swamp 0.8 | (none) / adjacent_empty |
| **Climbing Bramble** | *Trimerophyton robustius* (Early Devonian) | plantae | carry-over | `parasitic_climber` | swamp 1.4, forest_edge 1.1 | `parasite`, `plantae` / parasitic_plantae |
| **Tree-Fern Stem** | *Wattieza muschelae* (Middle Devonian) | plantae | `devonian` | `arborescent` | swamp 1.5, forest_edge 1.3, tundra 0.5 | `successor` / adjacent_empty |
| **Mycorrhizal Mycelium** | *Glomus intraradices* (Ordovician-now) | fungi | carry-over | `mycorrhizal` | swamp 1.4 (when bonded), forest_edge 1.2 | (none) / mycorrhizal_fungi |
| **Wood-Rot Bracket** | *Prototaxites loganii* (Silurian-Devonian, gigantic) | fungi | `devonian` | `saprotroph` | swamp 1.4, forest_edge 1.2 | (none) / fungi_substrate |
| **Devonian Lichen** | *Pertusariales devonica* (Devonian-now) | recipe | carry-over | `lichen` | forest_edge 1.3, tundra 1.1 | (none) / recipe (pioneer_stem + mycelium_thread) |
| **Lobe-Finned Browser** | *Eusthenopteron foordi* (Late Devonian) | animals | carry-over | `tetrapod_browser` | tidal_pool 1.4, swamp 1.1 | `herbivore`, `animals` / animal_anchor |
| **Apex Stalker** | *Hyneria lindae* (Late Devonian) | animals | carry-over | `tetrapod_predator` | swamp 1.3 | `predator`, `animals` / animal_anchor |

### Mapping to existing species files (Phase 13 → Phase 14a)

| Current file | New display_name | latin_name | lineage_id |
|---|---|---|---|
| `pioneer_grass` | Pioneer Stem | *Cooksonia caledonica (Silurian-Devonian)* | `pioneer_stem` |
| `mycelium_thread` | Mycelium Thread (unchanged) | *Glomeromycota basalis (Ordovician-now)* | `mycorrhizal` |
| `mycelium_thread_mycorrhizal` | Mycorrhizal Mycelium | *Glomus intraradices (Ordovician-now)* | `mycorrhizal` |
| `bramble` | Climbing Bramble | *Trimerophyton robustius (Early Devonian)* | `parasitic_climber` |
| `lichen_common` | Devonian Lichen | *Pertusariales devonica (Devonian-now)* | `lichen` |
| `common_grazer` | Lobe-Finned Browser | *Eusthenopteron foordi (Late Devonian)* | `tetrapod_browser` |
| `common_predator` | Apex Stalker | *Hyneria lindae (Late Devonian)* | `tetrapod_predator` |

### New species files (Phase 14a)

- `data/species/cyanobacterial_mat.tres` (Cryogenian, plantae, lineage `pioneer_stem`)
- `data/species/vent_archaeon.tres` (Cryogenian, fungi, lineage `extremophile`)
- `data/species/cryo_lichen.tres` (Cryogenian, recipe of cyanobacterial_mat + mycelium_thread)
- `data/species/tree_fern_stem.tres` (Devonian, plantae, lineage `arborescent`)
- `data/species/wood_rot_bracket.tres` (Devonian, fungi, lineage `saprotroph`)

## Lineage continuity

A species's `lineage_id` groups era-variants. Discovery log surfaces lineage milestones:
- "You've cultivated the **mycorrhizal** lineage across 2 eras."
- "Your **pioneer_stem** lineage has filled three ecosystems."

Phase 14a wires the field + writes 3-4 lineage milestone discovery entries. Phase 15+ extends lineages into future eras (Carboniferous Cordaite Pioneer, etc.).

## Biome affinity (soft preference)

Multiplied into `GrowthSystem._apply_yields` once per tile:

```gdscript
var affinity: float = float(species.biome_affinity.get(biome.id, 1.0))
per_tile *= affinity
```

Default `1.0` means no preference (a missing biome key = neutral). Values typically span `0.3 – 1.8`. Player can mismatch but pays the yield penalty.

Biome affinity guidance:
- `1.0`: neutral / no opinion (default for unlisted biomes).
- `1.1–1.3`: thrives here. A "good fit."
- `1.4–1.6`: signature biome. The species visibly belongs.
- `1.7+`: extremophile niche. Reserved for species whose entire identity is "this biome."
- `0.7–0.9`: struggles. Yield penalty but playable.
- `0.3–0.6`: severely punished. Late-game players may still want to push through with node bonuses.

Smoke-test heuristic: a starter species placed in its preferred ecosystem's dominant biome should feel ~30-50% more productive than placed in a hostile biome.

## Era progression (hybrid lock model)

- **Carry-over species** (`era_requires = &""`): playable in any era the player has access to.
- **Era-locked species** (`era_requires = &"cryogenian"` etc.): only playable in the matching era.

Era-locked species are signature pieces — they justify replaying an era or starting in it. Examples:
- Cyanobacterial Mat: snowball-Earth proto-photosynthesizer; doesn't survive the warming into Devonian.
- Vent Archaeon: extremophile; only relevant when volcanic_vent ecosystems matter.
- Cryo-Lichen: needs cyanobacterial_mat as a component, so era-locked transitively.
- Tree-Fern Stem: vascular plant breakthrough — Devonian and onward only.
- Wood-Rot Bracket: needs Devonian forests to decompose.

A future Carboniferous era might add: Cordaite Pioneer (carry-over of `pioneer_stem`), Cycad Cycle (new), Strangler Vine (carry-over of `parasitic_climber`).

## Tags reference

Used by interaction predicates + biological-additions matrix (§SPECIES_MODEL.md).

| Tag | Predicate handler | Active by Phase |
|---|---|---|
| `plantae` / `fungi` / `animals` | Kingdom slot assignment + symbiosis predicate | already wired |
| `herbivore` | Eats plantae-tagged adjacent tiles | Phase 14b (herbivore_manager update) |
| `predator` | Hunts herbivore-tagged tiles | Phase 14b (apex predator cascade) |
| `parasite` | Triggers parasite_steal tick effect | Phase 13 (already wired) |
| `pioneer` | Ignores normal adjacency rule on bare biomes | Phase 14a |
| `successor` | Requires prior-occupation history on tile | Phase 14a (basic) |
| `nitrogen_fixer` | +0.1 nutrient_per_tick on adjacent tiles | Phase 15 |
| `allelopath` | adjacent non-self yields × 0.9 | Phase 15 |
| `mycoheterotroph` | Drains biomass from mycorrhizal_bond neighbors | Phase 15 |
| `pollinator` | Boosts adjacent plantae flowering | Phase 15 (needs insect agents) |
| `scavenger` | Bonus from adjacent corpse tiles | Phase 15 |
| `extremophile` | Strong biome affinity to single biome | Tag-only, no predicate (Phase 14a) |
| `arborescent` | Reserved for future canopy mechanic | Tag-only (Phase 16+) |

## Future-era roster sketches (Phase 15+, not Tier 1)

Brief sketches for context — not authored in Tier 1.

### Carboniferous (358–298 Mya, swamps + great coal forests)
- **Cordaite Pioneer** (*Cordaites principalis*) — plantae, lineage `pioneer_stem`, swamp 1.4
- **Lepidodendron Trunk** (*Lepidodendron aculeatum*) — plantae, `arborescent`, swamp 1.6
- **Eogyrinus Apex** (*Eogyrinus attheyi*) — animals, `tetrapod_predator`, swamp 1.4
- **Strangler Vine** (*Carboniferous parasiticus*) — plantae, `parasitic_climber`, all swamps 1.5

### Permian (298–252 Mya, gymnosperms + synapsid dominance)
- **Cycad Cycle** (*Cycas revoluta*) — plantae, `arborescent`, forest_edge 1.4
- **Dimetrodon Hunter** (*Dimetrodon grandis*) — animals, `tetrapod_predator`, savanna affinity
- **Glossopteris Leaf** (*Glossopteris indica*) — plantae, `successor`, swamp 1.2

These don't need to be authored until the era they belong to ships.
