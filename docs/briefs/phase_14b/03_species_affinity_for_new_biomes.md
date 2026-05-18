# Brief 03 — Update species biome_affinity for new biomes

**Suggested agent**: Kilo for the .tres edits. Claude reviews.

Read first:
1. `docs/SPECIES_ROSTER.md` — affinity tables.
2. `data/species/*.tres` — all 12 species.

## Goal

Add new biome keys (`tundra`, `mineral_vent`, `swamp`) to each species's `biome_affinity` dict per the SPECIES_ROSTER.md guidance.

## Per-species updates

Append the listed keys to each species's `biome_affinity` dict (preserve existing keys).

### `cyanobacterial_mat.tres`

```
biome_affinity = {
&"tundra": 1.2,
&"polar_ice": 1.3,   # placeholder — no polar_ice biome exists; tundra serves
&"mineral_vent": 1.0,
&"swamp": 0.6,
&"rich_soil": 1.1,
&"forest_edge": 0.9,
&"grassland": 1.0
}
```

(Drop the placeholder `polar_ice` key if you'd rather not author meaningless data. Keep the `tundra` 1.2.)

### `vent_archaeon.tres`

```
biome_affinity = {
&"mineral_vent": 1.8,
&"tundra": 0.4,
&"swamp": 0.3,
&"rich_soil": 0.5,
&"forest_edge": 0.4,
&"grassland": 0.3
}
```

### `cryo_lichen.tres`

```
biome_affinity = {
&"tundra": 1.3,
&"mineral_vent": 0.8,
&"swamp": 0.6,
&"rich_soil": 1.2,
&"forest_edge": 1.0
}
```

### `mycelium_thread.tres`

```
biome_affinity = {
&"mineral_vent": 1.2,
&"tundra": 0.9,
&"swamp": 1.1,
&"rich_soil": 1.2,
&"forest_edge": 1.0,
&"grassland": 1.0
}
```

### `mycelium_thread_mycorrhizal.tres`

```
biome_affinity = {
&"swamp": 1.4,
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"tundra": 0.7,
&"mineral_vent": 0.6,
&"grassland": 1.0
}
```

### `pioneer_grass.tres` (Pioneer Stem)

```
biome_affinity = {
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"grassland": 1.0,
&"swamp": 0.8,
&"tundra": 0.5,
&"mineral_vent": 0.4
}
```

### `bramble.tres` (Climbing Bramble)

```
biome_affinity = {
&"swamp": 1.4,
&"forest_edge": 1.1,
&"rich_soil": 1.0,
&"grassland": 0.9,
&"tundra": 0.4,
&"mineral_vent": 0.3
}
```

### `lichen_common.tres` (Devonian Lichen)

```
biome_affinity = {
&"forest_edge": 1.3,
&"tundra": 1.1,
&"rich_soil": 1.1,
&"swamp": 0.9,
&"mineral_vent": 0.8,
&"grassland": 1.0
}
```

### `tree_fern_stem.tres`

```
biome_affinity = {
&"swamp": 1.5,
&"forest_edge": 1.3,
&"rich_soil": 1.2,
&"grassland": 0.9,
&"tundra": 0.5,
&"mineral_vent": 0.4
}
```

### `wood_rot_bracket.tres`

```
biome_affinity = {
&"swamp": 1.4,
&"forest_edge": 1.2,
&"rich_soil": 1.1,
&"grassland": 0.9,
&"tundra": 0.4,
&"mineral_vent": 0.6
}
```

### `common_grazer.tres` (Lobe-Finned Browser)

```
biome_affinity = {
&"swamp": 1.3,
&"rich_soil": 1.2,
&"forest_edge": 1.1,
&"grassland": 1.0,
&"tundra": 0.5,
&"mineral_vent": 0.3
}
```

### `common_predator.tres` (Apex Stalker)

```
biome_affinity = {
&"swamp": 1.3,
&"forest_edge": 1.0,
&"rich_soil": 1.1,
&"tundra": 0.4,
&"mineral_vent": 0.3,
&"grassland": 0.9
}
```

## Acceptance criteria

- [ ] All 12 species (.tres) files have `tundra`, `mineral_vent`, `swamp` keys in `biome_affinity`.
- [ ] Values match the SPECIES_ROSTER.md guidance.
- [ ] Picker shows correct yields when placed on the new biomes (verifiable with brief 08's smoke test).
- [ ] No species hits 0.0 affinity on any biome (lowest = 0.3, prevents complete-loss runs).

## Out of scope

- Trait-based affinity overrides (Phase 15+).
- Per-ecosystem unique affinity overrides ("Vent Archaeon gets +0.2 in cryo_volcanic_vent specifically"). Future polish.
- Successor / pollinator predicate wiring (Phase 15).
