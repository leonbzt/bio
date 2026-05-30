# Phase 17 — Solidify & Polish

**Goal:** Make the prototype feel finished. No new mechanics — only strip dead weight, harden the loop, and fix rough edges that would confuse a second playtester.

**Prerequisite:** Phase 16 smoke test passes (run_complete + cycle_closed fixes committed).

---

## Current state (post Phase 16)

- 72 scripts, ~17.5k lines. Core loop works: place 3 species → cycle closes → biomass climbs → prestige.
- 5 dead systems removed. Offline progress batched. cycle_closed + run_complete fixed.
- Still present: ~6 orphan UI scripts, 16 MetaModifiers checks for unearnable unlocks, dead signal wiring, dead data directories, untested prestige round-trip.

---

## Briefs

### Brief 1 — Dead code strip (second pass)

Delete orphan scripts, dead signals, dead data. Pure deletions.

| Target | Why |
|---|---|
| `scripts/ui/goal_banner.gd` | Not instanced anywhere (scene never existed) |
| `scripts/ui/multiplier_chips.gd` | Orphan, no scene, no callers |
| `scripts/ui/biome_legend.gd` | Orphan, no scene, no callers |
| `scripts/ui/resource_label.gd` | Orphan, no scene, no callers |
| `scripts/ui/tooltip_button.gd` | Orphan, no scene, no callers |
| `scripts/ui/adaptation_chip.gd` + `scenes/ui/adaptation_chip.tscn` | Scene exists but never instanced |
| `data/abilities/` (entire dir) | AbilitySystem deleted; no callers |
| Dead signal connections: `ability_used` listeners in AmbientModifierSystem + GrowthSystem | Connected but never emitted |
| Dead signal connections: `organism_died` listener in EraSystem | Connected but never emitted |
| Dead EventBus signals: `organism_spawned`, `organism_died`, `trait_unlocked`, `input_mode_changed` | Never emitted or connected |

Also: remove `_on_ability_used` handler from GrowthSystem (handles "bundle" warming — ability system is gone).

### Brief 2 — Growth system cleanup

Strip the MetaModifiers bonus tower from the per-tick hot loop.

**What to cut:** 8 `MetaModifiers.is_unlocked()` checks in `growth_system.gd` for unlocks that cannot be earned in the prototype:
- `endophytic_bridge`, `chemosynthetic_pathway`, `vascular_network`, `soil_memory`, `extinction_survivor`, `wood_wide_web`, `efficient_photosynthesis`, `mutualism`

Also strip 5 checks in `colonization_rules_registry.gd`:
- `thrifty_growth` (4 checks), `spore_distribution` (1 check)

And 2 checks in `ambient_modifier_system.gd`:
- `drought_resilience`, `cryotolerance`

And 1 check in `prestige_system.gd`:
- `spore_distribution` (spore charges on run start)

**Result:** ~50 lines of dead conditionals removed from the hot loop. Growth system becomes a clean, readable production pipeline.

**Note:** Keep `MetaModifiers` class and the evolution_tree data structure intact — they'll be needed when between-run progression lands. Just remove the specific checks that have no effect today.

### Brief 3 — Prestige round-trip hardening

Test and fix the end-to-end prestige flow:

1. `goal_met` fires → prestige screen auto-opens (just implemented)
2. Player clicks "Begin next run" → `trigger_prestige()` called → evolution points awarded
3. `auto_start_run = true` → main menu → fresh run starts
4. Second run initializes cleanly (pools reset, species cleared, checkpoints reset)
5. Biomass counter starts at 0 on the fresh run

**Known risks:**
- `trigger_prestige()` calls `TickClock.resume()` inside prestige_screen — but we paused in `_on_goal_met`. Verify resume happens before scene change.
- `auto_start_run` flag in GameState — verify main_menu reads it and starts a run without user input.
- Species panel on second run — does it show the correct available species?
- Save system — does the prestige write persist both `meta_save` (evolution earned) and a fresh `run_save`?

### Brief 4 — Small UX polish

Low-effort fixes that improve the prototype feel:

1. **World map button in pause menu** — either make it functional or remove it (currently loads an empty/broken scene that interrupts the prototype experience).
2. **AdaptationSystem ticking silently** — accruing a currency the player can't see or spend. Either surface it minimally or silence the tick until v2.
3. **Species panel tooltip cleanup** — tooltips reference levels ("Lvl 1/3 +0% yield") but the evolve UI was just removed.
4. **Pool readout clarity** — the N/B/D row tooltip is dense. Consider shorter copy.
5. **Prestige screen: evolution tree canvas** — verify it renders something useful (completed runs list) or hide the section.

---

## Out of scope

- New species / 4th species (predator)
- Spatial resource flows
- Between-run evolution spending
- New biomes or eras
- Visual overhaul or new art

---

## Execution order

1 → 2 → 3 → 4 (sequential — each builds on the previous cleanup)

## Exit criteria

- All dead code deleted, no orphan scripts remain
- Growth system has no unreachable conditionals
- Prestige → second run works end-to-end without errors
- Smoke test passes on a fresh save
