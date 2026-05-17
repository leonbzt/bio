# Brief 00 — Phase 11 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 9 smoke test passed (tree visualization + discovery log functioning).
- [ ] Phase 10 complete: layered-lifeform foundation, Lichen, animal foundation, niche signature mechanics, stub resources.
- [ ] Save at `save_version: 8` (Phase 10 bumps v7 → v8 to retire symbiosis kingdom).

## What Phase 11 is

Phase 11 implements the **world feedback layer** — Tier 2's first deliverable. See `docs/ROADMAP.md` Phase 11 and `docs/GAME_VISION.md` for the framing. Three mutually reinforcing pieces, plus a small fourth:

1. **Active-event interventions** — most events default to passive impact. Evolution nodes unlock tap-targeted abilities that mitigate or exploit specific events. Toxin Bloom (Phase 3) is the prototype pattern; this phase generalizes it.
2. **Tile history** — `TerritorySystem` persists per-tile metadata across prestige. Tiles render with a faint pre-existing tint showing which kingdoms have lived there. Substantiates the "world remembers" pillar mechanically and visually.
3. **Soft prestige goal** — per-run goal banner ("Reach 30 tiles", "Survive 2 events", "Steal 200 biomass"). Banner highlights when met; doesn't force prestige but congratulates the player and lights up the prestige button. Goals are drawn from a niche-aware pool.
4. **Generations counter** — title-screen shows total prestige count with an evolving descriptor that changes by threshold ("Pioneers" → "Settled Colonies" → "Networked Life" → "The Anthropocene Watches"). Cheap to ship; sells the long-arc identity.

These ship together because:
- Tile history + tile-local soil_memory refactor share the same data layer.
- The soft-goal pool naturally extends per-niche signature goals (a parasite plantae goal asking for "200 biomass stolen" makes the Phase 10 signature mechanic feel earned).
- The generations counter is a small UI piece that punctuates the prestige loop the soft-goal system funnels players into.

## Decisions locked for Phase 11

These resolve open design questions raised during the Phase 9 mechanics-vs-vision review and confirmed 2026-05-16:

1. **Active interventions extend `AbilitySystem`, not a new system.** `AbilitySystem` gets refactored to read `AbilityData` resources; Toxin Bloom becomes the first one. New abilities (Irrigate, Bundle, Cull) follow the same pattern.
2. **Ability availability is gated by two predicates AND-ed**: `MetaModifiers.is_unlocked(unlock_node_id)` AND (`requires_event_active` is empty OR that event is currently active). Toxin Bloom has empty `requires_event_active` (always usable in plantae runs); Irrigate requires `&"drought"`.
3. **Tile history persists in `meta.tile_history`, not `run.tiles`** — it survives prestige. Keyed by `"x,y"` string; value is `Array[String]` of kingdom ids that have *ever* occupied either layer at this coord. Append-only, deduplicated.
4. **Tile history rendering**: faint overlay (alpha ~0.15) using the wing color of the most-recent historical kingdom, drawn under the active-tile overlay. No animation — just static.
5. **soil_memory refactored to tile-local**: instead of a global 15% yield when `fungi` ever played, the bonus applies *per tile* when that tile's history includes `fungi`. Fixes the Phase 9 balance leak called out in the review.
6. **One goal per run** at v1. Goal is picked at `start_run`; immutable for the run. Multi-goal lists deferred.
7. **Goal pool is niche-tied at v1**: each niche has a small pool of candidate goals (3–5). A goal is rolled at run start; the niche dictates which pool to roll from.
8. **Generations descriptor thresholds**: Pioneers (1–5), Settled Colonies (6–20), Networked Life (21–100), The Anthropocene Watches (101+). Show count + descriptor on title screen.

## Contracts landing in Phase 11

- **Save schema v8 → v9**: adds `meta.tile_history: Dictionary`, `run.goal_id: String`, `run.goal_progress: Dictionary` (free-form per goal type), `run.goal_met: bool`.
- **`AbilityData` resource** (`scripts/data/ability_data.gd`) — id, display_name, description, cost, unlock_node_id, requires_event_active, target_mode, radius, damage (free-form payload).
- **`AbilityIndex` + `data/abilities/_index.tres`** — content-index pattern. Includes Toxin Bloom (the refactored existing ability) plus the 3 new ones.
- **`AbilitySystem` generalization**: `get_usable_abilities() -> Array[StringName]`, `request_ability(id) -> bool`. Existing `request_toxin_bloom()` becomes a thin shim or is removed.
- **3 new evolution-tree nodes**: `deep_roots`, `cold_tolerance`, `quarantine`. Each has `unlock_node_id` matching an ability id.
- **`PerRunGoalData` resource** + `RunGoalSystem` autoload. New `EventBus.goal_progress_changed(progress: Dictionary)` and `EventBus.goal_met()` signals.
- **`TerritorySystem` extensions**: `_record_history(coord, kingdom_id)` called from `add_surface`/`add_subsurface`. New public reads `get_tile_history(coord) -> Array[StringName]`, `tile_has_history(coord, kingdom_id) -> bool`.
- **Title-screen scene change**: descriptor logic + count display.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v8 → v9 migration | ChatGPT 5.2 / Copilot | **Claude** (save format) |
| 02 | Tile history persistence (TerritorySystem + GameState helper) | ChatGPT 5.2 / Copilot | Claude |
| 03 | Tile history rendering + soil_memory tile-local refactor | ChatGPT 5.2 / Copilot | Claude (balance) |
| 04 | AbilityData resource + AbilitySystem generalization | ChatGPT 5.2 / Copilot | Claude (contract refactor) |
| 05 | 3 event-tied abilities + 3 evolution nodes + HUD ability bar | Kilo (data) + ChatGPT (logic) | Claude |
| 06 | PerRunGoalData + RunGoalSystem + goal pool authoring | Kilo (data) + ChatGPT (logic) | Claude |
| 07 | Soft-goal banner UI | ChatGPT 5.2 / Copilot | Claude (mobile layout) |
| 08 | Generations counter on title screen | ChatGPT 5.2 / Copilot | — |
| 09 | Phase 11 manual smoke test | you on device | — |

## Out of scope

- Per-niche signature mechanics (Phase 10 — parasite biomass-steal, mycorrhizal substrate-claim).
- Layered lifeforms (Phase 10).
- Animal kingdom (Phase 10).
- Era system (Phase 12).
- Per-ecosystem completion gating (Phase 12).
- Axis-scoped events (`EventData.scope`) (Phase 13).
- Era-transition narrative passages (Phase 12).
- Multi-goal runs.
- Per-tile history tooltip ("This tile was once fungi, then plantae") — nice to have, defer.
- Goal authoring beyond ~12 generic + niche-tied goals; expand in Phase 13+ with era-specific goals.
