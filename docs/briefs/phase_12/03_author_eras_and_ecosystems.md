# Brief 03 — Author 2 eras × 3 ecosystems content

**Suggested agent**: Kilo for mechanical `.tres` creation; Claude reviews voice + balance.

Read first:
1. `docs/briefs/phase_12/02_era_ecosystem_schemas.md` (must land first).
2. `docs/STORY_AND_TONE.md` for voice.
3. `docs/briefs/phase_9/07_author_discovery_entries.md` for the voice pattern (1–3 sentences, mythic-scientific).

## Goal

Author 2 eras and 6 ecosystems (3 per era). All content text is final — copy verbatim.

## Era 1: Cryogenian

**`data/eras/cryogenian.tres`**

```
[gd_resource type="Resource" script_class="EraData" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/data/era_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_polar_ice.tres" id="2"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_volcanic_vent.tres" id="3"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_under_ice_sea.tres" id="4"]

[resource]
script = ExtResource("1")
id = &"cryogenian"
display_name = "Cryogenian"
description = "Ice covers most of the world. Light is dim. The first life that survives here will be fungi — extremophiles, decomposers, the patient kind."
available_kingdoms = [&"fungi"]
ecosystems = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4")])
tint_color = Color(0.72, 0.85, 1.0, 0.15)
transition_narrative = ""
unlock_requires_prev_era = &""
```

## Era 2: Devonian

**`data/eras/devonian.tres`**

```
[gd_resource type="Resource" script_class="EraData" load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/data/era_data.gd" id="1"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_tidal_pool.tres" id="2"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_forest_edge.tres" id="3"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_inland_swamp.tres" id="4"]

[resource]
script = ExtResource("1")
id = &"devonian"
display_name = "Devonian"
description = "The ice retreated. Something climbed out of the water with a structure that could hold itself up. Plants. Fungi. The first animals."
available_kingdoms = [&"plantae", &"fungi", &"animals"]
ecosystems = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4")])
tint_color = Color(0.65, 0.9, 0.55, 0.10)
transition_narrative = "For ages, ice. The fungi held on in cracks and crevices, eating the dead of things that died before they had names.

Then the warm. The seas opened. Something climbed out of the water with a structure that could hold itself up.

You are about to be a plant. You have never been a plant before.

Begin again."
unlock_requires_prev_era = &"cryogenian"
```

## Era 1 Ecosystems (Cryogenian — fungi-only)

### `data/ecosystems/cryo_polar_ice.tres`

```
[gd_resource type="Resource" script_class="EcosystemData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/ecosystem_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cryo_polar_ice"
display_name = "Polar Ice Cap"
description = "Thin sun. Thick ice. The fungi here live in the gaps between freezings."
era_id = &"cryogenian"
completion_criterion = &"events_survived"
completion_target = 3.0
completion_required_niche = &""
completion_required_kingdom = &"fungi"
unlock_text = "The cold is older than thought. What survives it survives by waiting."
complete_text = "Three winters held. The ice did not name you, but you remained."
biome_preference = &"rich_soil"
```

### `data/ecosystems/cryo_volcanic_vent.tres`

```
[resource]
script = ExtResource("1")
id = &"cryo_volcanic_vent"
display_name = "Volcanic Vent"
description = "Heat from below. The world's pulse, somewhere down there. Fungi crowd where the warmth seeps up."
era_id = &"cryogenian"
completion_criterion = &"tiles_colonized"
completion_target = 20.0
completion_required_niche = &""
completion_required_kingdom = &"fungi"
unlock_text = "The world is not all cold. Find the warmth and grow into it."
complete_text = "Twenty bodies arranged around a single seam of heat. A small civilization, made of patience."
biome_preference = &"forest_edge"
```

### `data/ecosystems/cryo_under_ice_sea.tres`

```
[resource]
script = ExtResource("1")
id = &"cryo_under_ice_sea"
display_name = "Under-ice Sea"
description = "Liquid water under a frozen lid. Spores drift in currents the surface will never know."
era_id = &"cryogenian"
completion_criterion = &"biomass_earned"
completion_target = 300.0
completion_required_niche = &""
completion_required_kingdom = &"fungi"
unlock_text = "Below the ice, the sea remembers being warm. It will be warm again."
complete_text = "What you grew here will rise when the ice does. The spores already know the way."
biome_preference = &"grassland"
```

