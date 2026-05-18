# Brief 03 — Existing species update (latin_name + lineage_id + biome_affinity)

**Suggested agent**: Kilo for the .tres edits. Claude reviews per-species values.

Read first:
1. `docs/SPECIES_ROSTER.md` — full mapping table.
2. `data/species/*.tres` — current 7 species files.

## Goal

Backfill the three new schema fields (brief 02) on all 7 existing species. Display names stay the same; some get renamed display strings to match the roster table (e.g., `pioneer_grass` → "Pioneer Stem").

## Per-species edits

### `data/species/pioneer_grass.tres`

```
display_name = "Pioneer Stem"
latin_name = "Cooksonia caledonica (Silurian-Devonian)"
lineage_id = &"pioneer_stem"
biome_affinity = {
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"grassland": 1.0,
&"swamp": 0.8
}
```

Keep `id = &"pioneer_grass"` unchanged — id is a stable key, only display_name shifts.

### `data/species/mycelium_thread.tres`

```
display_name = "Mycelium Thread"
latin_name = "Glomeromycota basalis (Ordovician-now)"
lineage_id = &"mycorrhizal"
biome_affinity = {
&"rich_soil": 1.2,
&"forest_edge": 1.0,
&"grassland": 1.0
}
```

### `data/species/mycelium_thread_mycorrhizal.tres`

```
display_name = "Mycorrhizal Mycelium"
latin_name = "Glomus intraradices (Ordovician-now)"
lineage_id = &"mycorrhizal"
biome_affinity = {
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"grassland": 1.0
}
```

(Bonded-tile bonus already comes from existing 1.20× mycorrhizal_bond multiplier in growth_system — biome_affinity stacks on top.)

### `data/species/bramble.tres`

```
display_name = "Climbing Bramble"
latin_name = "Trimerophyton robustius (Early Devonian)"
lineage_id = &"parasitic_climber"
biome_affinity = {
&"forest_edge": 1.1,
&"rich_soil": 1.0,
&"grassland": 0.9
}
```

### `data/species/lichen_common.tres`

```
display_name = "Devonian Lichen"
latin_name = "Pertusariales devonica (Devonian-now)"
lineage_id = &"lichen"
biome_affinity = {
&"forest_edge": 1.3,
&"rich_soil": 1.1,
&"grassland": 1.0
}
```

### `data/species/common_grazer.tres`

```
display_name = "Lobe-Finned Browser"
latin_name = "Eusthenopteron foordi (Late Devonian)"
lineage_id = &"tetrapod_browser"
biome_affinity = {
&"rich_soil": 1.2,
&"forest_edge": 1.1,
&"grassland": 1.0
}
```

### `data/species/common_predator.tres`

```
display_name = "Apex Stalker"
latin_name = "Hyneria lindae (Late Devonian)"
lineage_id = &"tetrapod_predator"
biome_affinity = {
&"rich_soil": 1.1,
&"forest_edge": 1.0
}
```

## Discovery entry display_name sync

The 4 re-categorized niche entries (`disc_niche_*`) have voice text that doesn't reference species display names directly, so no edits required. The species picker + panel render `display_name`, so the new names appear automatically once .tres updates land.

If any discovery entry body or title refers to the old display name (e.g., "Pioneer Grass" or "Common Grazer"), update those references — they're rare enough to grep and confirm:

```bash
grep -rn "Pioneer Grass\|Common Grazer\|Common Predator\|Common Lichen" data/discovery/
```

## Audio crossfade verification

`AudioManager` keys music tracks by kingdom_id, not species_id. No impact from display name changes.

## Acceptance criteria

- [ ] All 7 species files have `latin_name`, `lineage_id`, `biome_affinity` populated per the tables.
- [ ] Existing species display correctly in the species picker with new names.
- [ ] No save-load regression (display_name is data-only, not a save key).
- [ ] Grep for old display names returns either no hits or only documentation.

## Out of scope

- New species (brief 04).
- Yield integration (brief 05).
- Tooltip widget rendering Latin name (small UI polish — fold into brief 04's species panel/picker update).
- Discovery entry body rewrites for new names (light touch in brief 07 if needed).
