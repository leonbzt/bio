# Brief 02 — Schema extensions: NicheData + SpeciesData + ResourceLedger constants

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — contracts.

Read first:
1. `scripts/data/niche_data.gd`.
2. `scripts/data/species_data.gd`.
3. `scripts/autoloads/resource_ledger.gd` — where existing resource constants live.
4. `docs/briefs/phase_10/00_phase_10_entry.md` decisions 2, 3, 7, 8.

## Goal
Lay the contract additions Phase 10 needs. After this brief:
- `NicheData` carries layer + parasitic-targets metadata.
- `SpeciesData` carries layer count + per-layer roster.
- `ResourceLedger` exposes constants for the 6 stub resources.
- No behavior changes yet — content (Lichen, parasite niche updates) lands in later briefs.

## Outputs

### Extend `scripts/data/niche_data.gd`

```gdscript
class_name NicheData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var kingdom_id: StringName = &""
@export var species_options: Array[SpeciesData] = []
@export var colonization_rule: StringName = &""
@export var cost_override: Dictionary = {}
@export var unlock_node_id: StringName = &""
@export var tile_variant: StringName = &""

# Phase 10 additions — see docs/KINGDOMS.md "Layered lifeforms".

# True for niches whose selected species drives multi-layer placement
# (the species' layer_species roster is non-empty). Engine reads this
# to decide whether to enter multi-layer placement mode at run start.
@export var expects_layered: bool = false

# For parasitic niches: which kingdoms can be stolen from. Empty = no steal.
# Example: parasitic plantae has [&"plantae", &"fungi"]. A future cordyceps
# fungi niche has [&"animals"]. Per-species overrides (if needed) come later
# via a SpeciesData field.
@export var parasitic_targets: Array[StringName] = []
```

### Extend `scripts/data/species_data.gd`

```gdscript
class_name SpeciesData
extends Resource

# ... existing fields ...

# Phase 10 additions — see docs/KINGDOMS.md "Layered lifeforms".

# Number of layers this species drives. 1 = single-layer (default), 2 = dual
# (Lichen), 3+ = stack (Coral, Termite Mound — Phase 14+).
@export var layer_count: int = 1

# When layer_count > 1, this is the per-layer species roster. Element order
# defines layer order. For Lichen: [mycelium_thread (subsurface), pioneer_grass (surface)].
# When layer_count == 1, this is empty.
@export var layer_species: Array[SpeciesData] = []
```

### Extend `scripts/autoloads/resource_ledger.gd`

Add constants for the 6 stub resources alongside existing ones:

```gdscript
const BIOMASS    := &"biomass"
const NUTRIENTS  := &"nutrients"
const SUNLIGHT   := &"sunlight"
const DECAY      := &"decay"
const SPORES     := &"spores"
const PRESSURE   := &"population_pressure"

# Phase 10 stub resources — wired into gameplay in Phase 14.
# Each is biologically grounded; see docs/GAME_VISION.md.
const PROTEIN     := &"protein"      # amino-acid biomass — animal predators, carnivore plantae
const CELLULOSE   := &"cellulose"    # plant structural fiber — animal herbivores consume it
const CHITIN      := &"chitin"       # fungal cell walls + arthropod exoskeleton
const PHOSPHATE   := &"phosphate"    # mineral nutrient — mycorrhizal trade currency
const LIFEFORCE   := &"lifeforce"    # stolen vital energy — parasite niches
const POLLINATION := &"pollination"  # reproductive vector — pollinator-host plantae × insects
```

No other changes to `ResourceLedger` — the get/set methods already work generically over StringName keys.

## ARCHITECTURE.md updates

- § 3 ResourceLedger section: append the 6 new constants.
- § 4: extend NicheData + SpeciesData schema docs with the new fields.
- § 9: add v9 → v10 row (brief 01).

## Acceptance criteria
- [ ] `NicheData` schema loads with new fields visible in inspector; existing `.tres` files load (defaults populate).
- [ ] `SpeciesData` schema loads with new fields; existing species `.tres` files load (`layer_count == 1`, `layer_species == []` by default).
- [ ] `ResourceLedger.PROTEIN` etc. resolvable as static constants from any script.
- [ ] `ResourceLedger.add(ResourceLedger.PROTEIN, 5.0)` works without error (verifies the generic StringName path).
- [ ] No gameplay changes — existing prestige + niche flow unaffected.

## Out of scope
- Multi-layer placement engine (brief 04).
- Lichen content (brief 05).
- Wiring parasitic_targets into the parasite niche signature (brief 06).
- HUD display of stub resources (brief 10).
- Resource wiring beyond the constants (Phase 14).
