# Brief 07 — Author the discovery log entries

**Suggested agent**: this brief authors content directly — no agent dispatch needed. Kilo can mechanically transcribe each entry into its `.tres` file from the table below; review with Claude before committing.

Read first:
1. `docs/STORY_AND_TONE.md` — voice (mythic-scientific, Sagan/Dillard/Kimmerer), 1–4 sentences each.
2. `docs/briefs/phase_9/02_schema_extensions.md` — `DiscoveryEntry` resource shape.
3. `docs/briefs/phase_9/06_discovery_log_triggers.md` — what category/trigger_id maps to what.

## Goal
Author **28 discovery entries** (above the ≥25 target) as `data/discovery/<id>.tres` files, and register them in `data/discovery/_index.tres`.

Distribution:
- Kingdom: 3 (plantae, fungi, symbiosis)
- Niche: 4 (photosynthesizer, decomposer, parasitic_plantae, mycorrhizal_fungi)
- Event: 4 (drought, cool_spell, herbivore_wave, spore_infection)
- Node: 13 (the most narratively load-bearing nodes — entry-tier + capstones)
- Milestone: 4 (prestige_5, prestige_25, prestige_50, first_cross_kingdom_node)

= **28 entries**. Denominator the player sees: "Discoveries: N / 28".

## Voice reminder

> Mythic-scientific. Carl Sagan writing for poets. Grounded in real biology. Second-person introspective is default. 1–4 sentences. Avoid: whimsy, generic-fantasy filler (*ancient*, *mystical*, *primordial*), didactic lecturing, anthropomorphism.

## The 28 entries

Each row is one `.tres` file at `data/discovery/<id>.tres`. The body text below is final — copy it verbatim. The id, category, and trigger_id columns map to brief 06's `find_entry_for_trigger` lookups.

### Kingdom entries

**`disc_kingdom_plantae.tres`** — category `&"kingdom"`, trigger_id `&"plantae"`
> *Title:* The First Deal
>
> You unfurl. The light meets the chlorophyll meets the carbon and the carbon stays.
> This is the first deal you made with the world.

**`disc_kingdom_fungi.tres`** — category `&"kingdom"`, trigger_id `&"fungi"`
> *Title:* The Decomposers Were Already Here
>
> They were waiting. Threading the dark places between roots, eating the dead of things that died before they had names.
> They wait for everything.

**`disc_kingdom_symbiosis.tres`** — category `&"kingdom"`, trigger_id `&"symbiosis"`
> *Title:* Two Lives, One Body
>
> What if the cell that ate the bacterium did not finish eating?
> What if it kept the bacterium, fed it, asked it to stay?
> Most of what you are was once a deal between strangers.

### Niche entries

**`disc_niche_photosynthesizer.tres`** — category `&"niche"`, trigger_id `&"photosynthesizer"`
> *Title:* Photons and Patience
>
> The sun arrives at every leaf for free. The work is in being there to catch it.
> You learn that growth is mostly about holding still in the right place.

**`disc_niche_decomposer.tres`** — category `&"niche"`, trigger_id `&"decomposer"`
> *Title:* The Slow Return
>
> Nothing is wasted, only delayed. The body that fell is the soil that will rise.
> You are the verb between those two nouns.

**`disc_niche_parasitic_plantae.tres`** — category `&"niche"`, trigger_id `&"parasitic_plantae"`
> *Title:* Roots Without Light
>
> Some plants gave up the sun. They learned a faster way: take what the others made.
> The arrangement is not cruel. It is only efficient.

**`disc_niche_mycorrhizal_fungi.tres`** — category `&"niche"`, trigger_id `&"mycorrhizal_fungi"`
> *Title:* The Underground Market
>
> Sugar from the roots above, in exchange for water and phosphorus from the dark below.
> No one wrote this contract. It is older than writing.

### Event entries

