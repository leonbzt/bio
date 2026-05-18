# Brief 05 — Event content pass (backfill scope + author new scoped events)

**Suggested agent**: Kilo for the backfill edits + ChatGPT 5.2 for the new events (data only). Claude reviews the scope assignments.

Read first:
1. `docs/briefs/phase_13/04_event_scope_schema.md` — schema this brief populates.
2. `data/events/*.tres` — current event roster.
3. `data/events/_index.tres` — append the four new events.
4. `scripts/systems/ambient_modifier_system.gd` — how payload `modifiers` get applied (drought / cool_spell pattern).

## Goal

Two-part content pass:

1. **Backfill** existing events with explicit `scope`.
2. **Author 4 new scoped events** — one kingdom-scoped (fungi), one era-scoped (Cryogenian), one ecosystem-scoped (Devonian swamp), one era-scoped (Devonian).

## Part 1 — Backfill existing events

Edit each `.tres` to add explicit `scope` + `scope_target`:

| File | scope | scope_target |
|---|---|---|
| `data/events/drought.tres` | `&"world"` | `&""` |
| `data/events/cool_spell.tres` | `&"world"` | `&""` |
| `data/events/herbivore_wave.tres` | `&"kingdom"` | `&"plantae"` |
| `data/events/spore_infection.tres` | `&"kingdom"` | `&"fungi"` |
| `data/events/mass_extinction.tres` | `&"world"` | `&""` |

Example edit shape (herbivore_wave):

```
[resource]
script = ExtResource("1")
id = &"herbivore_wave"
display_name = "Herbivore Wave"
description = "A herd has wandered into your territory."
trigger_weight = 1.0
duration_ticks = 60
scope = &"kingdom"
scope_target = &"plantae"
payload = {
"spawn_count": 3,
"chew_ticks": 4,
"speed_ticks": 2,
"hp": 2.0,
"kingdom_required": "plantae"
}
```

Note `payload.kingdom_required` stays — it's now redundant with scope but removing it is a separate cleanup pass. The scope filter (brief 04) replaces its function.

**Decision rationale per event**:
- **drought**: affects sunlight globally; relevant to anything photosynthetic but harmless to fungi — but for v1 we keep it world-scoped to preserve the "every kingdom has tension" feel. Phase 14 can re-scope to `kingdom:plantae` if it feels off.
- **cool_spell**: same logic; world-scoped. Reduced sun affects everyone via the ambient modifier; both plantae and fungi see it (fungi already ignore sun for biomass, but cool_spell also debuffs decay rates conceptually).
- **herbivore_wave**: kingdom-scoped to plantae. Animals eat plants — fungi runs shouldn't be molested.
- **spore_infection**: kingdom-scoped to fungi. The infection acts on fungal tiles specifically (existing handler assumes fungi).
- **mass_extinction**: world (special — `trigger_weight = 0`, only fires from EraSystem).

## Part 2 — Author 4 new scoped events

### `data/events/cold_snap.tres` — Cryogenian era event

```
[gd_resource type="Resource" script_class="EventData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"cold_snap"
display_name = "Cold Snap"
description = "The cold deepens. Tiles slow."
trigger_weight = 0.8
duration_ticks = 90
scope = &"era"
scope_target = &"cryogenian"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.5,
    "biomass_multiplier": 0.7
},
"counter_node": "cryotolerance"
}
```

**Why**: Cryogenian-only event that mechanically extends cool_spell. The `counter_node` hint is for HUD ("Your **Cryotolerance** node reduces this event") — wiring of that hint is a polish task, not blocking.

### `data/events/sulfur_bloom.tres` — Volcanic vent ecosystem event

```
[gd_resource type="Resource" script_class="EventData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"sulfur_bloom"
display_name = "Sulfur Bloom"
description = "Vents belch acid haze. Plantae wither; fungi thrive."
trigger_weight = 0.6
duration_ticks = 60
scope = &"ecosystem"
scope_target = &"cryo_volcanic_vent"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.6,
    "biomass_multiplier": 0.8
},
"fungi_bonus": 1.5
}
```

