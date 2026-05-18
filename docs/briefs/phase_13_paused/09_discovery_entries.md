# Brief 09 — Discovery entries for Phase 13 content (~10 new)

**Suggested agent**: Claude writes the voice text directly. No Kilo flavor pass.

Read first:
1. `scripts/data/discovery_entry.gd` — schema.
2. `data/discovery/_index.tres` — registration pattern.
3. `data/discovery/disc_era_cryogenian.tres`, `data/discovery/disc_event_mass_extinction.tres` — voice reference. Two-sentence prose, second sentence reframes the first; "you" addresses the player as the lineage; concrete imagery, no glossary, no in-game numbers.
4. `docs/STORY_AND_TONE.md` (if it exists) — voice rules.

## Goal

Author 10 new discovery entries covering Phase 13 content. All in mythic-scientific voice. Register all 10 in `_index.tres`.

## Entries to author

### 1. `disc_biome_tundra` — biome category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_biome_tundra"
title = "The Long Sleep of Roots"
body = "Even where the sun reaches, the soil refuses it. Nothing here decays — death is just storage with no key.
What you build here, the cold will keep. For as long as you mean to wait."
category = &"biome"
trigger_id = &"tundra"
```

### 2. `disc_biome_mineral_vent` — biome category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_biome_mineral_vent"
title = "The Sunless Bloom"
body = "There is no light here, but there is heat, and that is enough — the rock itself feeds anything patient enough to ask.
First life learned to eat the world before it learned to eat the sun."
category = &"biome"
trigger_id = &"mineral_vent"
```

### 3. `disc_biome_swamp` — biome category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_biome_swamp"
title = "Where Death Composes Itself"
body = "Standing water and standing rot make one substance, and from that substance everything draws.
Whatever dies here joins you, eventually. You eat your ancestors. They are not insulted."
category = &"biome"
trigger_id = &"swamp"
```

### 4. `disc_event_cold_snap` — event category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_event_cold_snap"
title = "The Cold Becomes Geography"
body = "What began as a season becomes a place; the chill outlasts the year.
Your tiles slow but do not stop. Slow is not stopped. Remember the difference."
category = &"event"
trigger_id = &"cold_snap"
```

### 5. `disc_event_sulfur_bloom` — event category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_event_sulfur_bloom"
title = "The Air Turns Yellow"
body = "The vent exhales harder. Anything with leaves regrets having them; anything without thrives.
The wrong shape at the wrong time costs everything. Right shapes have their own seasons."
category = &"event"
trigger_id = &"sulfur_bloom"
```

### 6. `disc_event_wildfire` — event category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_event_wildfire"
title = "The Forest Eats Itself"
body = "Smoke buries the sun for a while. After the burn, the soil is richer than it was before — fire is also a kind of gift, if you survive the giving.
You always survive the giving. Otherwise you would not be here to remember it."
category = &"event"
trigger_id = &"wildfire"
```

### 7. `disc_event_swamp_fever` — event category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_event_swamp_fever"
title = "The Water Turns"
body = "The pools grow warm and dark. What lives in them lives in everything that drinks them, and what cannot adapt becomes substrate.
The wetlands are not cruel. They are simply older than the species they correct."
category = &"event"
trigger_id = &"swamp_fever"
```

### 8. `disc_node_cryotolerance` — node category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_node_cryotolerance"
title = "Antifreeze in the Sap"
body = "The chemistry that lets a cell not freeze is older than cells that can think about it.
You learn to wear the cold the way other lineages wear the sun. It is the same act."
category = &"node"
trigger_id = &"cryotolerance"
```

### 9. `disc_node_chemosynthetic_pathway` — node category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_node_chemosynthetic_pathway"
title = "Eat the Rock"
body = "Before chlorophyll, there was sulfur and iron, and the first hunger was for these.
You remember it now. You were never really dependent on the sun. The sun was a convenience."
category = &"node"
trigger_id = &"chemosynthetic_pathway"
```

### 10. `disc_milestone_extinction_survivor` — milestone category

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_milestone_extinction_survivor"
title = "What the Survivors Brought Forward"
body = "The lineages that crossed the threshold are not the lineages that walked toward it. Catastrophe rewrites the page; survivors edit the rewrite.
You carry forward what the dying could not. You are the part of them that learned."
category = &"milestone"
trigger_id = &"extinction_survivor"
```

