# Brief 09 — Animal Predator niche + species (placeholder)

**Suggested agent**: Kilo for data, ChatGPT 5.2 for the placement-rule reuse. Route diff to Claude.

Read first:
1. `docs/briefs/phase_10/08_animal_kingdom_herbivore.md` (must land first — animal kingdom + niche infrastructure).
2. `docs/briefs/phase_10/00_phase_10_entry.md` decision 5 (Predator scope = spawn+move only, deferred actual hunting).

## Goal

Add the Predator niche under Animals. **Placeholder scope**: Predator animals can be spawned, take up a tile, and tick yield. They do NOT actively hunt herbivores or other animals in Phase 10 — that's Phase 14 polish.

After this brief: the Animals niche selector shows two options. The player can play a Predator run and verify the animal kingdom supports multiple niches. The mechanic is intentionally thin — this brief ships an *available niche*, not an exciting one.

## Outputs

### Create `data/species/common_predator.tres`

```
[gd_resource type="Resource" script_class="SpeciesData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/species_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"common_predator"
display_name = "Common Predator"
kingdom_id = &"animals"
base_traits = Array[Resource]([])
colonize_cost = {"protein": 10.0}
tick_yield = {
    "protein": 0.6,
    "lifeforce": 0.05
}
layer_count = 1
layer_species = Array[Resource]([])
```

Predator costs Protein (you need to have hunted something to spawn the next one), produces Protein (cannibalistic loop in placeholder — Phase 14 fixes the loop by routing predator yield from prey kills instead of ambient). Also produces a trickle of Lifeforce.

### Append to `data/species/_index.tres`

Add `common_predator` reference.

### Create `data/niches/predator.tres`

```
[gd_resource type="Resource" script_class="NicheData" load_steps=3 format=3]
[ext_resource type="Script" path="res://scripts/data/niche_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/species/common_predator.tres" id="2"]

[resource]
script = ExtResource("1")
id = &"predator"
display_name = "Predator"
description = "You hunt what moves. The pursuit teaches you patience. (Phase 10 placeholder — full hunting in Phase 14.)"
kingdom_id = &"animals"
species_options = Array[Resource]([ExtResource("2")])
colonization_rule = &"animal_anchor"    # reuses the rule from brief 08
cost_override = {}
unlock_node_id = &""    # available from animal kingdom unlock; no separate node
tile_variant = &"animals_predator"
expects_layered = false
parasitic_targets = []
```

### Append to `data/niches/_index.tres`

Add `predator` reference.

### `GrowthSystem._tick_animals` already covers this

Because brief 08's `_tick_animals` calls `_apply_yields(species, coords, &"animals", 1.0)` with the active species (resolved via niche), no per-niche logic is needed. Predator's `tick_yield` (0.6 protein, 0.05 lifeforce) ticks via the same path that Herbivore's yields tick.

The wander-radius biomass bonus in brief 08 is grassland-specific — it doesn't apply to Predator. That's fine; Predator's identity is different and doesn't need the grazing bonus.

### HUD ability bar

Predator gets no new ability in Phase 10 (no Toxin-Bloom equivalent for predators yet). Brief 11's HUD ability bar already handles per-niche ability sets via the `AbilityData.unlock_node_id` check. With no predator-specific abilities authored, nothing extra appears. That's expected.

### Discovery log entry

No discovery entry for Predator in Phase 10. The `disc_niche_predator` entry can be authored in Phase 14 when the niche becomes mechanically interesting (full hunting). Listing here as a follow-up; not blocking.

## Acceptance criteria
- [ ] Predator niche button appears in the Animals niche selector after `unlock_animals` is purchased.
- [ ] Choosing Predator → run starts: `kingdom_id == &"animals"`, `niche_id == &"predator"`.
- [ ] Tap an empty surface tile → Common Predator placed (cost 10 protein).
- [ ] Per-tick yield: 0.6 protein + 0.05 lifeforce per anchored predator.
- [ ] No wander-radius biomass bonus (vs Herbivore which has it).
- [ ] HUD shows Protein + Lifeforce resources ticking.
- [ ] Predator + Herbivore both selectable in same animal kingdom (regression with brief 08).

## Out of scope
- Predators actively pursuing herbivore-wave agents (Phase 14).
- Predators hunting the player's own Herbivore animals from prior runs (would need tile history; parked).
- Predator-specific abilities (Phase 14).
- Predator discovery entry (Phase 14).
- Predator-specific tile variant beyond the variant id (brief 11 graphics).