**`disc_event_drought.tres`** — category `&"event"`, trigger_id `&"drought"`
> *Title:* The Water That Isn't There
>
> The sky forgets you. The soil dries to a thing that holds nothing.
> What survives a drought is what learned, long ago, to need less.

**`disc_event_cool_spell.tres`** — category `&"event"`, trigger_id `&"cool_spell"`
> *Title:* The Cold Calculation
>
> Metabolism slows. The molecules that built you move a little less surely.
> Cold is not death. Cold is the long pause that decides who keeps going.

**`disc_event_herbivore_wave.tres`** — category `&"event"`, trigger_id `&"herbivore_wave"`
> *Title:* You Learn That You Are Food
>
> Movement at the edge of your territory. Mouths. Stomachs.
> They cannot be reasoned with — only outlasted.

**`disc_event_spore_infection.tres`** — category `&"event"`, trigger_id `&"spore_infection"`
> *Title:* Carried on the Wind
>
> A spore is a possibility you cannot see, wrapped in a coat thinner than rumor.
> Some land where nothing waits. Some land where everything is ready.

### Node entries

**`disc_node_thrifty_growth.tres`** — category `&"node"`, trigger_id `&"thrifty_growth"`
> *Title:* Less Is the New More
>
> Every gram of biomass you do not spend is one the next colony inherits.
> Frugality is patience wearing a different name.

**`disc_node_pioneer_resilience.tres`** — category `&"node"`, trigger_id `&"pioneer_resilience"`
> *Title:* The First to Arrive
>
> Bare rock. Acid soil. Light too bright or barely there.
> Pioneers do not find good places. They make them.

**`disc_node_efficient_photosynthesis.tres`** — category `&"node"`, trigger_id `&"efficient_photosynthesis"`
> *Title:* The Carbon Stays
>
> Six waters. Six carbons. One sugar. A trick the world has been working on for three billion years.
> You inherit a small refinement.

**`disc_node_toxin_potency.tres`** — category `&"node"`, trigger_id `&"toxin_potency"`
> *Title:* Bitter By Design
>
> The plants that survived being eaten were the ones that tasted wrong.
> You sharpen the lesson.

**`disc_node_unlock_fungi.tres`** — category `&"node"`, trigger_id `&"unlock_fungi"`
> *Title:* Beneath the Green
>
> All your roots, you now realize, were already touched by something.
> The fungi were always there. You just had not asked their name.

**`disc_node_unlock_symbiosis.tres`** — category `&"node"`, trigger_id `&"unlock_symbiosis"`
> *Title:* The Word for Two
>
> *Symbiosis*. From the Greek for "living together."
> The word arrived only recently. The thing it names is older than most of life.

**`disc_node_wood_wide_web.tres`** — category `&"node"`, trigger_id `&"wood_wide_web"`
> *Title:* The Network You Did Not Build
>
> Sugar flows from the strong tree to the dying one. Nutrients flow up to where they are needed most.
> The fungi are the postal service. No one ever paid them in anything but sugar.

**`disc_node_soil_memory.tres`** — category `&"node"`, trigger_id `&"soil_memory"`
> *Title:* What the Ground Remembers
>
> A forest cleared and replanted is not the same as a forest grown from nothing.
> The soil keeps a ledger. You learn to read it.

**`disc_node_insectivory.tres`** — category `&"node"`, trigger_id `&"insectivory"`
> *Title:* The Plants That Eat
>
> Where the soil is poor, some plants learned to wait, sticky and patient, for what would land on them.
> You become a kind of plant the herbivores did not predict.

**`disc_node_cordyceps_mastery.tres`** — category `&"node"`, trigger_id `&"cordyceps_mastery"`
> *Title:* The Fungus That Steers
>
> Some fungi do not wait for the dead. They make the living convenient.
> An ant climbs higher than it should. It opens. The fungus blooms.

**`disc_node_spore_distribution.tres`** — category `&"node"`, trigger_id `&"spore_distribution"`
> *Title:* The Long Throw
>
> A puffball releases a cloud of spores wide enough to seed a meadow.
> Most will fall in places that cannot have them. Most is enough.

