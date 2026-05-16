# Brief 03 — Tag existing nodes with wing/tier + enforce `requires_kingdom_played`

**Suggested agent**: Kilo for the `.tres` edits (mechanical data update); ChatGPT 5.2 for the `prestige_system.gd` logic. Route diff to Claude.

Read first:
1. `docs/PROGRESSION_WEB.md` § "Migration from current tree".
2. `docs/briefs/phase_9/02_schema_extensions.md` (must land first).
3. `scripts/systems/prestige_system.gd` `purchase_node` + `trigger_prestige`.
4. All 10 files in `data/evolution_tree/*.tres`.

## Goal
Two changes:
1. **Data**: tag each of the 10 existing evolution nodes with `wing` and `tier`. None of them get `requires_kingdom_played` — they all predate the gate. Brief 04 adds new nodes that use the gate.
2. **Logic**: enforce `requires_kingdom_played` in `PrestigeSystem.purchase_node`, and append to `meta.kingdoms_played` in `PrestigeSystem.trigger_prestige`.

## Part 1 — Tag existing nodes

Apply the wing/tier assignments below. Edit each `.tres` to add two lines under `grants_kingdoms`:

```
wing = &"<wing>"
tier = <int>
```

| File | wing | tier | Notes |
|---|---|---|---|
| `thrifty_growth.tres` | `&"plantae"` | `1` | Entry. Cost reduction is plantae-flavored. |
| `pioneer_resilience.tres` | `&"plantae"` | `1` | Entry. Bootstrap survival. |
| `efficient_photosynthesis.tres` | `&"plantae"` | `1` | Entry. |
| `toxin_potency.tres` | `&"plantae"` | `2` | Mid — anti-herbivore. |
| `unlock_fungi.tres` | `&"hybrid"` | `1` | The "discovery" node — hybrid wing because it's the gateway, not a plantae-pure progression. |
| `unlock_parasitic_plantae.tres` | `&"plantae"` | `2` | The niche unlock counts as plantae mid-tier. |
| `unlock_mycorrhizal_fungi.tres` | `&"fungi"` | `2` | Mirrors parasitic — kingdom-local niche unlock. |
| `unlock_symbiosis.tres` | `&"hybrid"` | `2` | Cross-kingdom kingdom unlock. |
| `mutualism.tres` | `&"hybrid"` | `2` | Cross-kingdom effect. |
| `wood_wide_web.tres` | `&"hybrid"` | `3` | Capstone — fungi+plant network. |

Example diff for `thrifty_growth.tres`:
```
 grants_traits = []
 grants_kingdoms = []
+wing = &"plantae"
+tier = 1
```

No `_index.tres` change needed — the order is preserved.

## Part 2 — Enforce `requires_kingdom_played`

### `scripts/systems/prestige_system.gd`

**Add a helper:**
```gdscript
func _kingdoms_played_satisfied(node: EvolutionNodeData) -> bool:
    if node.requires_kingdom_played.is_empty():
        return true
    var played: Array = GameState.meta_save.get("kingdoms_played", [])
    for required in node.requires_kingdom_played:
        if not played.has(String(required)):
            return false
    return true
```

**Extend `purchase_node`** — insert the check between prereqs and cost:
```gdscript
func purchase_node(node_id: StringName) -> bool:
    var node := _find_node(node_id)
    if node == null:
        return false
    if is_node_unlocked(node_id):
        return false
    if not _prerequisites_met(node):
        return false
    if not _kingdoms_played_satisfied(node):    # NEW
        return false                            # NEW
    var cost: int = int(node.meta_cost.get("evolution_points", 0))
    ...
```

