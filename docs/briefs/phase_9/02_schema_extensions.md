# Brief 02 — EvolutionNodeData extension + DiscoveryEntry resource + DiscoveryLog autoload stub

**Suggested agent**: ChatGPT 5.2 via Copilot. **Route diff to Claude** — contracts touch GameState/EventBus/autoloads.

Read first:
1. `docs/PROGRESSION_WEB.md` — wing/tier/`requires_kingdom_played` design.
2. `docs/STORY_AND_TONE.md` — discovery log triggers and voice.
3. `scripts/data/evolution_node_data.gd`.
4. `scripts/data/niche_data.gd` + `scripts/data/niche_index.gd` (mirror the pattern).
5. `scripts/autoloads/event_bus.gd`.
6. `scripts/systems/prestige_system.gd` (autoload registration pattern).

## Goal
Lay the architectural foundation for Phase 9. After this brief lands:
- `EvolutionNodeData` can carry wing/tier/cross-kingdom metadata.
- `DiscoveryEntry` resources can be authored.
- `DiscoveryLog` autoload exists with stub API.
- New `EventBus.discovery_unlocked` signal is declared.
- Save v6 fields are touched by the autoload (read-only — no triggers wired yet, brief 06 does that).
- No gameplay changes yet.

## Outputs (create / extend)

### Extend `scripts/data/evolution_node_data.gd`

```gdscript
class_name EvolutionNodeData
extends Resource
##
## A node in the meta-progression evolution tree.
## Instances live in data/evolution_tree/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var prerequisites: Array[StringName] = []   # other node ids
@export var meta_cost: Dictionary = {}              # meta-currency cost
@export var grants_traits: Array[TraitData] = []
@export var grants_kingdoms: Array[StringName] = []

# Phase 9 additions — see docs/PROGRESSION_WEB.md
@export var wing: StringName = &""                   # &"plantae", &"fungi", &"animals", &"hybrid"
@export var tier: int = 1                            # 1 = entry, 2 = mid, 3 = capstone
@export var requires_kingdom_played: Array[StringName] = []   # hard purchase gate
```

All three additions default to safe empty values so existing `.tres` files load without modification (brief 03 tags them).

### Create `scripts/data/discovery_entry.gd`

```gdscript
class_name DiscoveryEntry
extends Resource
##
## A single mythic-scientific journal entry. Authored by hand.
## Instances live in data/discovery/<id>.tres.
##

@export var id: StringName = &""
@export var title: String = ""
@export var body: String = ""

# Category drives sectioning in the discovery-log UI and filters in the index.
# Recognized values:
#   &"kingdom"   — fired when a kingdom is first unlocked
#   &"niche"     — fired when a niche is first played
#   &"node"      — fired when an evolution node is first purchased
#   &"event"     — fired when an event first resolves (per-run dedup via run.event_first_fires_seen)
#   &"milestone" — fired by DiscoveryLog at hardcoded thresholds (5 prestiges, etc.)
@export var category: StringName = &""

# What triggers this entry. Semantics depend on category:
#   kingdom   → kingdom_id (e.g. &"fungi")
#   niche     → niche_id (e.g. &"parasitic_plantae")
#   node      → evolution node id (e.g. &"wood_wide_web")
#   event     → event_id (e.g. &"drought")
#   milestone → milestone id (e.g. &"prestige_5", &"first_cross_kingdom_node")
@export var trigger_id: StringName = &""
```

### Create `scripts/data/discovery_index.gd`

```gdscript
class_name DiscoveryIndex
extends Resource

@export var entries: Array[DiscoveryEntry] = []
```

### Create `data/discovery/` directory + placeholder `_index.tres`

```
[gd_resource type="Resource" script_class="DiscoveryIndex" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/discovery_index.gd" id="1"]

[resource]
script = ExtResource("1")
entries = Array[Resource]([])
```

Brief 07 populates it.

### Create `scripts/autoloads/discovery_log.gd`

