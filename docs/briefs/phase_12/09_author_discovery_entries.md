# Brief 09 — Author Phase 12 discovery log entries

**Suggested agent**: this brief authors content directly. Kilo can transcribe each entry into a `.tres` file; review with Claude before committing.

Read first:
1. `docs/STORY_AND_TONE.md` for voice.
2. `docs/briefs/phase_9/07_author_discovery_entries.md` for the existing entry pattern.
3. `scripts/data/discovery_entry.gd` — schema.

## Goal

Author **10 new discovery entries** for Phase 12 content, expanding the total from 28 → 38. Categories:
- 2 kingdom-era boundary entries (the "first time you arrive in an era" framing)
- 6 ecosystem entries (one per ecosystem authored in brief 03; fires on first completion)
- 1 mass-extinction event entry
- 1 milestone (first era transition)

## Schema reminder

`discovery_entry.gd` has fields `id`, `title`, `body`, `category`, `trigger_id`. Brief 06 phase 9's `discovery_log.gd` reads them via `find_entry_for_trigger(category, trigger_id)`.

Phase 12 introduces two new categories that the DiscoveryLog autoload needs to recognize: `&"era"` and `&"ecosystem"`. Extend `discovery_log.gd`:

```gdscript
# Add to _enter_tree:
EventBus.era_changed.connect(_on_era_changed)
EventBus.ecosystem_completed.connect(_on_ecosystem_completed)
EventBus.era_transition_started.connect(_on_era_transition_started)


func _on_era_changed(era_id: StringName) -> void:
    if era_id == &"":
        return
    var entry := find_entry_for_trigger(&"era", era_id)
    if entry != &"":
        unlock(entry)


func _on_ecosystem_completed(ecosystem_id: StringName) -> void:
    var entry := find_entry_for_trigger(&"ecosystem", ecosystem_id)
    if entry != &"":
        unlock(entry)


func _on_era_transition_started(_from: StringName, _to: StringName) -> void:
    var milestone := find_entry_for_trigger(&"milestone", &"first_era_transition")
    if milestone != &"":
        unlock(milestone)
```

The existing `_on_event_resolved` handler will catch the `mass_extinction` event firing and unlock the `disc_event_mass_extinction` entry automatically — no extra wiring needed.

## The 10 entries

### Era entries (2)

**`disc_era_cryogenian.tres`** — category `&"era"`, trigger_id `&"cryogenian"`
> *Title:* The First Cold
>
> The world was ice for an age. The fungi that survived it survived by waiting.
> You wait now. The cold remembers everyone who has ever asked it to break.

**`disc_era_devonian.tres`** — category `&"era"`, trigger_id `&"devonian"`
> *Title:* The Warm Returns
>
> The ice retreated. The water that was always there opened to the light.
> Something rose from it with a structure that could hold itself up. You are about to be that thing.

### Ecosystem entries (6)

**`disc_ecosystem_cryo_polar_ice.tres`** — category `&"ecosystem"`, trigger_id `&"cryo_polar_ice"`
> *Title:* Patience as a Strategy
>
> Three winters held against you. You held against them.
> The ice keeps a ledger. It noted you.

**`disc_ecosystem_cryo_volcanic_vent.tres`** — category `&"ecosystem"`, trigger_id `&"cryo_volcanic_vent"`
> *Title:* The Warmth Below
>
> Twenty bodies arranged around a single seam of heat.
> Civilization, defined down — a small one, made of patience.

**`disc_ecosystem_cryo_under_ice_sea.tres`** — category `&"ecosystem"`, trigger_id `&"cryo_under_ice_sea"`
> *Title:* What the Sea Will Remember
>
> Three hundred units of decay, gathered under a frozen lid.
> When the ice goes — and it will — the spores will rise with it.

**`disc_ecosystem_dev_tidal_pool.tres`** — category `&"ecosystem"`, trigger_id `&"dev_tidal_pool"`
> *Title:* The First Deal Made Twice
>
> Thirty leaves at the salt edge. The pool was a deal you made with the air.
> The land is the next deal.

**`disc_ecosystem_dev_forest_edge.tres`** — category `&"ecosystem"`, trigger_id `&"dev_forest_edge"`
> *Title:* Outlasted
>
> Two waves of mouths came through. Two waves went without you.
> What you made remains. So do you, in some form.

**`disc_ecosystem_dev_inland_swamp.tres`** — category `&"ecosystem"`, trigger_id `&"dev_inland_swamp"`
> *Title:* The Swamp Bargained
>
> Five hundred units of compounded partnership. Two kingdoms sharing a body, sharing a yield, sharing a fate.
> The swamp itself remembers how the deal was made.

### Event entry (1)

**`disc_event_mass_extinction.tres`** — category `&"event"`, trigger_id `&"mass_extinction"`
> *Title:* The Wave That Erased the Drafts
>
> Most of what was built is not. The world goes on.
> So do you, in some form — smaller, older, beginning again. This is how new things become possible.

### Milestone entry (1)

**`disc_milestone_first_era_transition.tres`** — category `&"milestone"`, trigger_id `&"first_era_transition"`
> *Title:* Time Has a Direction
>
> An age ended. Another began. You are the same and not the same.
> The world is going somewhere. You are part of how it gets there.

## `.tres` template

Same pattern as Phase 9 brief 07:

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_era_cryogenian"
title = "The First Cold"
body = "The world was ice for an age. The fungi that survived it survived by waiting.
You wait now. The cold remembers everyone who has ever asked it to break."
category = &"era"
trigger_id = &"cryogenian"
```

## Index update

Append 10 ext_resource lines to `data/discovery/_index.tres` and add to the `entries` array. Final count = 38.

Also update the discovery-log UI's category sectioning (`scripts/ui/discovery_log_screen.gd` from Phase 9 brief 08) to include the two new categories:

```gdscript
const _CATEGORY_HEADERS: Dictionary = {
    &"kingdom":   "Kingdoms",
    &"era":       "Eras",        # NEW
    &"ecosystem": "Ecosystems",  # NEW
    &"niche":     "Niches",
    &"node":      "Nodes",
    &"event":     "Events",
    &"milestone": "Milestones",
}

const _CATEGORY_ORDER: Array[StringName] = [
    &"era", &"ecosystem",        # NEW (placed first for narrative arc)
    &"kingdom", &"niche", &"node", &"event", &"milestone"
]
```

## Acceptance criteria
- [ ] 10 `.tres` files exist with valid schema.
- [ ] `_index.tres` references all 38 (28 existing + 10 new).
- [ ] `DiscoveryLog.get_total_count() == 38` at boot.
- [ ] Era entry "The First Cold" fires on first cold-load with `current_era_id == &"cryogenian"`.
- [ ] Ecosystem entry "Patience as a Strategy" fires when `cryo_polar_ice` is first completed (after prestige).
- [ ] Mass extinction event entry "The Wave That Erased the Drafts" fires on first Cryogenian → Devonian transition (via existing event_resolved → discovery wiring).
- [ ] Milestone entry "Time Has a Direction" fires on the same transition.
- [ ] Discovery log UI shows new categories grouped at the top.

## Out of scope
- Per-discovery sound effects (Phase 13 polish).
- Era-transition entries for future eras (Carboniferous, Mesozoic — phases TBD).
- Animal-kingdom-arrival discovery entry (already exists from Phase 9; fires when player unlocks the kingdom).
