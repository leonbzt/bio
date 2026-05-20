# Brief 04 — Biome legend + species picker respect fog

**Suggested agent**: ChatGPT 5.2. Route diff to Claude.

Read first:
1. `scripts/ui/biome_legend.gd._unique_biomes_in_play` — current biome enumeration.
2. `scripts/ui/starting_species_picker.gd._get_candidates` — starting-species filter.
3. `scripts/systems/fog_system.gd.is_revealed` — fog check (brief 02).

## Goal

UI should only reveal what the player has *seen*. Two consumers:

1. **Biome legend** — only show chips for biomes present on *revealed* tiles.
2. **Starting-species picker** — unchanged for v1 (ecosystem filter already drives what shows there). Note: pickers run before any tiles exist, so fog hasn't reduced anything yet.

This makes the biome legend an exploration reward: as you reveal more terrain, more biome chips appear.

## BiomeLegend update

In `scripts/ui/biome_legend.gd._unique_biomes_in_play`:

```gdscript
func _unique_biomes_in_play() -> Array[StringName]:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
    var fog: Node = _get_fog_system()
    var seen: Dictionary[StringName, bool] = {}
    for k in biome_map.keys():
        var coord: Vector2i = _parse_coord_key(String(k))
        # Skip unrevealed tiles — biome legend only shows what we've seen.
        if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
            continue
        seen[StringName(biome_map[k])] = true
    var result: Array[StringName] = []
    for k in seen.keys():
        result.append(k)
    result.sort_custom(func(a, b): return String(a) < String(b))
    return result


func _get_fog_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/FogSystem")


func _parse_coord_key(s: String) -> Vector2i:
    var parts := s.split(",", false)
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))
```

Also: hook the legend to refresh whenever fog updates. Add a signal:

```gdscript
# In FogSystem (brief 02):
signal fog_updated()

# Emit at end of reveal_area():
fog_updated.emit()


# In biome_legend.gd._ready():
var fog: Node = _get_fog_system()
if fog != null and fog.has_signal("fog_updated"):
    fog.fog_updated.connect(func(): call_deferred("_refresh"))
```

## Starting species picker (unchanged for v1)

The picker runs from the world map screen — before the world is loaded. Fog state doesn't exist yet, so we can't filter against it. The picker continues to use `ecosystem.starting_species_filter`. Fog only kicks in *after* the world is rendered.

Document the rationale in the script as a comment.

## Discovery log — biome unlocks fog-aware

The biome discovery entries currently unlock when any tile in `biome_map` has that biome — even unrevealed ones. With fog, only reveal-then-unlock makes sense:

In `scripts/autoloads/discovery_log.gd._check_biomes_in_play`:

```gdscript
func _check_biomes_in_play() -> void:
    var run: Dictionary = GameState.run_save if GameState.run_save is Dictionary else {}
    var biome_map: Dictionary = run.get("biome_map", {}) as Dictionary
    var fog: Node = _get_fog_system()
    var seen: Dictionary = {}
    for k in biome_map.keys():
        var coord: Vector2i = _parse_coord_key(String(k))
        if fog != null and fog.has_method("is_revealed") and not fog.is_revealed(coord):
            continue
        seen[StringName(biome_map[k])] = true
    for biome_id in seen.keys():
        var entry := find_entry_for_trigger(&"biome", biome_id)
        if entry != &"":
            unlock(entry)


func _get_fog_system() -> Node:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return null
    return tree.root.get_node_or_null("World/Systems/FogSystem")


func _parse_coord_key(s: String) -> Vector2i:
    var parts := s.split(",", false)
    if parts.size() != 2:
        return Vector2i.ZERO
    return Vector2i(int(parts[0]), int(parts[1]))
```

Hook to `fog_updated`:

```gdscript
# In DiscoveryLog._enter_tree or _ready:
# (Wait until ready to ensure FogSystem exists.)
call_deferred("_subscribe_fog")


func _subscribe_fog() -> void:
    var fog: Node = _get_fog_system()
    if fog != null and fog.has_signal("fog_updated"):
        fog.fog_updated.connect(_check_biomes_in_play)
```

## Acceptance criteria

- [ ] Fresh run: biome legend shows only the biome of the starting reveal area (likely 1-2 biomes).
- [ ] As player reveals more tiles, new biome chips appear in the legend.
- [ ] Biome discovery entries unlock when their biome is first *revealed* (not first generated).
- [ ] Starting-species picker behavior unchanged.
- [ ] Legend refreshes promptly on each reveal.
- [ ] No perf drop from the fog-aware filtering (called only on `fog_updated`).

## Out of scope

- Animated "new biome discovered!" toast (could land in Phase 16+ polish).
- Greyed-out chips for partially-revealed biomes (binary: visible or not).
- Player ability to "scout" without colonizing — Phase 16+ ability.
