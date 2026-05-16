# Niche System Design

## Purpose
Niches are the **playstyle dimension within a kingdom**. Currently a plantae run plays one way (photosynthesizer). With niches, the same kingdom can play radically differently: predator, parasite, pollinator-host. This is the single highest-leverage addition to the post-MVP game — one phase multiplies replay value by 5–10×.

## How niches sit relative to kingdoms and species

```
KINGDOM (plantae)
├── NICHE (photosynthesizer)
│   ├── SPECIES (pioneer_grass)
│   └── SPECIES (bramble)
├── NICHE (carnivore)
│   ├── SPECIES (venus_trap)
│   └── SPECIES (sundew)
└── NICHE (parasite)
    └── SPECIES (mistletoe)
```

A run is configured by picking **kingdom → niche → species**. The kingdom determines what layer of the tile you occupy and what visual category you belong to. The niche determines the *rules* of resource generation, colonization, and conflict. The species is a tuning knob within the niche.

## Niche slots per kingdom (initial)

### Plantae

| Niche | Resource focus | Colonize rule | Distinctive ability |
|---|---|---|---|
| **Photosynthesizer** *(current)* | Biomass | Adjacent empty tile | Sunlight-dependent yields |
| **Carnivore** | Biomass + Protein | Adjacent empty tile | Attracts and consumes wandering herbivores |
| **Parasite** | Biomass (stolen) | Must place on existing plantae OR animal tile (taps yield) | No biome dependency; very cheap; cannot exist on bare ground |
| **Pollinator-host** | Biomass + Pollination | Adjacent empty tile | Spawns/attracts insect agents; insects boost yields on adjacent tiles |

### Fungi

| Niche | Resource focus | Colonize rule | Distinctive ability |
|---|---|---|---|
| **Decomposer** *(current)* | Decay + Spores | Plant tile, corpse, or adjacent fungi | Bonus yield on corpse tiles |
| **Parasite** | Decay + Lifeforce | Must place on a living animal organism | Slowly takes over the host; converts host yields |
| **Mycorrhizal** | Decay + Network | Adjacent to fungi (cannot bootstrap solo) | Strong boost to adjacent plantae tiles' yields |

### Animals (future)

| Niche | Resource focus | Colonize rule | Distinctive ability |
|---|---|---|---|
| **Herbivore** | Protein | Move-based; territory is a "range" not a tile set | Consumes plant tiles for protein |
| **Predator** | Protein + Apex | Range-based | Hunts other animals; territorial pressure |
| **Scavenger** | Protein (from decay) | Range-based | Feeds on corpses; symbiotic with fungi |

## How niches map to existing systems

### Data layer
Add `NicheData` resource:
```gdscript
class_name NicheData
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var kingdom_id: StringName
@export var species_options: Array[SpeciesData]
@export var colonization_rule: StringName    # &"adjacent_empty", &"parasitic", &"corpse_substrate", ...
@export var resource_focus: Array[StringName]
@export var ability_overrides: Dictionary    # which abilities replace the default
```

Add `data/niches/<niche_id>.tres` files + `data/niches/_index.tres` per the content-index pattern.

### Colonization layer
Currently `PlantColonization._on_tile_tapped` has hardcoded "must be adjacent to owned + costs biomass" logic. Refactor it to read the active niche's `colonization_rule` and dispatch.

Simplest dispatch: a `ColonizationRulesRegistry` autoload (or static class) with one function per rule. The rule returns `(is_valid: bool, cost_override: Dictionary)`.

### Yield layer
`GrowthSystem` already iterates `tick_yield` per species. Niche modifies tick_yield indirectly through the species. A Carnivore niche's species has `{biomass: 0.3, protein: 0.2}` instead of `{biomass: 0.5}`.

### Run state
Add `GameState.current_niche_id: StringName`. Set at run start by PrestigeSystem. Persist in save under `run.niche_id`.

## UI flow change

Current: prestige screen → "Begin run as Plantae" / "Fungi" / "Symbiosis".

After niches: prestige screen → pick **Kingdom**, then **Niche**, then **Species**. Each step shows options gated by unlocks.

```
[Kingdom selection]
  Plantae          (unlocked)
  Fungi            (unlocked)
  Animals          (locked — see Animal Awakening node)

[Niche selection — Plantae]
  Photosynthesizer (unlocked, default)
  Carnivore        (unlocked — bought "Insectivory" node)
  Parasite         (locked — buy "Mistletoe Heritage" node)

[Species selection — Carnivore]
  Venus Trap       (unlocked, default for niche)
  Sundew           (locked — beat 5 herbivore waves with Carnivore)
```

## Why niches are the right next thing to build

- **Engine-ready**: most of the underlying systems (colonization, resource generation, save state) already support it. Niche data slots into the existing data-driven content pipeline.
- **High player-visible variety**: each niche is fundamentally a new game mode. Adding 3 plantae niches = 4× the plantae replay variety overnight.
- **Unblocks the web of life**: niches give the evolution tree something interesting to grant. Currently most nodes just bump numbers; with niches, nodes can unlock entirely new ways to play.
- **Naturally extends to animals later**: the niche concept generalizes — herbivore vs predator is the same kind of choice as decomposer vs parasite.

## Open design questions

1. **Can a single run swap niches mid-flight?** E.g., your Photosynthesizer plantae unlocks Carnivore mid-run and you start placing carnivore tiles. This adds complexity but rewards mastery. Probably NO for v1 — pick at run start, evolve via species choice within the niche.
2. **Should niches share or replace abilities?** Does a Carnivore plantae lose Toxin Bloom or just gain a new ability alongside? Lean toward *replace* — encourages distinct identity per niche.
3. **How do niches interact with the symbiosis reframe?** Symbiotic species like Lichen would have a niche too — "Mutualist Hybrid" — that combines both parent kingdoms' colonization rules.