**Why**: Ecosystem-scoped exemplar. Hostile to plantae, gift to fungi. The `fungi_bonus` payload hint is wired in growth_system (or AmbientModifierSystem) as an opportunistic polish — kingdom-specific multipliers within events are a small extension worth landing now.

### `data/events/wildfire.tres` — Devonian era event

```
[gd_resource type="Resource" script_class="EventData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"wildfire"
display_name = "Wildfire"
description = "Smoke darkens the sky. Old growth burns; new growth follows."
trigger_weight = 0.5
duration_ticks = 75
scope = &"era"
scope_target = &"devonian"
payload = {
"modifiers": {
    "sunlight_multiplier": 0.7,
    "biomass_multiplier": 0.6
},
"post_event_bonus_ticks": 60,
"post_event_biomass_multiplier": 1.3
}
```

**Why**: Devonian-only. The post-event payload fields describe a recovery boost — first 60 ticks after the wildfire ends, biomass yield is +30%. Wiring the post-event hook is a small AmbientModifierSystem extension (timer that schedules a follow-up modifier when the event resolves). If implementation is heavier than expected, ship the event without the follow-up bonus and defer to a follow-on brief — flagged as "graceful degrade".

### `data/events/swamp_fever.tres` — Devonian inland_swamp ecosystem event

```
[gd_resource type="Resource" script_class="EventData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/event_data.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"swamp_fever"
display_name = "Swamp Fever"
description = "Standing water turns; pathogens rise. Animal tiles weaken."
trigger_weight = 0.6
duration_ticks = 60
scope = &"ecosystem"
scope_target = &"dev_inland_swamp"
payload = {
"modifiers": {
    "biomass_multiplier": 0.85
},
"animal_hp_modifier": 0.7
}
```

**Why**: Swamp-only debuff that especially targets animals (placeholder until animal HP system supports event modifiers — until then the modifier hint sits in payload as future scaffolding).

## Update `data/events/_index.tres`

Append all four new events.

## Modifier channel addition

The new events introduce `&"biomass_multiplier"` as a recognized ambient modifier key. Confirm `AmbientModifierSystem` honors it (or add the channel — single dictionary entry alongside `sunlight_multiplier` and `nutrient_multiplier`). `growth_system._apply_yields` reads it via `_ambient.get_multiplier(&"biomass_multiplier")` and multiplies into `per_tile` once per tile for the biomass resource.

Brief 06 also needs this channel (post-extinction debuff uses it), so confirm it's in by the end of brief 05's commit.

## Acceptance criteria

- [ ] All 5 existing events have explicit `scope` + `scope_target` set.
- [ ] All 4 new events load in inspector.
- [ ] All 4 new events registered in `_index.tres`.
- [ ] `AmbientModifierSystem` recognizes `&"biomass_multiplier"`.
- [ ] In a Cryogenian fungi run on `cryo_volcanic_vent`: `cold_snap`, `sulfur_bloom`, `spore_infection` (fungi-scoped) are eligible; `herbivore_wave`, `wildfire`, `swamp_fever` are not.
- [ ] In a Devonian plantae run on `dev_inland_swamp`: `drought`, `cool_spell`, `herbivore_wave`, `wildfire`, `swamp_fever` are eligible; `cold_snap`, `sulfur_bloom`, `spore_infection` are not.
- [ ] No event-rolling regressions on Devonian forest_edge plantae (current Phase 12 baseline).

## Out of scope

- Per-niche scoped events (capability exists, content not written).
- HUD hint surfacing "this event has a counter node" (polish).
- `payload.kingdom_required` cleanup pass on existing events.
- Animal HP system support for `animal_hp_modifier` (placeholder field — Phase 14).
- Post-event scheduled modifiers as a general system (graceful degrade: ship wildfire without the bonus if the timer plumbing is non-trivial).
