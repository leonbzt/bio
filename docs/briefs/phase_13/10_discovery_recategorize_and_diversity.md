# Brief 10 — Discovery re-categorization + diversity prestige multiplier

**Suggested agent**: Kilo for the discovery .tres edits. ChatGPT 5.2 for the prestige multiplier code. Claude reviews.

Read first:
1. `data/discovery/*.tres` — all 38 entries (Phases 9-12).
2. `scripts/autoloads/discovery_log.gd` — niche_changed handler (deleting).
3. `scripts/systems/prestige_system.gd` — `calculate_prestige_reward` (where diversity multiplier lands).
4. `docs/SPECIES_MODEL.md` §End (Locked Decision 14).

## Goal

Two unrelated finishing touches the migration phase needs:

1. **Discovery re-categorization** — entries with `category: &"niche"` and the niche-changed unlock wiring need to be re-keyed to the species-first taxonomy. Voice text bodies are unchanged.
2. **Diversity prestige multiplier** — `× 1.0 / 1.1 / 1.2` for cultivating 1 / 2 / 3+ species in a run.

## Part 1 — Discovery re-categorization

### Affected entries

Currently 4 entries have `category: &"niche"`:
- `disc_niche_photosynthesizer` (trigger: photosynthesizer)
- `disc_niche_decomposer` (trigger: decomposer)
- `disc_niche_parasitic_plantae` (trigger: parasitic_plantae)
- `disc_niche_mycorrhizal_fungi` (trigger: mycorrhizal_fungi)

### Re-categorization mapping

| Entry id (unchanged) | Old category | Old trigger_id | New category | New trigger_id |
|---|---|---|---|---|
| `disc_niche_photosynthesizer` | niche | photosynthesizer | species | pioneer_grass |
| `disc_niche_decomposer` | niche | decomposer | species | mycelium_thread |
| `disc_niche_parasitic_plantae` | niche | parasitic_plantae | species | bramble |
| `disc_niche_mycorrhizal_fungi` | niche | mycorrhizal_fungi | species | mycelium_thread_mycorrhizal |

Entry ids stay the same — keeps `meta.discovery_log` keys valid across the migration. Only the `category` and `trigger_id` fields change in each .tres.

### DiscoveryLog rewiring

In `scripts/autoloads/discovery_log.gd`:

- **Delete** `_on_niche_changed(niche_id)` handler.
- **Delete** the `EventBus.niche_changed.connect(...)` subscription.
- **Add** `_on_species_introduced(species_id)` handler:

```gdscript
func _on_species_introduced(species_id: StringName) -> void:
    if species_id == &"":
        return
    var entry := find_entry_for_trigger(&"species", species_id)
    if entry != &"":
        unlock(entry)
    # Also track in meta.species_played if this is the starting species.
    var starter: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
    if species_id == starter:
        var played: Array = GameState.meta_save.get("species_played", []) as Array
        if not played.has(String(species_id)):
            played.append(String(species_id))
            GameState.meta_save["species_played"] = played
            SaveSystem.save_now()
```

Wire to `EventBus.species_introduced` (new signal from brief 07).

- **Also fire on run_started**: the starting species counts as "introduced" — add an early call from `_on_run_started`:

```gdscript
func _on_run_started(kingdom_id: StringName) -> void:
    # Existing kingdom-entry unlock stays.
    if kingdom_id != &"":
        var entry := find_entry_for_trigger(&"kingdom", kingdom_id)
        if entry != &"":
            unlock(entry)
    # Also fire species_introduced for the starting species so its discovery entry unlocks.
    var starter: StringName = StringName(GameState.run_save.get("starting_species_id", ""))
    if starter != &"":
        _on_species_introduced(starter)
```

### EventBus update

Delete the `niche_changed(niche_id: StringName)` signal from `event_bus.gd`. Add:

```gdscript
signal species_introduced(species_id: StringName)
```

(Brief 07 emits this; brief 10 + future content consume it.)

## Part 2 — Diversity prestige multiplier

### `scripts/systems/prestige_system.gd`

```gdscript
static func calculate_prestige_reward(total_biomass_earned: float, species_diversity: int = 1) -> int:
    var base: int = int(sqrt(maxf(0.0, total_biomass_earned) / 10.0))
    var diversity_mult: float = 1.0
    if species_diversity >= 3:
        diversity_mult = 1.2
    elif species_diversity == 2:
        diversity_mult = 1.1
    return int(round(base * diversity_mult))


func get_pending_reward() -> int:
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    var diversity: int = (GameState.run_save.get("unlocked_species_in_run", []) as Array).size()
    return calculate_prestige_reward(earned, diversity)


func trigger_prestige() -> void:
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    var diversity: int = (GameState.run_save.get("unlocked_species_in_run", []) as Array).size()
    var reward: int = calculate_prestige_reward(earned, diversity)
    _record_species_played()
    _update_meta_stats(reward, earned)
    _reset_run_state()
    var summary := {
        "evolution_points_earned": reward,
        "total_biomass_earned": earned,
        "species_cultivated": diversity,
        "starting_species_id": GameState.run_save.get("starting_species_id", "")
    }
    EventBus.prestige_triggered.emit(summary)


func _record_species_played() -> void:
    var starter: String = String(GameState.run_save.get("starting_species_id", ""))
    if starter == "":
        return
    var played: Array = GameState.meta_save.get("species_played", []) as Array
    if not played.has(starter):
        played.append(starter)
        GameState.meta_save["species_played"] = played
```

### Prestige screen summary

The screen showing prestige results (after trigger_prestige) reads the new `species_cultivated` + `starting_species_id` from the summary dict and displays:

> "You earned **N** Evolution Points.
> Total biomass: **X**
> Species cultivated: **Y** (×1.2 diversity bonus)
> Beginning: **Starting Species Display Name**"

Light text update; no new scene.

## Acceptance criteria

### Re-categorization
- [ ] 4 niche-category entries have `category: &"species"` and updated `trigger_id`s per the table.
- [ ] `DiscoveryLog._on_niche_changed` handler deleted.
- [ ] `DiscoveryLog._on_species_introduced` handler added and wired.
- [ ] `EventBus.niche_changed` signal deleted; `species_introduced` signal added.
- [ ] First-introduction of each species (including starting) unlocks the matching `disc_*` entry.
- [ ] Existing `meta.discovery_log` keys remain valid (no entries lost across migration).

### Diversity multiplier
- [ ] `calculate_prestige_reward` accepts `species_diversity` param; reads `unlocked_species_in_run.size()`.
- [ ] Multiplier applies: 1× / 1.1× / 1.2× for 1 / 2 / 3+ species.
- [ ] Prestige summary surfaces species_cultivated count + starting_species id.
- [ ] `meta.species_played` updates on prestige with the starting species.

## Out of scope

- New discovery entries (Phase 14 — for new biomes, new species, new events).
- Per-species prestige milestones (e.g., "cultivated 10 unique starting species" — Phase 14).
- Re-balanced diversity curve (Phase 14 — current 1.0/1.1/1.2 may want a steeper ramp at 5+/10+).
- "Diversity goal" as a PerRunGoalData kind (Phase 14).
- Replays / past-run species records on prestige screen. Polish.
