# Brief 02 — SpeciesData schema additions (biome_affinity, latin_name, lineage_id)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/data/species_data.gd` — current schema.
2. `docs/SPECIES_MODEL.md` §Species.
3. `docs/SPECIES_ROSTER.md` §Naming convention.

## Goal

Three additive fields on `SpeciesData`. No consumer logic yet (briefs 05 + 07 wire them).

## Output

### `scripts/data/species_data.gd`

Append to the schema (preserve all existing fields):

```gdscript
# Phase 14a additions — see docs/SPECIES_ROSTER.md.

# Latin binomial + era hint surfaced in tooltips.
# Example: "Cooksonia caledonica (Silurian-Devonian)".
@export var latin_name: String = ""

# Groups era-variants of the same biological lineage.
# Example: pioneer_grass + cordaite_pioneer + cyanobacterial_mat all share
# lineage_id &"pioneer_stem". Used by discovery-log lineage milestones.
@export var lineage_id: StringName = &""

# Per-biome yield multiplier (applied in GrowthSystem._apply_yields).
# Missing key = 1.0 (neutral). Typical range 0.3 – 1.8.
# Example: {&"swamp": 1.4, &"tundra": 0.6, &"forest_edge": 1.2}.
@export var biome_affinity: Dictionary = {}
```

### Backward compatibility

All three fields are default-valued, so existing `data/species/*.tres` files load without error. Brief 03 populates them on the existing 7 species; brief 04 sets them on the 5 new ones.

Until brief 05 lands the yield integration, biome_affinity is read by nothing (no behavior change).

Until brief 07 lands the lineage discovery wiring, `lineages_played` (from brief 01's save migration) is populated but no entries fire.

## Inspector + serialization sanity

Open `data/species/pioneer_grass.tres` in the inspector. Confirm:
- New `latin_name` (string, empty default)
- New `lineage_id` (StringName, empty default)
- New `biome_affinity` (Dictionary, empty default)
- All existing fields intact.

## ARCHITECTURE.md updates

§4 schema — update `SpeciesData` entry to include the three new fields (and a note that biome_affinity drives a yield multiplier).

## Acceptance criteria

- [ ] `SpeciesData.biome_affinity`, `latin_name`, `lineage_id` exist as exported fields.
- [ ] All existing species files load with no inspector errors.
- [ ] No runtime behavior change yet (consumers don't read the new fields).

## Out of scope

- Populating fields on species files (briefs 03 + 04).
- Yield integration (brief 05).
- Tooltip rendering in species picker / panel (a small UI polish — handled in brief 04's update of the picker/panel).
- Pioneer tag predicate (brief 06).
