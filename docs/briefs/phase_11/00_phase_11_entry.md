# Brief 00 — Phase 11 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [ ] Phase 9 smoke test passed (tree visualization + discovery log functioning).
- [ ] Phase 10 complete: Lichen niche under Fungi (hybrid niche+species model), animal foundation, niche signature mechanics, stub resources.
- [ ] Save at `save_version: 8` (Phase 10 bumps v7 → v8 to retire symbiosis kingdom).

## What Phase 11 is

Phase 11 implements the **world feedback layer** — Tier 2's first deliverable. See `docs/ROADMAP.md` Phase 11 and `docs/GAME_VISION.md` for the framing. Three mutually reinforcing pieces:

1. **Active-event interventions** — most events default to passive impact. Evolution nodes unlock tap-targeted abilities that mitigate or exploit specific events. Toxin Bloom (Phase 3) is the prototype pattern; this phase generalizes it.
2. **Soft prestige goal** — per-run goal banner ("Reach 30 tiles", "Survive 2 events", "Spread 20 parasite tiles"). Banner highlights when met; doesn't force prestige but congratulates the player and lights up the prestige button. Goals are drawn from a niche-aware pool.
3. **Generations counter** — title-screen shows total prestige count with an evolving descriptor that changes by threshold ("Pioneers" → "Settled Colonies" → "Networked Life" → "The Anthropocene Watches"). Cheap to ship; sells the long-arc identity.

### What was dropped from Phase 11 (decided 2026-05-17)

**Tile history persistence + rendering** was originally a fourth piece of Phase 11. Dropped because:
- Per-tile colored tints would be visually noisy on a 32×48 portrait grid.
- Without a long-press tooltip (deferred), players wouldn't understand why tiles render differently.
- The `soil_memory` tile-local refactor that depended on it isn't critical — the global 15% bonus from Phase 9 is an acceptable balance leak in the interim.
- A different "world remembers" mechanic will land in Phase 12 alongside the ecosystem/era system where it has a more natural home.

`soil_memory` stays as the Phase 9 global multiplier. No `meta.tile_history` save field.

## Decisions locked for Phase 11

1. **Active interventions extend `AbilitySystem`, not a new system.** `AbilitySystem` gets refactored to read `AbilityData` resources; Toxin Bloom becomes the first one. New abilities (Irrigate, Bundle, Cull) follow the same pattern.
2. **Ability availability is gated by two predicates AND-ed**: `MetaModifiers.is_unlocked(unlock_node_id)` AND (`requires_event_active` is empty OR that event is currently active). Toxin Bloom has empty `requires_event_active` (always usable in plantae runs); Irrigate requires `&"drought"`.
3. **One goal per run** at v1. Goal is picked at `start_run`; immutable for the run. Multi-goal lists deferred.
4. **Goal pool is niche-tied at v1**: each niche has a small pool of candidate goals (3–5). A goal is rolled at run start; the niche dictates which pool to roll from.
5. **Generations descriptor thresholds**: Pioneers (1–5), Settled Colonies (6–20), Networked Life (21–100), The Anthropocene Watches (101+). Show count + descriptor on title screen.

## Contracts landing in Phase 11

- **Save schema v8 → v9**: adds `run.goal_id: String`, `run.goal_progress: Dictionary` (free-form per goal type), `run.goal_met: bool`.
- **`AbilityData` resource** (`scripts/data/ability_data.gd`) — id, display_name, description, cost, unlock_node_id, requires_event_active, target_mode, radius, magnitude, extra_payload.
- **`AbilityIndex` + `data/abilities/_index.tres`** — content-index pattern. Includes Toxin Bloom (refactored existing ability) plus 3 new ones.
- **`AbilitySystem` generalization**: `get_usable_abilities() -> Array[AbilityData]`, `request_ability(id) -> bool`. Existing `request_toxin_bloom()` becomes a thin shim.
- **3 new evolution-tree nodes**: `deep_roots`, `cold_tolerance`, `quarantine`.
- **`PerRunGoalData` resource** + `RunGoalSystem` autoload + new signals `EventBus.goal_progress_changed(progress: Dictionary)` and `EventBus.goal_met()`.
- **Title-screen scene change**: descriptor logic + count display.

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v8 → v9 migration | ChatGPT 5.2 / Copilot | **Claude** (save format) |
| 02 | AbilityData resource + AbilitySystem generalization | ChatGPT 5.2 / Copilot | Claude (contract refactor) |
| 03 | 3 event-tied abilities + 3 evolution nodes + HUD ability bar | Kilo (data) + ChatGPT (logic) | Claude |
| 04 | PerRunGoalData + RunGoalSystem + goal pool authoring | Kilo (data) + ChatGPT (logic) | Claude |
| 05 | Soft-goal banner UI | ChatGPT 5.2 / Copilot | Claude (mobile layout) |
| 06 | Generations counter on title screen | ChatGPT 5.2 / Copilot | — |
| 07 | Phase 11 manual smoke test | you on device | — |

## Out of scope

- Tile history (dropped per above; revisit in Phase 12).
- Per-niche signature mechanics (Phase 10 — parasite biomass-steal, mycorrhizal substrate-claim).
- Layered lifeforms beyond Lichen (Phase 10 ships Lichen; 3+ layer packs in Phase 14+).
- Animal kingdom (Phase 10).
- Era system (Phase 12).
- Per-ecosystem completion gating (Phase 12).
- Axis-scoped events (`EventData.scope`) (Phase 13).
- Era-transition narrative passages (Phase 12).
- Multi-goal runs.
- Goal authoring beyond ~12 generic + niche-tied goals; expand in Phase 13+ with era-specific goals.
