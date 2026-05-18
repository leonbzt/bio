# Brief 08 — Discovery entries for Phase 14b content (~10)

**Suggested agent**: Claude writes voice text directly.

Read first:
1. `data/discovery/*.tres` for voice reference.
2. `docs/briefs/phase_13_paused/09_discovery_entries.md` — most of these survive intact, voice unchanged.

## Goal

Author 10 new discovery entries: 3 biome, 4 event, 2 era-gated node, 1 milestone. Voice consistency with existing entries (two-sentence prose, mythic-scientific, "you" addresses the lineage).

## Entries

### 1. `disc_biome_tundra.tres`

```
title = "The Long Sleep of Roots"
body = "Even where the sun reaches, the soil refuses it. Nothing here decays — death is just storage with no key.
What you build here, the cold will keep. For as long as you mean to wait."
category = &"biome"
trigger_id = &"tundra"
```

### 2. `disc_biome_mineral_vent.tres`

```
title = "The Sunless Bloom"
body = "There is no light here, but there is heat, and that is enough — the rock itself feeds anything patient enough to ask.
First life learned to eat the world before it learned to eat the sun."
category = &"biome"
trigger_id = &"mineral_vent"
```

### 3. `disc_biome_swamp.tres`

```
title = "Where Death Composes Itself"
body = "Standing water and standing rot make one substance, and from that substance everything draws.
Whatever dies here joins you, eventually. You eat your ancestors. They are not insulted."
category = &"biome"
trigger_id = &"swamp"
```

### 4. `disc_event_cold_snap.tres`

```
title = "The Cold Becomes Geography"
body = "What began as a season becomes a place; the chill outlasts the year.
Your tiles slow but do not stop. Slow is not stopped. Remember the difference."
category = &"event"
trigger_id = &"cold_snap"
```

### 5. `disc_event_sulfur_bloom.tres`

```
title = "The Air Turns Yellow"
body = "The vent exhales harder. Anything with leaves regrets having them; anything without thrives.
The wrong shape at the wrong time costs everything. Right shapes have their own seasons."
category = &"event"
trigger_id = &"sulfur_bloom"
```

### 6. `disc_event_wildfire.tres`

```
title = "The Forest Eats Itself"
body = "Smoke buries the sun for a while. After the burn, the soil is richer than it was before — fire is also a kind of gift, if you survive the giving.
You always survive the giving. Otherwise you would not be here to remember it."
category = &"event"
trigger_id = &"wildfire"
```

### 7. `disc_event_swamp_fever.tres`

```
title = "The Water Turns"
body = "The pools grow warm and dark. What lives in them lives in everything that drinks them, and what cannot adapt becomes substrate.
The wetlands are not cruel. They are simply older than the species they correct."
category = &"event"
trigger_id = &"swamp_fever"
```

### 8. `disc_node_cryotolerance.tres`

```
title = "Antifreeze in the Sap"
body = "The chemistry that lets a cell not freeze is older than cells that can think about it.
You learn to wear the cold the way other lineages wear the sun. It is the same act."
category = &"node"
trigger_id = &"cryotolerance"
```

### 9. `disc_node_chemosynthetic_pathway.tres`

```
title = "Eat the Rock"
body = "Before chlorophyll, there was sulfur and iron, and the first hunger was for these.
You remember it now. You were never really dependent on the sun. The sun was a convenience."
category = &"node"
trigger_id = &"chemosynthetic_pathway"
```

### 10. `disc_milestone_extinction_survivor.tres`

```
title = "What the Survivors Brought Forward"
body = "The lineages that crossed the threshold are not the lineages that walked toward it. Catastrophe rewrites the page; survivors edit the rewrite.
You carry forward what the dying could not. You are the part of them that learned."
category = &"milestone"
trigger_id = &"extinction_survivor"
```

## Optional bonus (ship if scope allows)

### `disc_node_vascular_network.tres`

```
title = "Veins Across the Canopy"
body = "Each plant alone is small. The network of plants is large, and the large thing decides what the small things become.
Connection compounds. Refuse it and you remain a small thing among small things."
category = &"node"
trigger_id = &"vascular_network"
```

### `disc_node_mass_fruiting.tres`

```
title = "The Forest Inhales"
body = "Once a season — sometimes once a century — every mushroom in the wood opens at once.
The spores go everywhere. Most go nowhere. The ones that go somewhere become you."
category = &"node"
trigger_id = &"mass_fruiting"
```

### `disc_node_extinction_survivor.tres`

(Distinct from the milestone above — fires on purchasing the cross-era node.)

```
title = "The Memory of the End"
body = "You remember the dying because it cost you something to remember.
The cost is also the gift. The lineages that paid it move faster than the ones that did not."
category = &"node"
trigger_id = &"extinction_survivor"
```

## DiscoveryLog wiring

Two new categories appear here:
- **`biome`**: triggered when a run starts on a map that contains the biome. NutrientSystem can emit a `biomes_in_play(biome_ids)` signal on `_on_run_loaded`, or DiscoveryLog can directly query the biome map.

Add to DiscoveryLog:

```gdscript
func _on_run_loaded(_save_version: int) -> void:
    # ... existing logic ...
    _check_biomes_in_play()

func _check_biomes_in_play() -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
    var seen: Dictionary = {}
    for k in biome_map.values():
        seen[StringName(k)] = true
    for biome_id in seen.keys():
        var entry := find_entry_for_trigger(&"biome", biome_id)
        if entry != &"":
            unlock(entry)
```

- **`milestone` extinction_survivor**: brief 05's PrestigeSystem already emits `EventBus.discovery_unlocked.emit(&"disc_milestone_extinction_survivor")` directly. Confirm the entry id matches.

## Update `data/discovery/_index.tres`

Append all 10 (or 13 with bonus) entries. Increment `load_steps`.

## Acceptance criteria

- [ ] All 10 (or 13) entries load in inspector.
- [ ] All registered in `_index.tres`.
- [ ] Biome entries unlock when player runs on a map containing the biome.
- [ ] Event entries unlock on first event firing.
- [ ] Node entries unlock on purchase.
- [ ] `disc_milestone_extinction_survivor` unlocks on first survivor prestige.
- [ ] Voice consistency confirmed (two-sentence prose pattern preserved).
- [ ] Discovery count denominator increases by +10 (or +13).

## Out of scope

- Discovery entries for paused-Phase-13 ecosystem flavor (Phase 12 already shipped 6 ecosystem entries).
- Cross-references / "see also" linkage between entries (Phase 15+).
- Audio cues per entry category.
- Voice-acted entries.
