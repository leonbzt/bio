# Brief 05 — Lichen niche + species pack + integration

**Suggested agent**: Kilo for the `.tres` data, ChatGPT 5.2 for the integration code. Route diff to Claude.

Read first:
1. `docs/briefs/phase_10/02_schema_extensions.md` (NicheData + SpeciesData fields).
2. `docs/briefs/phase_10/04_multi_layer_placement.md` (MultiLayerPlacementSystem).
3. `data/niches/decomposer.tres`, `data/niches/mycorrhizal_fungi.tres` — sibling fungi niches for layout reference.
4. `data/species/pioneer_grass.tres`, `data/species/mycelium_thread.tres` — the two species Lichen wraps.
5. `data/evolution_tree/unlock_symbiosis.tres` — the evolution node being repurposed.

## Goal

Create the Lichen 2-layer species pack as a niche under Fungi. After this brief:
- A Lichen run starts as `kingdom_id = &"fungi"`, `niche_id = &"lichen"`, with the MultiLayerPlacementSystem detecting layer_count == 2 and enabling the HUD layer toggle (Fungi / Plantae).
- The player can place fungi tiles on the subsurface layer and plantae tiles on the surface layer in the same run.
- The `unlock_symbiosis` evolution node grants this niche (replacing its prior grants_kingdoms = symbiosis).
- The `symbiotic_generosity` start-bonus relocates from the symbiosis-kingdom hook (deleted in brief 03) to a Lichen-niche start hook.

## Outputs

### Create `data/species/lichen_common.tres`

The Lichen species itself — its `layer_count = 2`, `layer_species = [mycelium_thread, pioneer_grass]`.

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/mycelium_thread.tres" id="2"]
[ext_resource type="Resource" path="res://data/species/pioneer_grass.tres" id="3"]

[resource]
script = ExtResource("1")
id = &"lichen_common"
display_name = "Common Lichen"
kingdom_id = &"fungi"
base_traits = Array[Resource]([])
colonize_cost = {}
tick_yield = {}
layer_count = 2
layer_species = Array[Resource]([ExtResource("2"), ExtResource("3")])
```

The species' own `colonize_cost` + `tick_yield` are empty because Lichen *delegates* per-layer to its layer_species — each layer's cost + yield come from the underlying mycelium_thread / pioneer_grass species.

### Append to `data/species/_index.tres`

Add the `lichen_common` reference to the index.

### Create `data/niches/lichen.tres`

```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/lichen_common.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"lichen"
display_name = "Lichen"
description = "You are two. Fungus and alga, woven into one body. Place both layers and let the partnership feed itself."
kingdom_id = &"fungi"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &""    # Empty — colonization routes via layer_species' kingdom-default rules.
cost_override = {}
unlock_node_id = &"unlock_symbiosis"    # The existing evolution node; brief 03 left it in place.
tile_variant = &""
expects_layered = true
parasitic_targets = []
```

### Append to `data/niches/_index.tres`

Add the `lichen` reference.

### Repurpose `data/evolution_tree/unlock_symbiosis.tres`

Edit the content (keeping the id `&"unlock_symbiosis"` for save compatibility):

```
script = ExtResource("1")
id = &"unlock_symbiosis"
display_name = "Lichen Heritage"
description = "Two bodies learn to be one. The Lichen niche unlocks under Fungi — place both fungal and plant layers in the same run."
prerequisites = [&"unlock_fungi"]    # adjust if prior prereqs differed
meta_cost = {"evolution_points": 12}    # match prior cost
grants_traits = []
grants_kingdoms = []    # WAS [&"symbiosis"] — emptied
wing = &"hybrid"
tier = 2
requires_kingdom_played = []
```

Brief 03 already noted this is happening; brief 05 actually executes the content swap.

### Niche-start hook for `symbiotic_generosity` bonus

Brief 03 noted the bonus needs a new home. Two options:

**Option A** (recommended): Add a "niche start bonus" hook to `PrestigeSystem.start_run`. After resolving the niche, check if the niche has a `start_bonus` field on its NicheData:

Extend `NicheData`:
```gdscript
# Resources granted once at run start. Format: {resource_id: amount}.
@export var start_bonus: Dictionary = {}
```

(Add this in this brief, not in brief 02 — brief 02 was schema additions for layered/parasitic; this is a separate concern that emerged from the symbiosis-bonus relocation.)

In `prestige_system.start_run`, after the niche is resolved and the run is initialized:
```gdscript
var niche: NicheData = _get_niche_by_id(resolved_niche)
if niche != null and not niche.start_bonus.is_empty():
    for resource_id in niche.start_bonus.keys():
        if MetaModifiers.is_unlocked(&"symbiotic_generosity"):
            ResourceLedger.add(StringName(resource_id), float(niche.start_bonus[resource_id]))
