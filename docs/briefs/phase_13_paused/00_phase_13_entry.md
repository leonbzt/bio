# Brief 00 — Phase 13 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 12 smoke test passed (era + ecosystem flow, mass extinction narrative, world map UI).
- [ ] Fungi-only Cryogenian start can actually earn EP (commit `5a23aca`).
- [ ] Save at `save_version: 11`.

## What Phase 13 is

The second deliverable of Tier 2. Phase 12 added the **time axis** as scaffolding (eras + ecosystems exist, narrative beats fire, but every ecosystem plays out on the same 3 biomes with the same global event pool). Phase 13 gives that scaffold **gameplay teeth and visual identity**:

1. **New biomes** matched to era flavor (tundra, mineral vent, swamp) — so a Cryogenian polar-ice run plays mechanically different from a Devonian swamp run.
2. **Per-ecosystem biome generation** — `EcosystemData.biome_preference` (already authored, ignored in Phase 12) now actually shapes the generated map.
3. **Axis-scoped events** — events declare what context they belong to (world / kingdom / niche / era / ecosystem). A fungi run no longer rolls `herbivore_wave`; a Cryogenian run can roll cold-snap events that don't exist in Devonian.
4. **Mass extinction with gameplay teeth** — Phase 12's narrative beat now leaves a real scar on the first run in the new era (reduced yields + recovery curve), redeemed by an EP bonus when the survivor run prestiges.
5. **Era-gated evolution nodes** — 5 new nodes whose availability depends on which era the player is in, putting era choice on the build path.
6. **Per-era visual identity** — tile + background tinting per era (cool blue Cryogenian, warm green Devonian) + placeholder textures for the 3 new biomes.

## Decisions locked

From 2026-05-17 conversation (continuing after Phase 12 ship + fungi biomass fix):

1. **New biomes are mechanically distinct, not just visually**. `BiomeData` gains `chemosynthesis_per_tick: float`. The mineral-vent biome has `sunlight_per_tick = 0.0` and instead feeds biomass via chemosynthesis (fungi convert it directly; plantae get a smaller chemosynthesis multiplier). Tundra is low-sunlight + slow-decay. Swamp is moderate-sunlight + high-decay. Three new files in `data/biomes/`, one schema field added.

2. **Per-ecosystem generation uses a 70/30 weighted mix**, not a hard replacement. If `ecosystem.biome_preference` is set, ~70% of tiles spawn that biome and 30% draw from the era's natural mix (= whichever biomes have any presence in that era). Deterministic from `run_seed`. If `biome_preference` is empty, current behavior preserved verbatim — no Phase 12 ecosystems break.

3. **Mass extinction teeth = post-extinction recovery debuff on the FIRST run in the new era, then an EP bonus**. On `era_transition_started`, `meta.post_extinction = {to_era_id: <new>, debuff_ticks_remaining: 120}` is stamped. The next run in `to_era_id` opens with `AmbientModifierSystem` applying `sunlight_multiplier *= 0.5` and a new `biomass_multiplier *= 0.5`, both linearly recovering to `1.0` over 120 ticks. When that run prestiges (any outcome — success, restart, abandon), the state clears and a one-shot +25 EP "Extinction Survivor" bonus is granted, surfacing as a discovery + HUD toast. Player feels the loss in-run, gets compensated meta-side, never gets re-debuffed.

4. **Axis-scoped events use a single `scope: StringName` + `scope_target: StringName` pair**, not a list. Recognized scopes: `&"world"` (always rolls), `&"kingdom"`, `&"niche"`, `&"era"`, `&"ecosystem"`. `EcologicalPressure._maybe_trigger` filters the candidate pool by scope-matches *before* the weighted roll — so a fungi run never even sees herbivore_wave in the lottery, not "rolls it and then skips". The legacy `payload.kingdom_required` field is removed in this phase (replaced by `scope = &"kingdom"`, `scope_target = &"plantae"`).

5. **Era-gated nodes use a new `requires_era: StringName` field on `EvolutionNodeData`**, default empty = always available. `PrestigeSystem` filters node availability by `requires_era == "" or current_era_id == requires_era`. UI in the tree shows era-gated nodes greyed out with a tooltip ("Requires Cryogenian era"). Player can purchase only while playing in the matching era; once purchased the node stays unlocked across all eras.

6. **Per-era visuals are tint-only, not full palette swaps**. `EraData.tint_color` (already exists, unused in Phase 12) is applied as `modulate` on `TileGrid` and a background `ColorRect` in `world.tscn`. The 3 new biome textures are flat-color atlas additions (pale gray-blue tundra, dark gray w/ orange flecks mineral, dull olive swamp). Music swaps + transition VFX explicitly deferred to Phase 14.

