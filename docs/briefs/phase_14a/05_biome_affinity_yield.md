# Brief 05 — Biome affinity yield integration in GrowthSystem

**Suggested agent**: ChatGPT 5.2. Route diff to **Claude** — yield math is balance-load-bearing.

Read first:
1. `scripts/systems/growth_system.gd` — current `_apply_yields` (post Phase 13 brief 05).
2. `docs/SPECIES_ROSTER.md` §Biome affinity guidance.

## Goal

Multiply `species.biome_affinity.get(biome.id, 1.0)` into per-tile biomass yield. Default missing key = 1.0 (no behavior change for species without a populated affinity dict).

Apply only to biomass for v1 — decay and spores stay neutral. Phase 15+ can extend if a content design surfaces that needs per-biome decay tuning.

## Implementation

### `scripts/systems/growth_system.gd._apply_yields`

In the biomass branch, after biome is resolved, apply affinity. The change is one line per kingdom path:

```gdscript
if resource_key == &"biomass":
    if kingdom_id == &"fungi":
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
        # Phase 14a: biome affinity (fungi path — biome may still be relevant
        # even without sun, e.g. swamp decay-rich vs tundra frozen).
        var biome_for_affinity: BiomeData = _nutrients.get_biome_at(coord)
        if biome_for_affinity != null:
            per_tile *= float(species.biome_affinity.get(biome_for_affinity.id, 1.0))
    else:
        var biome: BiomeData = _nutrients.get_biome_at(coord)
        if biome == null:
            continue
        var local_sun_mult := sun_mult
        if _is_tile_warmed(coord) and _ambient.has_method("get_event_multiplier"):
            var cool_mult: float = float(_ambient.get_event_multiplier(&"cool_spell", &"sunlight_multiplier"))
            if cool_mult > 0.0:
                local_sun_mult = sun_mult / cool_mult
        per_tile *= biome.sunlight_per_tick * local_sun_mult
        per_tile *= (1.0 + float(trait_mods.get(&"biomass_per_tile", 0.0)))
        per_tile *= meta_mult
        if kingdom_id == &"plantae" and MetaModifiers.is_unlocked(&"soil_memory"):
            per_tile *= 1.15
        if _is_tile_mycorrhizal_bonded(coord):
            per_tile *= 1.20
        # Phase 14a: biome affinity (plantae/animals path).
        per_tile *= float(species.biome_affinity.get(biome.id, 1.0))
```

Place the affinity multiplier **after** all other biomass multipliers but **before** the symbiosis stack (so symbiosis still multiplies on top of an already-biome-tuned base). The diff is two single-line additions.

### Logging guard (optional, for smoke test)

Add a debug print toggle:

```gdscript
const DEBUG_BIOME_AFFINITY: bool = false

# Inside _apply_yields, after multiplier applied:
if DEBUG_BIOME_AFFINITY:
    var aff: float = float(species.biome_affinity.get(biome.id, 1.0))
    if aff != 1.0:
        print("[GrowthSystem] %s on %s: affinity=%.2f per_tile=%.3f" % [species.id, biome.id, aff, per_tile])
```

Leave `DEBUG_BIOME_AFFINITY = false` in main. Flip true locally for the smoke test.

## Verification

Manual: in a Devonian forest_edge run with Pioneer Stem:
- Tiles on `forest_edge` biome should produce ~20% more biomass than the same setup on a `grassland` tile (1.2 vs 1.0 affinity).

In a Cryogenian volcanic_vent run with Vent Archaeon (post Phase 14b biomes):
- Tiles on `mineral_vent` produce significantly more than tiles on the natural-mix biomes (1.8 vs 0.3-0.5 affinity).

## Acceptance criteria

- [ ] Biomass tick on a tile reads `species.biome_affinity` and multiplies.
- [ ] Missing biome key = 1.0 (no behavior change for species without populated affinity).
- [ ] No regression on Phase 13 ship runs (lichen, parasite, herbivore, etc.) — measured by total biomass earned over a fixed-seed 60-tick run.
- [ ] Fungi path also applies affinity (despite sunlight-skip — fungi still care about decay substrate per biome).
- [ ] Recipe species (e.g., Cryo-Lichen) don't double-apply: components tick independently with their own affinities.

## Out of scope

- Per-biome decay or spore yield (only biomass for v1).
- Animal-specific affinity tuning (animals tick like plantae path; same wiring).
- Tooltip surface ("this species earns 30% more here") — Phase 15 polish.
- Trait-based affinity boosts (`+10% affinity to all biomes`) — Phase 15 if needed.
