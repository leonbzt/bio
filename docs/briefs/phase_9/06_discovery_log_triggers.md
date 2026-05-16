# Brief 06 — DiscoveryLog trigger wiring

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — touches the EventBus contract surface.

Read first:
1. `docs/STORY_AND_TONE.md` § Discovery log triggers.
2. `docs/briefs/phase_9/00_phase_8_recap.md` decision 3 (four trigger categories).
3. `docs/briefs/phase_9/02_schema_extensions.md` (`DiscoveryLog` autoload + `unlock` API + `find_entry_for_trigger`).
4. `scripts/autoloads/event_bus.gd` — full signal list.
5. `scripts/systems/prestige_system.gd` for the kingdom unlock + node-purchase signal sources.

## Goal
Wire `DiscoveryLog` to listen for the four trigger sources locked in phase 9:
1. **Kingdom unlock** — `EventBus.evolution_node_unlocked` fires; if that node has `grants_kingdoms`, fire one discovery entry per granted kingdom (category `&"kingdom"`, trigger_id = kingdom_id).
2. **Niche first-play** — `EventBus.niche_changed(niche_id)` fires; first time the player plays a given niche, fire a discovery (category `&"niche"`, trigger_id = niche_id).
3. **Evolution node purchase** — `EventBus.evolution_node_unlocked(node_id)` fires; fire one discovery (category `&"node"`, trigger_id = node_id). The same signal drives the kingdom-unlock fire above; both can fire on a single purchase if both entries exist.
4. **Event first-fire + milestones** — `EventBus.event_resolved(event_id, outcome)` fires; if this is the first fire of this event in the current run, fire a discovery (category `&"event"`). Milestones (5 prestiges, first cross-wing node, etc.) fire via direct calls from `PrestigeSystem`.

## Implementation

### Extend `scripts/autoloads/discovery_log.gd`

Append after the existing public API:

```gdscript
# Persistent "niches the player has ever started" set, used by niche-trigger dedup.
# Stored under meta.niches_played as a sorted list of strings, mirroring kingdoms_played.
const _MILESTONES: Dictionary[StringName, int] = {
    # milestone trigger_id -> prestige_count threshold (or other condition handled in code)
    &"prestige_5": 5,
    &"prestige_25": 25,
    &"prestige_50": 50,
}


func _enter_tree() -> void:
    EventBus.evolution_node_unlocked.connect(_on_evolution_node_unlocked)
    EventBus.niche_changed.connect(_on_niche_changed)
    EventBus.event_resolved.connect(_on_event_resolved)
    EventBus.prestige_triggered.connect(_on_prestige_triggered)


func _on_evolution_node_unlocked(node_id: StringName) -> void:
    # Node-purchase entry.
    var node_entry := find_entry_for_trigger(&"node", node_id)
    if node_entry != &"":
        unlock(node_entry)

    # Kingdom-unlock entries (a node may grant multiple kingdoms).
    var node: EvolutionNodeData = _lookup_node(node_id)
    if node != null:
        for kingdom_id in node.grants_kingdoms:
            var kingdom_entry := find_entry_for_trigger(&"kingdom", kingdom_id)
            if kingdom_entry != &"":
                unlock(kingdom_entry)


func _on_niche_changed(niche_id: StringName) -> void:
    if niche_id == &"":
        return
    # Persistent dedup: only fire once ever per niche.
    var played: Array = GameState.meta_save.get("niches_played", []) as Array
    if played.has(String(niche_id)):
        return
    played.append(String(niche_id))
    GameState.meta_save["niches_played"] = played
    var entry := find_entry_for_trigger(&"niche", niche_id)
    if entry != &"":
        unlock(entry)


func _on_event_resolved(event_id: StringName, _outcome: StringName) -> void:
    # Per-run dedup via run.event_first_fires_seen.
    var seen: Array = GameState.run_save.get("event_first_fires_seen", []) as Array
    if seen.has(String(event_id)):
        return
    seen.append(String(event_id))
    GameState.run_save["event_first_fires_seen"] = seen
    var entry := find_entry_for_trigger(&"event", event_id)
    if entry != &"":
        unlock(entry)


func _on_prestige_triggered(summary: Dictionary) -> void:
    var stats: Dictionary = GameState.meta_save.get("statistics", {})
    var count: int = int(stats.get("prestige_count", 0))
    for milestone_id in _MILESTONES.keys():
        var threshold: int = _MILESTONES[milestone_id]
        if count >= threshold:
            var entry := find_entry_for_trigger(&"milestone", milestone_id)
            if entry != &"":
                unlock(entry)


func _lookup_node(node_id: StringName) -> EvolutionNodeData:
    var ps := get_tree().get_first_node_in_group("prestige_system")
    if ps == null:
        return null
    for node in ps.get_all_nodes():
        if node.id == node_id:
            return node
    return null
```

### Save schema addition

`meta.niches_played` is new. Add a quiet default to `SaveSystem._build_default_save()`:

```gdscript
"niches_played": [],
```

And to the v5→v6 migration arm (brief 01) — **add this line** to the meta block:

```gdscript
if not meta.has("niches_played"):
    meta["niches_played"] = []
```

If brief 01 has already shipped without this, add a v6→v7 micro-migration. Otherwise fold into v6.

### Custom milestone: first cross-wing node

Hardcode this one in `_on_evolution_node_unlocked` after the existing kingdom/node fires:

```gdscript
    if node != null and not node.requires_kingdom_played.is_empty():
        var entry := find_entry_for_trigger(&"milestone", &"first_cross_kingdom_node")
        if entry != &"":
            unlock(entry)
```

(Idempotent — `unlock` no-ops if already unlocked.)

## Manual test plan

1. Cold load. `DiscoveryLog.get_unlocked_count() == 0`.
2. Start a plantae run (Photosynthesizer). After the niche_changed fires, the photosynthesizer entry unlocks.
3. Buy `unlock_fungi`. The fungi-kingdom entry + the fungi-kingdom-unlock node entry both fire (two entries from one purchase).
4. Buy a cross-kingdom node like `soil_memory` (requires fungi played first). The `first_cross_kingdom_node` milestone fires alongside the node's own entry.
5. Trigger a drought event. First fire unlocks the drought entry. Second fire same run = no new entry.
6. Prestige. New run. Drought fires again = no new entry (persistent dedup via `find_entry_for_trigger` lookup → entry already unlocked).
7. Inspect `save.json`: `meta.discovery_log` has the expected entry_ids set to `true`. `run.event_first_fires_seen` has the event_ids that fired this run.

## Acceptance criteria
- [ ] `_enter_tree` connects all four signal handlers.
- [ ] Node-purchase fires the node entry + any kingdom entries.
- [ ] First niche-play fires the niche entry; second play of same niche fires nothing.
- [ ] First event resolution this run fires the entry; subsequent fires this run fire nothing.
- [ ] Milestone entries fire on `prestige_triggered` when threshold met.
- [ ] `first_cross_kingdom_node` milestone fires on first purchase of a node with non-empty `requires_kingdom_played`.
- [ ] All unlocks idempotent (verified by spamming `EventBus.evolution_node_unlocked.emit(&"any_owned_node")`).
- [ ] `EventBus.discovery_unlocked` emits exactly once per genuine new unlock (UI in brief 08 can rely on it for toast notifications).

## Out of scope
- Discovery entry content (brief 07).
- Discovery log UI (brief 08).
- Era-transition entries (Phase 11).
- Species-first-played entries (Phase 10+).
- Toast notification on `discovery_unlocked` — brief 08 wires the HUD toast.
