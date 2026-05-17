# Brief 00 — Phase 12 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 10 smoke test passed (Lichen + animals + niche signatures).
- [ ] Phase 11 smoke test passed (active interventions + soft goals + generations counter).
- [ ] Save at `save_version: 10`.

## What Phase 12 is

The first deliverable of Tier 2's "world feedback" arc. Adds the **time axis** to the game: runs no longer happen in a flat now — they happen in a specific **era** (geological epoch) within a specific **ecosystem** (biome region). Each ecosystem has its own completion criterion; completing all ecosystems in an era unlocks the next.

Six bundled deliverables:

1. **EraData + EcosystemData resources** + content authoring (2 eras × 3 ecosystems = 6 ecosystems).
2. **World map UI** replacing the current "Begin run as..." flow. Player picks an ecosystem first; the kingdom/niche cascade follows, pre-filtered by what's available in the era.
3. **EraSystem autoload** + per-ecosystem completion tracking.
4. **Era transition narrative passages** — when the player completes all ecosystems in an era, a 4–8 sentence mythic-scientific passage plays before the next era opens.
5. **Era-locked content** — Cryogenian era has fungi only (no plantae yet). Establishes the pattern.
6. **Mass extinction event** as an era-transition narrative beat. Phase 12 ships the text + flow; gameplay-level effects (destroying tiles, etc.) defer to Phase 13.

Plus the usual: discovery entries for new content + smoke test.

## Decisions locked

From 2026-05-18 conversation:

1. **Per-ecosystem authored completion criterion** (not generic threshold). Each `EcosystemData` has its own criterion id + target + (optional) required niche. Variety per ecosystem; reuses the same tracker shape as `PerRunGoalData` from Phase 11.
2. **World map replaces "Begin run as..."**. Player picks ecosystem first; then the existing kingdom/niche cascade, pre-filtered by `era.available_kingdoms`. No second selector path.
3. **Era visuals are text + color tint only** in Phase 12. World-map background tints per era; era label visible in HUD. No gameplay-tile palette shift, no new sprites. Tile palette work is Phase 13's graphics pass.
4. **Ecosystem completion criterion reuses Phase 11's `tracker` taxonomy**: `tiles_colonized`, `biomass_earned`, `events_survived`, `herbivores_defeated`, `node_purchased`. Adds optional `required_niche` to layer the playstyle gate ("must complete via Lichen run").
5. **Era unlock**: all ecosystems in current era must be complete to unlock the next era. Order within an era is the player's choice.
6. **Mass extinction event** in Phase 12 = narrative passage on era transition only. Tile-destroying / cascading-extinction effects are Phase 13.

## Contracts landing in Phase 12

- **Save schema v10 → v11**: `meta.current_era_id: String`, `meta.current_ecosystem_id: String`, `meta.ecosystem_completions: Dictionary` (ecosystem_id → bool), `meta.eras_unlocked: Array[String]`.
- **`EraData` resource** + **`EcosystemData` resource** + content-index pattern.
- **`EraSystem` autoload** — registered after `RunGoalSystem`.
- **New `EventBus` signals**: `era_transition_started(from_era: StringName, to_era: StringName)`, `ecosystem_completed(ecosystem_id: StringName)`, `era_changed(era_id: StringName)`.
- **PrestigeSystem.start_run** filters kingdom availability against `EraSystem.get_current_era().available_kingdoms`.
- **PerRunGoalData.tracker** taxonomy is shared with EcosystemData.completion_criterion.
- **World map scene** `scenes/ui/world_map.tscn` + `scripts/ui/world_map.gd`.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v10 → v11 migration | ChatGPT 5.2 | **Claude** (save format) |
| 02 | EraData + EcosystemData resources + indexes | ChatGPT 5.2 | Claude (contracts) |
| 03 | Author 2 eras × 3 ecosystems (6 ecosystems) + content | Kilo (data) | Claude (balance) |
| 04 | EraSystem autoload + completion tracking | ChatGPT 5.2 | Claude (signals) |
| 05 | World map UI + flow integration with prestige_screen | ChatGPT 5.2 | Claude (mobile layout) |
| 06 | Era transition narrative passage UI | ChatGPT 5.2 | Claude |
| 07 | Era-locked kingdom availability (Cryogenian fungi-only) | ChatGPT 5.2 | Claude |
| 08 | Mass extinction event content + trigger on era transition | Kilo (data) + ChatGPT (trigger) | Claude |
| 09 | Discovery log entries for eras + ecosystems + mass extinction (~10 new) | **Claude writes voice text directly** | — |
| 10 | Phase 12 manual smoke test | you on device | — |

## Out of scope

- Phase 13's full ecosystem-specific biomes (new biome types, tundra/swamp data files).
- Phase 13's per-era graphics pass (sprite palettes, music variation).
- Per-era evolution-tree node gating (some nodes only purchasable in certain eras).
- 3-layer species packs (Coral, Termite Mound — Phase 14).
- Era-locked events beyond mass extinction (Phase 13).
- Player-replay of previously-completed ecosystems for grinding (allow always, but completion is one-time).
- Era reset / "playing through an old era again" — out of scope; completed stays completed.
- Multiple worlds / parallel petri dishes (Tier 3).