## Era 2 Ecosystems (Devonian — all kingdoms)

### `data/ecosystems/dev_tidal_pool.tres`

```
[resource]
script = ExtResource("1")
id = &"dev_tidal_pool"
display_name = "Tidal Pool"
description = "Salt water at the edge of land. The first plants test what the air does to their leaves."
era_id = &"devonian"
completion_criterion = &"tiles_colonized"
completion_target = 30.0
completion_required_niche = &""
completion_required_kingdom = &"plantae"
unlock_text = "You unfurl. The light meets the chlorophyll meets the carbon and the carbon stays."
complete_text = "Thirty leaves. The pool is yours. The dry land is what comes next."
biome_preference = &"grassland"
```

### `data/ecosystems/dev_forest_edge.tres`

```
[resource]
script = ExtResource("1")
id = &"dev_forest_edge"
display_name = "Forest Edge"
description = "Where the tall things end and the open ground begins. The herd that wandered through has not gone far."
era_id = &"devonian"
completion_criterion = &"events_survived"
completion_target = 2.0
completion_required_niche = &""
completion_required_kingdom = &"plantae"
unlock_text = "Movement at the edge of your territory. Mouths. Stomachs."
complete_text = "Two waves came and went. You are still here, and so is what you made."
biome_preference = &"forest_edge"
```

### `data/ecosystems/dev_inland_swamp.tres`

```
[resource]
script = ExtResource("1")
id = &"dev_inland_swamp"
display_name = "Inland Swamp"
description = "Wet. Decomposing. Crowded. The kind of place where two kingdoms learn to share a body."
era_id = &"devonian"
completion_criterion = &"biomass_earned"
completion_target = 500.0
completion_required_niche = &"lichen"
completion_required_kingdom = &""
unlock_text = "Where the water sits, the fungi find the plants. The bargain follows."
complete_text = "Five hundred units of compounded partnership. The swamp itself is your monument."
biome_preference = &"rich_soil"
```

## Indexes

### `data/eras/_index.tres`

```
[gd_resource type="Resource" script_class="EraIndex" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/data/era_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/eras/cryogenian.tres" id="2"]
[ext_resource type="Resource" path="res://data/eras/devonian.tres" id="3"]

[resource]
script = ExtResource("1")
eras = Array[Resource]([ExtResource("2"), ExtResource("3")])
```

### `data/ecosystems/_index.tres`

```
[gd_resource type="Resource" script_class="EcosystemIndex" load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/data/ecosystem_index.gd" id="1"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_polar_ice.tres" id="2"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_volcanic_vent.tres" id="3"]
[ext_resource type="Resource" path="res://data/ecosystems/cryo_under_ice_sea.tres" id="4"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_tidal_pool.tres" id="5"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_forest_edge.tres" id="6"]
[ext_resource type="Resource" path="res://data/ecosystems/dev_inland_swamp.tres" id="7"]

[resource]
script = ExtResource("1")
ecosystems = Array[Resource]([ExtResource("2"), ExtResource("3"), ExtResource("4"), ExtResource("5"), ExtResource("6"), ExtResource("7")])
```

## Acceptance criteria
- [ ] 2 era .tres files + 6 ecosystem .tres files exist.
- [ ] Both indexes resolve all references.
- [ ] Cold load: `EraIndex.eras.size() == 2`, `EcosystemIndex.ecosystems.size() == 6`.
- [ ] Devonian's `unlock_requires_prev_era == &"cryogenian"`.
- [ ] Cryogenian.available_kingdoms is `[&"fungi"]` (single-element array).
- [ ] Each Cryogenian ecosystem's `completion_required_kingdom == &"fungi"`.
- [ ] `dev_inland_swamp.completion_required_niche == &"lichen"` (gates on layered playthrough).

## Out of scope
- EraSystem autoload (brief 04).
- World map UI (brief 05).
- Era transition narrative passage UI (brief 06) — this brief just stores the text.
