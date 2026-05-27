# Bio v1 Prototype — Migration Plan

> **The existing build already contains Coal Swamp Carboniferous gameplay. Migration is refocus, not rewrite — strip multi-resource clutter, replace goal-bar with biomass-throughput counter, simplify the systems, and lean on what's already there.**

Translates [V1_PROTOTYPE.md](V1_PROTOTYPE.md) into a concrete engineering plan: what to keep, rework, cut, and the order of operations.

Locked 2026-05-27.

---

## 1. What the existing build actually contains

A code survey turned up that the prototype's flow is mostly already implemented in a different framing:

- **Onboarding overlay** teaches Coal Swamp: place Calamites → introduce Mycorrhizal Network → place adjacent → introduce Arthropleura → fill Coal Gauge to 1000.
- **`RunGoalSystem`** auto-pins `fill_coal_gauge` when the ecosystem is Coal Swamp.
- **`GoalBanner`** is restyled as a literal "Coal Gauge" — coal-vein bar fill, ember-orange when met.
- **`ResourceLedger`** already has `BIOMASS / NUTRIENTS / DECAY` (which map exactly to the prototype's B / N / D).
- **`GrowthSystem`** already does per-tile `tick_yield → ResourceLedger.add` — which is the prototype's recipe model.

**Implication.** The big lifts are: cut visible resources to one (Hero Biomass), strip dead systems left over from the 2026-05-22 design, add cycle-closure detection + placement-cost mechanic, and rewrite the HUD. The simulation core is reusable.

---

## 2. Subsystem keep / rework / cut

### Core simulation

| File | Status | Notes |
|---|---|---|
| `autoloads/tick_clock.gd` | **Keep** | Tick-driven sim is exactly the idle-accumulation model we want |
| `autoloads/resource_ledger.gd` | **Keep + slim** | Reduce visible resources from 11 to 3 internal (BIOMASS / NUTRIENTS / DECAY); drop SUNLIGHT / SPORES / PRESSURE / PROTEIN / LIFEFORCE / BLOOD / GRAY_MATTER / MYCELIAL_STABILITY |
| `autoloads/game_state.gd` | **Keep** | Run/meta save split fits prototype |
| `autoloads/event_bus.gd` | **Keep** | Signal architecture intact |
| `autoloads/save_system.gd` | **Keep mostly** | 873 lines — touch only resource-list constants; watch schema-versioning carefully |
| `systems/nutrient_system.gd` | **Rework** | Currently injects N/Sun/Decay per-biome per-tile. Replace with: biome provides *baseline* multipliers; species produce resources via recipes (per V1_PROTOTYPE.md § 4) |
| `systems/growth_system.gd` | **Significant rewrite** | 324 lines of structure/trait/affinity/maturation bonuses (Phase 15a/15c leftover). Strip to: recipe input availability → consume → produce. Save the bonus tower for v2 reference |
| `systems/offline_progress.gd` | **Keep** | Idle catch-up works as-is |
| `systems/territory_system.gd` | **Keep** | Tile placement tracking; needed |

### Run lifecycle

| File | Status | Notes |
|---|---|---|
| `systems/prestige_system.gd` | **Rework lightly** | start_run flow fine. Reward formula: replace biomass-earned-based with `reproductions × tier_mult + closure_bonus` |
| `autoloads/run_goal_system.gd` | **Repurpose** | Slim from 176 lines to ~30: hard-code goal = "reach biomass 100,000 + cycle closed" |
| `ui/starting_species_picker.gd` | **Defer** | Lock to tree_fern_stem; skip picker UI; auto-launch run |
| `ui/main_menu.gd` | **Light edit** | "Start Run" button straight to world.tscn |
| `ui/world_map.gd` | **Defer** | Ecosystem picker — restore in v2 with multiple biomes |
| `ui/prestige_screen.gd` | **Rework** | Show Evolution Points banked + lineage-tree node added |

### UI overhaul

| File | Status | Notes |
|---|---|---|
| `ui/hud.gd` (420 lines) | **Major rewrite** | New HUD = one huge biomass counter + rate. Strip 5-resource row, identity strip, abilities bar, event toast |
| `scenes/ui/hud.tscn` | **Major rewrite** | Scene structure changes |
| `ui/species_panel.gd` (300 lines) | **Rework** | Strip Introduced/Available split. Show 3 species buttons unlocked at biomass milestones |
| `ui/goal_banner.gd` | **Cut** | Coal Gauge UI replaced by HUD biomass counter |
| `ui/onboarding_overlay.gd` | **Rewrite** | Existing flow IS close. Drive new checkpoint system + per-cluster diagnostic tooltips |
| `ui/recipe_book.gd` (336 lines) | **Cut for prototype** | Three-tab Field Guide is too much for v1 |
| `ui/evolve_modal.gd` | **Cut for prototype** | Per-species adaptation is v2+ |
| `ui/evolution_tree_canvas.gd` (271 lines) | **Defer/repurpose** | For prototype, replace with flat list of completed runs |
| `ui/biome_legend.gd` | **Keep** | |
| `ui/cluster_float.gd` | **Keep** | |
| `ui/era_transition.gd` | **Cut** | Era transitions v2+ |
| `ui/era_background_tint.gd` | **Keep** | Cheap visual |
| `ui/multiplier_chips.gd` | **Cut** | Multi-resource displays |
| `ui/structure_banner.gd` | **Cut** | No structures in prototype |

### Systems to cut for prototype

(Per [[feedback-no-beta-preservation]] — these stay deleted, not stubbed.)

| File | Why cut |
|---|---|
| `autoloads/adaptation_system.gd` | Per-species leveling = v2+ |
| `autoloads/era_system.gd` | Single era only in prototype |
| `autoloads/discovery_log.gd` | Discovery state is more UI than core |
| `systems/ability_system.gd` | Hero abilities = v2+ |
| `systems/structure_registry.gd` (449 lines) | Pattern detection = v2+ |
| `systems/ecological_pressure.gd` (239 lines) | Random events replaced by checkpoint system |
| `systems/ambient_modifier_system.gd` | Event-driven multipliers |
| `systems/corpse_system.gd` | Hero death dead; corpse mechanics v2+ |
| `systems/herbivore_manager.gd` (316 lines) | Entity-based herbivores → simpler grazer-as-species |
| `entities/herbivore.gd` | Same |
| `systems/spore_infection_handler.gd` | Specialized spore mechanic |
| `systems/fog_system.gd` | Fog of war not in prototype |
| `systems/cluster_income_tracker.gd` | Stat tracking; not core |
| `systems/colonization_rules_registry.gd` (435 lines) | Strip to ~50 lines — only need `adjacent_empty` |

### Data layer

| File | Status | Notes |
|---|---|---|
| `data/species_data.gd` | **Slim significantly** | Keep: id, display_name, kingdom_id, tick_yield, consume_input (new), tile_marker_color, tile_sprite_paths. Drop: base_traits, introduce_cost, colonize_cost, placement_rule, placement_targets, tags, tick_effects, unlock_*, era_requires, recipe_components, biome_affinity |
| `data/biome_data.gd` | **Slim** | Drop chemosynthesis; keep base multipliers |
| `data/ecosystem_data.gd` | **Keep** | Only Coal Swamp in prototype |
| `data/era_data.gd` | **Cut for prototype** | |
| `data/per_run_goal_data.gd` | **Cut for prototype** | Hard-coded goal instead |
| `data/structure_data.gd` | **Cut for prototype** | |
| `data/ability_data.gd` | **Cut for prototype** | |
| `data/evolution_node_data.gd` | **Keep minimally** | Lineage tree node |
| `data/trait_data.gd` | **Cut for prototype** | |
| `data/event_data.gd` | **Cut for prototype** | |
| `data/discovery_entry.gd` | **Cut for prototype** | |

### Data files (.tres) — content rewrites

| File | What to rewrite |
|---|---|
| `data/species/tree_fern_stem.tres` (hero) | tick_yield={biomass: 2.0}, consume_input={nutrients: 1.0}, side_output={decay: 0.2} |
| `data/species/mycelium_thread.tres` | tick_yield={nutrients: 1.5}, consume_input={decay: 1.5} |
| `data/species/common_grazer.tres` | tick_yield={decay: 1.5}, consume_input={biomass: 1.5}, placement_cost=50 hero biomass |
| Other species .tres | Leave in place — not loaded in prototype scope |
| `data/biomes/wetland.tres` | Theme to Coal Swamp; baseline multipliers may stay |
| `data/ecosystems/coal_swamp.tres` | Verify exists (onboarding references it) |
| `data/goals/_index.tres` | Add `prototype_v1` goal OR strip RunGoalSystem entirely |

---

## 3. Order of operations

Suggested sequence — each step ends with a runnable game state.

### Step 1 — Recipe model in data (~0.5 day)
- Update `species_data.gd` to slimmed-down version with `consume_input` field
- Rewrite the 3 species .tres files with new recipes
- Update `growth_system.gd` to honor input availability (throttle when input pool empty)
- **Test:** species ticks produce/consume per spec; bottleneck appears when input drained

### Step 2 — HUD reduction (~0.5 day)
- Rewrite `hud.gd` + `hud.tscn` to single biomass counter + rate
- Strip cut UI children from `world.tscn`
- **Test:** run loads, single number ticks up

### Step 3 — Run lifecycle simplification (~0.5 day)
- Skip starting_species_picker for prototype — auto-launch tree_fern_stem run
- Replace `run_goal_system.gd` with biomass-threshold + cycle-closure checker
- **Test:** run starts → biomass accumulates → can hit run-end target

### Step 4 — Placement costs + checkpoint flow (~1 day)
- Add placement-cost deduction in species_panel introduce flow
- Add `hero_biomass_lifetime_produced` counter (monotonic, ticks DOWN only on placement)
- Rewrite `onboarding_overlay.gd` with prototype checkpoints (milestone OR bottleneck triggers)
- **Test:** full first-run end-to-end

### Step 5 — Cycle closure detection (~0.5 day)
- Detect when all 3 species are placed AND all 3 pools are flowing
- Trigger visual glow + ×1.5 throughput multiplier
- **Test:** placing the grazer triggers the closure event

### Step 6 — Per-cluster status indicators (~0.5 day)
- Render green/yellow/red availability bar on each species cluster
- **Test:** bars correctly indicate starvation

### Step 7 — Prestige reskin (~0.5 day)
- Update `prestige_screen.gd` to show Evolution Points + lineage tree node
- Replace `evolution_tree_canvas.gd` with flat list of completed runs
- **Test:** run-end → bank → next run loads

**Total:** ~4 days of focused implementation, sequenced linearly so each step leaves a playable build.

---

## 4. Risks and surprises

1. **The existing build is closer to the prototype than expected.** Migration is refocus. Big chunks (TickClock, ResourceLedger, TerritorySystem, OfflineProgress) work as-is.
2. **GrowthSystem is heavily over-engineered.** 324 lines of conditional bonus stacking — most of it Phase 15a/15c era-system / adaptation / mycorrhizal / structure logic. Stripping it cleanly is the highest-risk step. Recommend doing in a feature branch with the old version preserved for v2 reference.
3. **Hero biomass counter as monotonic-from-production doesn't exist yet.** Current biomass goes UP from species ticks and DOWN when species are introduced (cost in biomass). Need a new `hero_lifetime_biomass_produced` field that's monotonic from production AND ticks down on placement cost.
4. **Coal Gauge is themed and working.** Tempting to keep as fallback. Don't — per [[feedback-no-beta-preservation]]. But it's a useful reference for "fill the gauge" feel.
5. **save_system.gd is 873 lines** and likely has schema versioning for the cut fields. Touch carefully — broken saves are very bad.
6. **Onboarding step copy references Calamites + Mycorrhizal Network + Arthropleura.** Current species are tree_fern_stem + mycelium_thread + common_grazer. Either rename species files to match onboarding OR rewrite onboarding copy. Renaming is cleaner long-term and matches user's Carboniferous flavor intent.
7. **Unused species .tres files stay.** They won't load unless referenced; leave alone to keep the cut lean.

---

## 5. What this defers explicitly to v2+

Stay deleted, not stubbed. No pre-emptive hooks.

- Adaptation/leveling (`adaptation_system.gd`, `evolve_modal.gd`)
- Era system (`era_system.gd`, `era_transition.gd`)
- Discovery log (`discovery_log.gd`)
- Structure detection (`structure_registry.gd`, `structure_banner.gd`)
- Ecological events (`ecological_pressure.gd`, `ambient_modifier_system.gd`)
- Herbivore as entity (`herbivore_manager.gd`, `herbivore.gd`)
- Fog of war (`fog_system.gd`)
- Hero abilities (`ability_system.gd`)
- Field Guide / Recipe Book (`recipe_book.gd`)
- World map / ecosystem picker (`world_map.gd`)
- Per-species evolution (evolve_modal, level-up UI)
- All non-prototype species data files (bramble, common_predator, cryo_lichen, etc.)

---

## 6. Open questions for implementer — RESOLVED 2026-05-27

1. **Branch strategy** — **In-place on main** with frequent focused commits. Each step in § 3 ends with a runnable build, so the working tree stays shippable between steps.
2. **Species renames** — **No renames.** Calamites / Mycorrhizal Network / Arthropleura already exist as `.tres` files (verified 2026-05-27). Use existing IDs.
3. **Cut-vs-comment strategy** — **Unwired.** Files stay on disk; remove their references from scene trees / autoload registry / signal connections. Git history preserves them for v2 reference, but they don't load.
4. **Save migration** — **Accepted break.** Bump `SAVE_VERSION`; existing saves get zeroed. Alpha audience; no migration path written.