7. **Backfill discipline**: existing events get `scope = &"world"` by default unless they have a clear narrower home (herbivore_wave → kingdom, spore_infection → kingdom). No event silently changes behavior — every backfill is a deliberate decision in brief 05.

8. **No save data loss across the upgrade**. The v11 → v12 migration adds `meta.post_extinction = {}`, defaults `meta.first_run_in_era_completed: Array[String] = []` (tracks which eras have had their survivor run), and re-stamps each existing event's `scope = "world"` if absent.

## Contracts landing in Phase 13

- **Save schema v11 → v12**: `meta.post_extinction: Dictionary` (active recovery state), `meta.first_run_in_era_completed: Array[String]` (eras that have had their survivor run + EP bonus claimed), `meta.first_era_seen: String` (records initial era for the EP-bonus guard).
- **`BiomeData` gains** `chemosynthesis_per_tick: float`.
- **`EventData` gains** `scope: StringName`, `scope_target: StringName`; loses dependency on `payload.kingdom_required` (legacy field stays in source data but is no longer read).
- **`EvolutionNodeData` gains** `requires_era: StringName`.
- **`AmbientModifierSystem` gains** the `&"biomass_multiplier"` channel (additive to existing `sunlight_multiplier`).
- **`EraSystem` gains** the `_apply_post_extinction_debuff()` lifecycle hook + `_award_extinction_survivor_bonus()` on prestige.
- **`NutrientSystem` gains** an `_apply_ecosystem_biome_preference(run_seed)` method called at run start.
- **No new EventBus signals.** The existing `era_transition_started`, `event_started`, `event_resolved`, `prestige_triggered` cover everything.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v11 → v12 migration | ChatGPT 5.2 | **Claude** (save format) |
| 02 | BiomeData schema extension + 3 new biome files | ChatGPT 5.2 (schema) + Kilo (data) | Claude (balance) |
| 03 | Per-ecosystem biome generation in NutrientSystem | ChatGPT 5.2 | Claude (determinism check) |
| 04 | EventData.scope + scope_target + EcologicalPressure filtering | ChatGPT 5.2 | **Claude** (filter logic) |
| 05 | Event content pass (backfill + new scoped events) | Kilo (data) + Claude (3-4 new events) | Claude |
| 06 | Mass extinction gameplay teeth (post-extinction recovery) | ChatGPT 5.2 | **Claude** (lifecycle) |
| 07 | Era-gated evolution nodes (schema + 5 new nodes) | ChatGPT 5.2 (schema) + Kilo (data) | Claude (balance + gating) |
| 08 | Per-era visual identity (tile + background tint, biome textures) | ChatGPT 5.2 | Claude (mobile readability) |
| 09 | Discovery entries for Phase 13 content (~10 new) | **Claude writes voice text directly** | — |
| 10 | Phase 13 manual smoke test | you on device | — |

## Out of scope (Phase 14+)

- Per-era music tracks + crossfade (audio asset blocker).
- Era-transition VFX (particle / shader pass).
- Proper biome sprite art (Phase 13 ships flat placeholder textures).
- Per-niche scoped events (briefs 04 + 05 add the *capability*; only kingdom-scoped events ship in Phase 13 — niche/era/ecosystem scopes are wired but unused).
- "Replay an old era for a different completion path" (era completion stays one-shot).
- Multi-run extinction cascades (one debuff window per transition, locked).
- Mass extinction "save one species via meta currency" rescue mechanic — parked.
- Predator + Scavenger animal niches (Phase 14).
- 3-layer species packs (Phase 14: Coral, Termite Mound).
- Tile-level structures (parked in `docs/STRUCTURES.md`, revisit Phase 13–14 alongside layered species packs).

## Order of work

The dependency chain matters here — get briefs in this order:

1. **01** (save migration) — everything else assumes v12 fields exist.
2. **02** (biome schema + data) — brief 03 needs the new biomes to exist.
3. **04** (event scope schema) — brief 05 (event content) needs the schema; brief 06 (mass extinction) also uses scope.
4. **03, 05, 06, 07** are mostly independent after 02 + 04 land — can interleave.
5. **08** (visuals) is mostly independent but easier once 02 lands.
6. **09** (discovery) goes last — needs to point at real content.
7. **10** (smoke test) gates the phase exit.

## Exit criteria

- A Cryogenian polar-ice run looks visually distinct from a Devonian swamp run (tint + dominant biome).
- Fungi runs never see `herbivore_wave` in the event lottery.
- A first run after the Cryogenian → Devonian transition opens with reduced yields and recovers over ~2 minutes; the run completes; the next prestige fires "Extinction Survivor +25 EP".
- At least 2 new evolution nodes are visibly era-gated in the tree.
- All 10 new discovery entries are reachable and authored in mythic-scientific voice.
- Save file from Phase 12 (v11) opens cleanly in Phase 13 (v12), no data loss.