## Bonus entries (optional, if scope budget allows)

Two more nodes from brief 07 deserve entries, but skip if any are non-trivial to author. Include in the .tres files if shipping:

### `disc_node_vascular_network`

```
title = "Veins Across the Canopy"
body = "Each plant alone is small. The network of plants is large, and the large thing decides what the small things become.
Connection compounds. Refuse it and you remain a small thing among small things."
category = &"node"
trigger_id = &"vascular_network"
```

### `disc_node_mass_fruiting`

```
title = "The Forest Inhales"
body = "Once a season — sometimes once a century — every mushroom in the wood opens at once.
The spores go everywhere. Most go nowhere. The ones that go somewhere become you."
category = &"node"
trigger_id = &"mass_fruiting"
```

### `disc_node_extinction_survivor`

(Distinct from the milestone above — the milestone fires on the first survivor run; this node entry fires on purchasing the cross-era node.)

```
title = "The Memory of the End"
body = "You remember the dying because it cost you something to remember.
The cost is also the gift. The lineages that paid it move faster than the ones that did not."
category = &"node"
trigger_id = &"extinction_survivor"
```

## Discovery log trigger wiring

Two new categories appear in this brief: `&"biome"` and `&"milestone"`-with-new-trigger. Confirm `DiscoveryLog` handles them:

- **`biome` category**: needs a new trigger source. The natural place is `NutrientSystem._on_run_loaded` — once the biome map is set, emit a `EventBus.biome_discovered` signal for each unique biome id present in the map (idempotent via DiscoveryLog's existing unlock-idempotency). Or simpler: after biome map generation, loop the map's unique biomes and call `DiscoveryLog.unlock(find_entry_for_trigger(&"biome", biome_id))` for each.

Add to `DiscoveryLog._on_run_loaded` (or wire a new signal):

```gdscript
# In DiscoveryLog, after run loaded.
func _on_biomes_discovered(biome_ids: Array) -> void:
    for biome_id in biome_ids:
        var entry := find_entry_for_trigger(&"biome", StringName(biome_id))
        if entry != &"":
            unlock(entry)
```

NutrientSystem emits the list of unique biomes after generating/loading the map. Implementation choice: a new signal `EventBus.biomes_in_play(biome_ids: Array)` fired on `_on_run_loaded`, or a direct call into DiscoveryLog. Either is fine; the signal pattern is more consistent.

- **`milestone` extinction_survivor**: brief 06 already emits `EventBus.discovery_unlocked.emit(&"milestone_extinction_survivor")` directly on the survivor prestige. Make sure the entry id in the .tres matches that exact string (above uses `disc_milestone_extinction_survivor` as the discovery id, but the trigger_id is `extinction_survivor` and category is `milestone` — the trigger-lookup pattern handles the mapping; the direct `unlock(...)` call in PrestigeSystem should use `&"disc_milestone_extinction_survivor"`, not the trigger_id). Verify the call site in brief 06 uses the entry id, not the trigger id.

## Update `data/discovery/_index.tres`

Append all 10 (or 13 with bonus) entries to the entries array. Increment `load_steps` accordingly.

## Acceptance criteria

- [ ] 10 (or 13) new .tres files load in inspector.
- [ ] All registered in `_index.tres`.
- [ ] Voice consistent with existing entries (two-sentence prose, "you" addresses the lineage, concrete imagery, no game numbers).
- [ ] Biome entries unlock when the player starts a run on a map containing each biome (test by playing one ecosystem per new biome).
- [ ] Event entries unlock when each new event first fires.
- [ ] Node entries unlock when each node is purchased.
- [ ] `disc_milestone_extinction_survivor` unlocks when the first post-extinction run prestiges.
- [ ] Discovery count denominator updates (total = old total + 10 or 13).

## Out of scope

- Per-ecosystem additional flavor entries (the 6 ecosystem entries shipped in Phase 12).
- Cross-references between entries (Phase 14+ — linking discovery entries via a "see also" field).
- Audio cues per category. Polish.
- Voice-acted entries. Far-future polish.