**Extend `trigger_prestige`** — append the just-finished kingdom to `kingdoms_played` before resetting run state:
```gdscript
func trigger_prestige() -> void:
    var reward: int = get_pending_reward()
    var earned: float = float(GameState.run_save.get("statistics", {}).get("total_biomass_earned", 0.0))
    _record_kingdom_played()                    # NEW — must happen before _reset_run_state
    _update_meta_stats(reward, earned)
    _reset_run_state()
    var summary := {
        "evolution_points_earned": reward,
        "total_biomass_earned": earned
    }
    EventBus.prestige_triggered.emit(summary)
    SaveSystem.save_now()


func _record_kingdom_played() -> void:
    var kid: String = String(GameState.run_save.get("kingdom_id", ""))
    if kid == "":
        return
    var played: Array = GameState.meta_save.get("kingdoms_played", []) as Array
    if not played.has(kid):
        played.append(kid)
    GameState.meta_save["kingdoms_played"] = played
```

**Public helper for the UI** (brief 05 uses this for tooltips):
```gdscript
func get_unsatisfied_kingdoms(node_id: StringName) -> Array[StringName]:
    var node := _find_node(node_id)
    if node == null:
        return []
    var played: Array = GameState.meta_save.get("kingdoms_played", [])
    var missing: Array[StringName] = []
    for required in node.requires_kingdom_played:
        if not played.has(String(required)):
            missing.append(required)
    return missing
```

## Tests

Append to `tests/test_prestige_system.gd` (or create the file mirroring `tests/test_save_system.gd`'s structure):

```gdscript
func test_purchase_node_blocked_by_kingdoms_played() -> void:
    # Set up: a fake node that requires fungi played; player has only plantae played.
    GameState.meta_save = {
        "evolution_tree": {},
        "kingdoms_played": ["plantae"],
        "statistics": {"evolution_points_balance": 100},
        "unlocked_kingdoms": ["plantae", "fungi"]
    }
    var node := EvolutionNodeData.new()
    node.id = &"_test_gated"
    node.meta_cost = {"evolution_points": 5}
    node.requires_kingdom_played = [&"fungi"]
    PrestigeSystem._nodes_by_id[node.id] = node
    PrestigeSystem._all_nodes.append(node)

    assert_false(PrestigeSystem.purchase_node(&"_test_gated"))
    assert_false(PrestigeSystem.is_node_unlocked(&"_test_gated"))

    # After playing fungi, purchase succeeds.
    GameState.meta_save["kingdoms_played"] = ["plantae", "fungi"]
    assert_true(PrestigeSystem.purchase_node(&"_test_gated"))


func test_trigger_prestige_records_kingdom_played() -> void:
    GameState.run_save = {
        "kingdom_id": "plantae",
        "statistics": {"total_biomass_earned": 100.0}
    }
    GameState.meta_save = {"kingdoms_played": [], "statistics": {}, "evolution_tree": {}}
    PrestigeSystem.trigger_prestige()
    assert_true(GameState.meta_save["kingdoms_played"].has("plantae"))

    # Idempotent: prestige plantae again, no duplicate.
    GameState.run_save = {"kingdom_id": "plantae", "statistics": {"total_biomass_earned": 50.0}}
    PrestigeSystem.trigger_prestige()
    assert_eq(GameState.meta_save["kingdoms_played"].count("plantae"), 1)
```

## Acceptance criteria
- [ ] All 10 `.tres` files have `wing` and `tier` set per the table.
- [ ] Loading the game produces no errors; `PrestigeSystem.get_all_nodes()` returns 10 nodes each with non-empty `wing`.
- [ ] `purchase_node` returns false for a hypothetical node with unsatisfied `requires_kingdom_played` (test above).
- [ ] `trigger_prestige` appends to `kingdoms_played` exactly once per kingdom (idempotent).
- [ ] `get_unsatisfied_kingdoms(node_id)` returns the missing kingdom_ids for any node.
- [ ] Existing prestige UI still works — no behavior change for nodes without `requires_kingdom_played`.

## Out of scope
- Authoring new cross-kingdom nodes (brief 04).
- Tree-visualization UI changes (brief 05) — the old UI keeps working off `is_node_unlocked` + `_prereqs_met` semantics.
- Showing the gate in the UI (brief 05 wires `get_unsatisfied_kingdoms` into tooltips).