```

Wait — that's wrong; we don't want the bonus only when symbiotic_generosity is unlocked for ALL niches with start_bonus. The bonus is specifically the `symbiotic_generosity` upgrade's effect on Lichen runs.

Refactor: make the bonus payment conditional per the original semantics. The cleanest is to put the conditional in the niche data itself:

Extend `NicheData`:
```gdscript
# {resource_id: amount} granted at run start IF the listed meta-node is unlocked.
# Empty = no bonus. Used by the symbiotic_generosity → Lichen niche bridge.
@export var conditional_start_bonus: Dictionary = {}
# Evolution node id gating the conditional_start_bonus. Empty = unconditional.
@export var conditional_start_bonus_requires: StringName = &""
```

On Lichen's niche:
```
conditional_start_bonus = {"biomass": 10.0, "nutrients": 5.0}
conditional_start_bonus_requires = &"symbiotic_generosity"
```

In `prestige_system.start_run` (after run init):
```gdscript
var niche: NicheData = _get_niche_by_id(resolved_niche)
if niche != null and not niche.conditional_start_bonus.is_empty():
    if niche.conditional_start_bonus_requires == &"" or MetaModifiers.is_unlocked(niche.conditional_start_bonus_requires):
        for resource_id in niche.conditional_start_bonus.keys():
            ResourceLedger.add(StringName(resource_id), float(niche.conditional_start_bonus[resource_id]))
```

Other niches can use this hook later for their own start-bonuses without code changes.

**Option B**: Hardcode the symbiotic_generosity check on Lichen by name in `prestige_system.start_run`:
```gdscript
if resolved_niche == &"lichen" and MetaModifiers.is_unlocked(&"symbiotic_generosity"):
    ResourceLedger.add(ResourceLedger.BIOMASS, 10.0)
    ResourceLedger.add(ResourceLedger.NUTRIENTS, 5.0)
```

Simpler, but reintroduces a hardcoded niche name. **Pick Option A** for the data-driven payoff.

## Acceptance criteria
- [ ] `data/species/lichen_common.tres` loads in inspector with `layer_count = 2` and `layer_species` populated.
- [ ] `data/niches/lichen.tres` loads with `expects_layered = true`.
- [ ] Buying `unlock_symbiosis` (now "Lichen Heritage") makes the Lichen niche available in the Fungi niche selector. Symbiosis kingdom no longer appears.
- [ ] Starting a Lichen run: `current_kingdom_id == &"fungi"`, `current_niche_id == &"lichen"`. MultiLayerPlacementSystem detects layered. HUD layer toggle visible.
- [ ] Place fungi tiles (Fungi layer active) → subsurface fungi colonization works.
- [ ] Toggle to Plantae layer → tap → surface plantae colonization works.
- [ ] Yields tick correctly — fungi yields from fungi tiles, plant yields from plant tiles. Mutualism / wood_wide_web bonuses apply per their normal logic (those nodes already check surface-plantae + subsurface-fungi adjacency, which still works in a Lichen run).
- [ ] With `symbiotic_generosity` unlocked, a fresh Lichen run starts with +10 biomass + 5 nutrients. Without it, no bonus.
- [ ] Lichen discovery entry (`disc_node_lichen_heritage`, "The Body That Is Two Bodies") fires when the player buys `unlock_symbiosis`. Phase 9 brief 07 already authored this entry; trigger via the node-purchase path (regression).
- [ ] Migrated v9 → v10 symbiosis-in-flight runs now play as Lichen — no UX dead-end.

## Out of scope
- Per-niche signature mechanics (briefs 06–07).
- Animal kingdom (briefs 08–09).
- Lichen-specific visual tile variant (brief 11 graphics pass — for v1 the player sees normal plantae green + fungi violet alternating).
- 3+ layer support (Phase 14).
- Per-layer separate stub-resource yields (Phase 14).
