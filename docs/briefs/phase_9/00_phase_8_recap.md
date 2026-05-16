# Brief 00 — Phase 9 entry checklist

**Suggested agent**: do this yourself.

## Pre-flight
- [x] Phase 8 complete: niche system, ColonizationRulesRegistry, parasite plantae + mycorrhizal fungi, niche-select UI, niche badge HUD. Smoke test passed 2026-05-16.
- [x] Save at `save_version: 5`.
- [x] Symbiosis regression fix (empty `niche_id` allowed for symbiosis kingdom) in place.
- [ ] No regressions in plantae/fungi/symbiosis runs.

## What Phase 9 is

Phase 9 implements the **interconnected progression web** — the second deliverable in Tier 1 of the post-MVP roadmap. See `docs/PROGRESSION_WEB.md` for the full design, and `docs/STORY_AND_TONE.md` for the discovery-log voice.

The current evolution tree is a flat per-kingdom unlock graph (10 nodes). Phase 9 turns it into a **directed graph across kingdoms** with wing/tier metadata, ~10–12 new cross-kingdom nodes, and a tree-visualization UI that *shows* the web. It also scaffolds the **discovery log** — the player-facing journal of mythic-scientific entries that makes the world feel like it has a voice.

These two pieces ship together because:
- The new tree UI needs a visualization model that the discovery log can mirror (both are browsable, both have locked/unlocked states).
- Discovery entries are triggered by evolution-node purchases and kingdom/niche unlocks — the same data Phase 9 is restructuring.
- Players need a *reason* to chase cross-kingdom nodes; the discovery log is the carrot.

## Decisions locked for Phase 9

These are from the open questions in `PROGRESSION_WEB.md` and `STORY_AND_TONE.md`, resolved during planning on 2026-05-16:

1. **Tree UI layout**: **Single scrollable canvas** with all four wings as horizontal columns and tiers stacking vertically. Prereq lines drawn through `Control._draw()`. No tabs, no separate "Crossings" view. Mobile-busy is the point.
2. **`requires_kingdom_played` enforcement**: **Hard gate**. `PrestigeSystem.purchase_node` refuses the purchase if the player hasn't completed (prestiged out of) a run in the required kingdom(s). The node still *displays* greyed-out with a tooltip explaining the gate.
3. **Discovery-log entry sources**: **All four** — kingdom unlocks, niche unlocks (first-play of a niche), evolution-node purchases, and event first-fires + milestones. Era transitions and species-first-played are out of scope until Phase 11 (era system) and Phase 10 (lichen species) respectively.
4. **Discovery-log authoring**: **Claude writes the voice text directly in brief 07.** Not a Kilo task, not a player-facing input. The text lands in `data/discovery/*.tres` as authored content.
5. **Locked-entry visibility**: **Hidden from the list, counted in denominator only.** Player sees "Discoveries: 12 / 27" but the 15 locked entries don't appear as rows. No silhouette teasing, no redacted body. This avoids spoilers and keeps the list clean.
6. **Refunds / respec**: **No.** Once a node is bought, it's permanent. (Deferred decision from `PROGRESSION_WEB.md` open questions.)

## Cross-kingdom nodes landing in this phase

Per the 30% cross-wing target in `PROGRESSION_WEB.md`, with ~10 existing nodes + ~12 new nodes = 22 nodes total, ~7 should be cross-wing prereqs. Brief 04 specifies the full list. Sneak preview:

| Wing | New nodes | Cross-wing? |
|---|---|---|
| Plantae | Insectivory, Soil Memory, Drought Resilience | Soil Memory (requires fungi played) |
| Fungi | Saprophytic Efficiency II, Cordyceps Mastery, Spore Distribution | Cordyceps (requires plantae played) |
| Hybrid | Lichen Heritage, Symbiotic Generosity, Photosynthetic Network, Endophytic Bridge | All hybrid nodes cross-wing by definition |
| Animals | — | Phase 10 unlocks the kingdom |

## Contracts landing in Phase 9

- **Save schema v5 → v6**: adds `meta.discovery_log: Dictionary` (entry_id → bool), `meta.kingdoms_played: Array[String]` (tracks `requires_kingdom_played` enforcement), `run.event_first_fires_seen: Array[String]` (per-run dedup so the same event doesn't double-fire a discovery entry on a single run).
- **`EvolutionNodeData` schema extension**: adds `wing: StringName`, `tier: int`, `requires_kingdom_played: Array[StringName]`.
- **New autoload `DiscoveryLog`**: registered after `PrestigeSystem`. Owns the entry index, the unlocked dict, the trigger wiring.
- **New resource `DiscoveryEntry`**: id, title, body, category, trigger_id.
- **New signal `EventBus.discovery_unlocked(entry_id: StringName)`**: fired by DiscoveryLog when a new entry is awarded. UI listens.
- **`PrestigeSystem.purchase_node`** gains a `requires_kingdom_played` check before the EP balance check.
- **`PrestigeSystem.trigger_prestige`** appends the just-finished kingdom to `meta.kingdoms_played` (idempotent).

## Brief routing

| # | Brief | Suggested agent | Diff review |
|---|---|---|---|
| 00 | This file | — | — |
| 01 | Save v5 → v6 migration | ChatGPT 5.2 / Copilot | **Claude** (save format) |
| 02 | EvolutionNodeData extension + DiscoveryEntry resource + DiscoveryLog autoload stub | ChatGPT 5.2 / Copilot | **Claude** (contracts) |
| 03 | Tag existing 10 nodes + `requires_kingdom_played` enforcement | Kilo (data) + ChatGPT (logic) | Claude |
| 04 | Author 12 new cross-kingdom nodes | Kilo (data files, names/numbers) | Claude (cross-wing balance) |
| 05 | Tree visualization UI rebuild | ChatGPT 5.2 / Copilot | Claude (mobile layout) |
| 06 | DiscoveryLog autoload + trigger wiring | ChatGPT 5.2 / Copilot | Claude (signal contract) |
| 07 | Author 25+ discovery entries | **Claude writes content directly** | — |
| 08 | Discovery log UI (pause menu entry, list, header) | ChatGPT 5.2 / Copilot | Claude |
| 09 | Phase 9 manual smoke test | you on device | — |

## Out of scope
- Animal kingdom (Phase 10).
- Symbiotic species via Lichen (Phase 10).
- Era / ecosystem system + era-transition discovery entries (Phase 11).
- Species-first-played discovery trigger (needs lichen / multi-species — Phase 10+).
- Discovery-log entry images or audio (text-only at launch, per `STORY_AND_TONE.md`).
- Multilingual flavor (English-only at launch).
- Tree-node respec / refund.