**`disc_node_drought_resilience.tres`** — category `&"node"`, trigger_id `&"drought_resilience"`
> *Title:* The Lesson the Dry Years Taught
>
> Thicker cuticles. Deeper roots. Stomata that close before the sun gets cruel.
> The drought did not break you. It only edited what you carry forward.

**`disc_node_lichen_heritage.tres`** — category `&"node"`, trigger_id `&"lichen_heritage"`
> *Title:* The Body That Is Two Bodies
>
> A fungus that grows around an alga, sheltering it. An alga that feeds the fungus in return.
> Together they live on stone, where neither could have survived alone. You are about to be both.

### Milestone entries

**`disc_milestone_prestige_5.tres`** — category `&"milestone"`, trigger_id `&"prestige_5"`
> *Title:* Five Lives Lived
>
> Five times now you have grown, persisted, and returned to substrate.
> The world keeps no statue of you. But it remembers, in soil chemistry, that you passed through.

**`disc_milestone_prestige_25.tres`** — category `&"milestone"`, trigger_id `&"prestige_25"`
> *Title:* Twenty-Five Cycles
>
> You begin to suspect that "you" is the wrong word.
> A pattern that repeats is not an individual. It is a *kind*.

**`disc_milestone_prestige_50.tres`** — category `&"milestone"`, trigger_id `&"prestige_50"`
> *Title:* Fifty Beginnings
>
> Half a hundred starts. The biosphere does not count its restarts either.
> Mass extinctions, ice ages, the asteroid: each was a prestige the world did not name.

**`disc_milestone_first_cross_kingdom_node.tres`** — category `&"milestone"`, trigger_id `&"first_cross_kingdom_node"`
> *Title:* Across the Border
>
> The first time you applied what one kingdom taught you to a problem in another.
> This is how new kingdoms are born — not from purity, but from the bridge between.

## `.tres` template

Each file follows this format:

```
[gd_resource type="Resource" script_class="DiscoveryEntry" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_entry.gd" id="1"]

[resource]
script = ExtResource("1")
id = &"disc_kingdom_plantae"
title = "The First Deal"
body = "You unfurl. The light meets the chlorophyll meets the carbon and the carbon stays.
This is the first deal you made with the world."
category = &"kingdom"
trigger_id = &"plantae"
```

Embedded newlines in `body` are preserved by Godot's resource serializer when the string is double-quoted. Test by loading one in the editor before mass-producing.

## `_index.tres` rebuild

Append all 28 ext_resource lines to `data/discovery/_index.tres` and list them in the `entries` array. Order doesn't matter for runtime; group by category for human scanability.

## Acceptance criteria
- [ ] 28 `.tres` files exist with valid schema.
- [ ] `_index.tres` references all 28.
- [ ] `DiscoveryLog.get_total_count() == 28` at boot.
- [ ] Body text matches the table verbatim (no autocorrect, no smart-quote substitution — straight quotes throughout).
- [ ] Each entry's category + trigger_id matches the corresponding fire site in brief 06.
- [ ] Manual: cold load → buy `unlock_fungi` → "Beneath the Green" + "The Decomposers Were Already Here" both unlock.
- [ ] Manual: start parasite plantae run → "Roots Without Light" unlocks once. Restart same niche → no second fire (persistent `niches_played` dedup).

## Out of scope
- UI rendering (brief 08).
- Toast notifications on unlock (brief 08 wires those).
- Entries for nodes not in the list above (e.g. `mutualism`, `unlock_parasitic_plantae`, `unlock_mycorrhizal_fungi`, `unlock_animals`, `endophytic_bridge`, `symbiotic_generosity`, `saprophytic_efficiency_ii`, `photosynthetic_network`) — deferred. The 28 above are the most narratively load-bearing. The rest can land in Phase 11 or whenever a voice rewrite pass happens.
- Era-transition entries (Phase 11).
- Species-first-played entries (Phase 10+).
