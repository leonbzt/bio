# Brief 07 — Run flow rebuild (world map + species picker + introduce panel)

**Suggested agent**: ChatGPT 5.2. Route diff to Claude — mobile layout.

Read first:
1. `scripts/ui/world_map.gd` + `scenes/ui/world_map.tscn` — Phase 12 ecosystem cards.
2. `scripts/ui/prestige_screen.gd` — current kingdom-cascade flow (replaced).
3. `scripts/systems/prestige_system.gd` — `start_run` path.
4. `docs/SPECIES_MODEL.md` §Run flow.

## Goal

Replace the kingdom → niche → species cascade with:
1. **World map** (kept, light reshape) → tap an ecosystem.
2. **Starting species picker** (new, replaces prestige_screen's kingdom cascade) → tap a species from `ecosystem.starting_species_filter ∩ meta.species_unlocked`.
3. **Begin run** → resources granted, biome map generated, run starts.
4. **In-run "Introduce species" panel** (new) → during play, see other unlocked species; tap one to pay `introduce_cost` and add it to the placeable pool.
5. **Species panel** (replaces niche/kingdom selector) → tap any introduced species to set it as the active placement target for taps on the map.

## Scenes / scripts to add or rebuild

### `scenes/ui/starting_species_picker.tscn` + `scripts/ui/starting_species_picker.gd` (new)

Modal that opens when an ecosystem is tapped. Shows:
- Ecosystem name + description at top.
- Grid of species cards (one per species in `ecosystem.starting_species_filter ∩ meta.species_unlocked`). Each card: species name, kingdom tag, tile_marker_color swatch, base_traits summary, "Begin" button.
- "Cancel" button → back to world map.

On Begin:
```gdscript
GameState.run_save["starting_species_id"] = String(species.id)
GameState.run_save["unlocked_species_in_run"] = [String(species.id)]
GameState.run_save["starting_species_kingdom_id"] = String(species.kingdom_id)
GameState.placement_target_species_id = String(species.id)
EraSystem.set_current_ecosystem(ecosystem.id)
PrestigeSystem.start_run(species)
get_tree().change_scene_to_file("res://scenes/world.tscn")
```

### `scenes/ui/species_panel.tscn` + `scripts/ui/species_panel.gd` (new)

Always-visible HUD panel during a run. Two sections:

**Introduced** — species you can currently place. One row per `unlocked_species_in_run`. Each row: species marker color, name, tile cost. Tapping a row sets `GameState.placement_target_species_id` (highlight active row).

**Available** — unlocked species not yet introduced this run. One row per `meta.species_unlocked - unlocked_species_in_run` (filtered to species whose kingdom is in current era's `available_kingdoms`). Each row: species name, introduce_cost summary, "Introduce" button (greyed if player can't afford).

Tap "Introduce" → if `ResourceLedger.can_afford(species.introduce_cost)`:
```gdscript
ResourceLedger.spend(species.introduce_cost)
var in_run: Array = GameState.run_save.get("unlocked_species_in_run", []) as Array
in_run.append(String(species.id))
GameState.run_save["unlocked_species_in_run"] = in_run
EventBus.species_introduced.emit(species.id)
SaveSystem.save_now()
```

EventBus addition: `species_introduced(species_id: StringName)` signal. Wired in brief 10's discovery log update.

### `scripts/ui/world_map.gd` — light reshape

Current Phase 12 world_map.gd opens directly to "begin run as kingdom X" via existing PrestigeSystem. Update the ecosystem-card tap handler:

```gdscript
func _on_ecosystem_card_pressed(ecosystem: EcosystemData) -> void:
    var picker := preload("res://scenes/ui/starting_species_picker.tscn").instantiate()
    picker.ecosystem = ecosystem
    add_child(picker)
    # picker handles confirm → scene change.
```

### Delete `scripts/ui/prestige_screen.gd` (or strip to evolution-tree-only)

The current prestige_screen handles both "evolution tree purchases" and "begin run as kingdom X". Phase 13 splits these:
- Evolution tree → stays in prestige_screen (or rename to `evolution_screen.gd`).
- Begin run flow → world_map → starting_species_picker.

If the prestige-screen scene also contains the kingdom-pick widgets, strip them out; keep the evolution tree + EP balance display.

### Update `scripts/ui/pause_menu.gd`

The "World Map" button stays. The (Phase 12) "Begin Run" / "End Run" buttons need a quick check — they should now go through the world_map → species_picker flow, not directly into a run.

### Update `scripts/systems/prestige_system.gd.start_run`

```gdscript
func start_run(species: SpeciesData) -> void:
    # No more kingdom/niche cascade. species carries everything.
    GameState.current_kingdom_id = species.kingdom_id   # denormalized mirror
    # (current_niche_id is gone — no assignment.)
    _reset_run_state()
    GameState.run_save["starting_species_id"] = String(species.id)
    GameState.run_save["unlocked_species_in_run"] = [String(species.id)]
    GameState.run_save["starting_species_kingdom_id"] = String(species.kingdom_id)
    # Grant starting resources (was per-kingdom; now per-species).
    for k in species.tick_yield.keys():
        # Loose heuristic: grant ~10 ticks worth of resources as a starter pad.
        ResourceLedger.add(StringName(k), float(species.tick_yield[k]) * 10.0)
    EventBus.run_started.emit(species.kingdom_id)
    SaveSystem.save_now()
```

Phase 14 will refine the starting-resource grant (currently `KingdomData.starting_resources` — could move to a per-species field or stay heuristic).

## HUD identity strip

A persistent strip near the top of the HUD shows: `[Starting Species] — [Ecosystem]`. Example: `Mycelium Thread — Cryogenian Volcanic Vent`. Reads from `run_save.starting_species_id` + `era_system.get_current_ecosystem().display_name`. Updates on `EventBus.run_started`.

## Mobile layout sanity (portrait 360×640)

- Species picker: 2-column grid of cards, ~140×90 each.
- Species panel: collapsible right-edge drawer; expanded width ~120px. Default collapsed during placement.
- Identity strip: ~28px tall, full width, dark background.

If the species panel + tile grid + HUD overflows, the panel collapses to a single icon (tap to expand).

## Acceptance criteria

- [ ] Tapping an ecosystem opens the starting-species picker (modal).
- [ ] Picker shows only species in `starting_species_filter ∩ meta.species_unlocked`.
- [ ] Begin transitions to world.tscn with the species set as `starting_species_id` + `placement_target_species_id`.
- [ ] During a run, the species panel shows introduced species + available-to-introduce species correctly.
- [ ] Tapping "Introduce X" pays the cost and adds X to the placeable pool.
- [ ] Tapping a species in the panel sets it as the active placement target — subsequent tile taps place that species.
- [ ] Phase 12 evolution-tree purchases still work via the (renamed/stripped) prestige_screen.
- [ ] `plant_colonization.gd`, `fungi_colonization.gd`, `animal_colonization.gd` already deleted (brief 06) — no UI button references them.
- [ ] World map era tabs + ecosystem cards survive (Phase 12 functionality intact).
- [ ] Identity strip displays starting species + ecosystem.

## Out of scope

- Per-ecosystem unique UI flavor (background art, music) — Phase 14.
- Species picker animations / VFX.
- Species panel sort modes (alphabetical, by kingdom, by cost). Polish.
- Tooltip details on species cards (multi-line trait descriptions). Polish.
- "Cancel introduction" / refund — locked: introduction is one-way per run.
- Cross-run species recommendation ("you've never played as bramble"). Polish.