```gdscript
extends Node
##
## DiscoveryLog — owns the index of authored entries, tracks which are unlocked,
## and exposes unlock/query API. Triggers (which signals fire which entries)
## land in brief 06.
##

const DISCOVERY_INDEX_PATH: String = "res://data/discovery/_index.tres"

var _all_entries: Array[DiscoveryEntry] = []
var _entries_by_id: Dictionary[StringName, DiscoveryEntry] = {}
# Index for fast trigger → entry_id lookup. Built once on _ready.
# Key: "<category>:<trigger_id>" (e.g. "node:wood_wide_web"). Value: entry_id.
var _trigger_index: Dictionary[String, StringName] = {}


func _ready() -> void:
    add_to_group("discovery_log")
    var index: DiscoveryIndex = load(DISCOVERY_INDEX_PATH) as DiscoveryIndex
    if index == null:
        push_error("DiscoveryLog: missing discovery index")
        return
    _all_entries = index.entries
    _entries_by_id.clear()
    _trigger_index.clear()
    for entry in _all_entries:
        if entry == null:
            continue
        _entries_by_id[entry.id] = entry
        if entry.category != &"" and entry.trigger_id != &"":
            var key := "%s:%s" % [String(entry.category), String(entry.trigger_id)]
            _trigger_index[key] = entry.id


# Public API ---------------------------------------------------------------

func get_all_entries() -> Array[DiscoveryEntry]:
    return _all_entries


func get_unlocked_entries() -> Array[DiscoveryEntry]:
    var log: Dictionary = GameState.meta_save.get("discovery_log", {})
    var result: Array[DiscoveryEntry] = []
    for entry in _all_entries:
        if entry == null:
            continue
        if bool(log.get(String(entry.id), false)):
            result.append(entry)
    return result


func get_total_count() -> int:
    return _all_entries.size()


func get_unlocked_count() -> int:
    var log: Dictionary = GameState.meta_save.get("discovery_log", {})
    var count := 0
    for key in log.keys():
        if bool(log[key]):
            count += 1
    return count


func is_unlocked(entry_id: StringName) -> bool:
    var log: Dictionary = GameState.meta_save.get("discovery_log", {})
    return bool(log.get(String(entry_id), false))


# Idempotent unlock. Returns true if this call newly unlocked the entry.
func unlock(entry_id: StringName) -> bool:
    if not _entries_by_id.has(entry_id):
        push_warning("DiscoveryLog: unknown entry id %s" % String(entry_id))
        return false
    if is_unlocked(entry_id):
        return false
    var log: Dictionary = GameState.meta_save.get("discovery_log", {}) as Dictionary
    log[String(entry_id)] = true
    GameState.meta_save["discovery_log"] = log
    EventBus.discovery_unlocked.emit(entry_id)
    SaveSystem.save_now()
    return true


# Trigger lookup used by brief 06 wiring.
# Returns &"" if no entry matches.
func find_entry_for_trigger(category: StringName, trigger_id: StringName) -> StringName:
    var key := "%s:%s" % [String(category), String(trigger_id)]
    return _trigger_index.get(key, &"")
```

### Register `DiscoveryLog` as autoload
In `project.godot`, immediately after `PrestigeSystem`:
```
DiscoveryLog="*res://scripts/autoloads/discovery_log.gd"
```

### Extend `scripts/autoloads/event_bus.gd`
Under the `# Meta-progression` block (next to `evolution_node_unlocked`):
```gdscript
signal discovery_unlocked(entry_id: StringName)
```

Document in `ARCHITECTURE.md` under signals + system map.

## ARCHITECTURE.md updates

- **§4 (Data schema)**: append `DiscoveryEntry` and the EvolutionNodeData additions.
- **§5 (System map)**: add `DiscoveryLog` row, mirroring the `PrestigeSystem` entry.
- **§7 (Signals)**: add `discovery_unlocked(entry_id: StringName)`.
- **§9 (Save schema history)**: append v5 → v6 row.

## Acceptance criteria
- [ ] `EvolutionNodeData` schema loads with new fields visible in inspector; existing `.tres` files still load.
- [ ] `DiscoveryEntry` + `DiscoveryIndex` load in inspector.
- [ ] `DiscoveryLog` autoload registers and `_ready` runs without errors on an empty index.
- [ ] `EventBus.discovery_unlocked` signal declared (no emitters yet — brief 06 wires them).
- [ ] `DiscoveryLog.unlock(&"any_id")` on an empty index logs a warning and returns false; idempotent on repeat unlock of a real entry.
- [ ] `DiscoveryLog.get_total_count()` returns 0 with empty index.
- [ ] No gameplay changes — existing prestige flow unaffected.

## Out of scope
- Tagging existing nodes with wing/tier (brief 03).
- Authoring new nodes (brief 04).
- Tree-visualization UI (brief 05).
- Trigger wiring (brief 06).
- Discovery entry content (brief 07).
- Discovery log UI (brief 08).
- Enforcing `requires_kingdom_played` (brief 03).
