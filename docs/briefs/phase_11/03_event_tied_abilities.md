# Brief 03 — Event-tied abilities + evolution nodes + HUD ability bar

**Suggested agent**: Kilo for the `.tres` data (mechanical), ChatGPT 5.2 for the HUD + system hooks. Route diff to Claude.

Read first:
1. `docs/briefs/phase_11/02_ability_data_generalization.md` (must land first).
2. `scripts/systems/ambient_modifier_system.gd` — drought/cool_spell handler.
3. `scripts/systems/spore_infection_handler.gd` — spore_infection handler.
4. `scenes/ui/hud.tscn` (or wherever the Toxin Bloom button currently lives).
5. `data/events/drought.tres`, `cool_spell.tres`, `spore_infection.tres` for payloads.

## Goal
Three new abilities + the three evolution nodes that unlock them + HUD ability bar that lists currently-usable abilities. Each ability mitigates a specific passive event when active.

| Ability | Event required | Unlock node | What it does |
|---|---|---|---|
| **Irrigate** | `drought` | `deep_roots` (plantae) | Tap a tile: 3-tile-radius AOE that grants +5 nutrients per affected owned tile, costs 30 biomass. |
| **Bundle** | `cool_spell` | `cold_tolerance` (fungi) | Tap a tile: that tile and its 4 neighbors get a temporary "warmed" tag (10s); warmed tiles ignore cool_spell yield reduction. Cost 20 decay. |
| **Cull** | `spore_infection` | `quarantine` (fungi) | Tap a tile: removes spore_infection's spread effect from that tile + neighbors (clears the tile from the spread set). Cost 15 spores. |

## Part 1 — Author ability `.tres` files

### `data/abilities/irrigate.tres`
```
[gd_resource type="Resource" script_class="AbilityData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/ability_data.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"irrigate"
display_name = "Irrigate"
description = "Channel reserves into the soil during drought. +5 nutrients per owned tile in radius."
cost = {"biomass": 30.0}
unlock_node_id = &"deep_roots"
requires_event_active = &"drought"
target_mode = &"target_tile"
radius = 3
magnitude = 5.0
extra_payload = {}
```

### `data/abilities/bundle.tres`
```
[resource]
script = ExtResource("1")
id = &"bundle"
display_name = "Bundle"
description = "Cluster mycelium around a hyphal node. Warmed tiles ignore cool spell yield reduction for 10 seconds."
cost = {"decay": 20.0}
unlock_node_id = &"cold_tolerance"
requires_event_active = &"cool_spell"
target_mode = &"target_tile"
radius = 1
magnitude = 10.0    # seconds of warmth
extra_payload = {"effect": "warm"}
```

### `data/abilities/cull.tres`
```
[resource]
script = ExtResource("1")
id = &"cull"
display_name = "Cull"
description = "Burn out infected tissue. Removes spore infection from a 1-tile radius."
cost = {"spores": 15.0}
unlock_node_id = &"quarantine"
requires_event_active = &"spore_infection"
target_mode = &"target_tile"
radius = 1
magnitude = 0.0
extra_payload = {"effect": "quarantine"}
```

### Extend `data/abilities/_index.tres`

Append the three new ext_resource lines and add to the `abilities` array. Final count = 4.

## Part 2 — Three new evolution nodes

### `data/evolution_tree/deep_roots.tres`
- id: `&"deep_roots"`, display: "Deep Roots"
- description: "Plant roots reach water reservoirs the surface forgets. Unlocks Irrigate during droughts."
- prerequisites: `[&"pioneer_resilience"]`
- meta_cost: `{"evolution_points": 8}`
- wing: `&"plantae"`, tier: 2
- requires_kingdom_played: `[]`

### `data/evolution_tree/cold_tolerance.tres`
- id: `&"cold_tolerance"`, display: "Cold Tolerance"
- description: "Hyphae cluster against the cold and survive what the warm world cannot. Unlocks Bundle during cool spells."
- prerequisites: `[&"unlock_fungi"]`
- meta_cost: `{"evolution_points": 8}`
- wing: `&"fungi"`, tier: 2
- requires_kingdom_played: `[]`

### `data/evolution_tree/quarantine.tres`
- id: `&"quarantine"`, display: "Quarantine"
- description: "The network learns to amputate. Unlocks Cull during spore infections."
- prerequisites: `[&"saprophytic_efficiency_ii"]`
- meta_cost: `{"evolution_points": 10}`
- wing: `&"fungi"`, tier: 3
- requires_kingdom_played: `[]`

### Extend `data/evolution_tree/_index.tres`

Append three ext_resource lines; add to the `nodes` array. Final count = 24 (was 22 after Phase 9 + 11 stub-resource nodes count if Phase 10 added any, adjust accordingly).

## Part 3 — System hooks for the ability effects

### Irrigate — extend `NutrientSystem` or add a one-shot handler

Easiest: extend `ambient_modifier_system.gd` with a listener for `EventBus.ability_used`:

```gdscript
func _on_ability_used(id: StringName, payload: Dictionary) -> void:
    if id != &"irrigate":
        return
    var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
    var radius: int = int(payload.get("radius_tiles", 0))
    var per_tile_nutrients: float = float(payload.get("magnitude", 0.0))
    var territory: Node = get_node_or_null("../TerritorySystem")
    if territory == null:
        return
    var owned: Array[Vector2i] = territory.get_surface_owned_coords()
    var total: float = 0.0
    for c in owned:
        if abs(c.x - coord.x) + abs(c.y - coord.y) <= radius:
            total += per_tile_nutrients
    if total > 0.0:
        ResourceLedger.add(ResourceLedger.NUTRIENTS, total)
```

Connect in `_ready`: `EventBus.ability_used.connect(_on_ability_used)`.

### Bundle — extend `GrowthSystem` to honor a per-tile "warmed" tag

Bundle writes a `tile.data["warmed_until_unix"] = Time.get_unix_time_from_system() + magnitude` for the targeted coord + its 4 neighbors via `TerritorySystem.set_tile_data`. Add a handler in `growth_system.gd`:

```gdscript
func _on_ability_used(id: StringName, payload: Dictionary) -> void:
    if id != &"bundle":
        return
    var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
    var duration: float = float(payload.get("magnitude", 0.0))
    var until: int = int(Time.get_unix_time_from_system() + duration)
    for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        _territory.set_tile_data(coord + offset, "warmed_until_unix", until)
```

In `_apply_yields`, when reading `sun_mult` for plantae or `decay_per_tile` for fungi, check if the tile is "warmed" — if so, skip the cool_spell multiplier:

```gdscript
var is_warmed: bool = false
var until: int = int(_territory.get_tile_data(coord, "warmed_until_unix", 0))
if until > int(Time.get_unix_time_from_system()):
    is_warmed = true
# When applying cool_spell-driven multipliers, replace mult with 1.0 if is_warmed.
```

(Concrete integration depends on how `AmbientModifierSystem`'s mult is plumbed into yield calc. Either: (a) read the per-tile `warmed` and divide back out the cool_spell contribution; or (b) push the warmed-tile check into `AmbientModifierSystem.get_multiplier(key, coord)` and pass coord to the call site. (b) is cleaner — extend the helper.)

### Cull — extend `spore_infection_handler.gd`

Add a listener that records "culled" tiles per-event and skips them in `_try_spread_one`:

```gdscript
var _culled_set: Dictionary = {}  # Vector2i -> true; cleared on event_started

func _on_event_started(event_id, payload):
    if event_id != EVENT_ID:
        return
    # ... existing reset ...
    _culled_set.clear()

func _on_ability_used(id, payload):
    if id != &"cull":
        return
    var coord: Vector2i = payload.get("coord", Vector2i.ZERO)
    var radius: int = int(payload.get("radius_tiles", 0))
    for dx in range(-radius, radius + 1):
        for dy in range(-radius, radius + 1):
            _culled_set[Vector2i(coord.x + dx, coord.y + dy)] = true

# In _try_spread_one, skip neighbors in _culled_set.
```

Connect in `_ready`: `EventBus.ability_used.connect(_on_ability_used)`.

## Part 4 — HUD ability bar

### `scripts/ui/hud.gd` (or wherever the Toxin Bloom button lives)

Replace the single Toxin Bloom button with a horizontal `HBoxContainer` of ability buttons. On `_ready` and on every `EventBus.tick`, rebuild the visible button set:

```gdscript
@onready var _abilities_bar: HBoxContainer = $AbilitiesBar
@onready var _ability_system: Node = get_node("/root/World/Systems/AbilitySystem")
# ^ adjust path to actual

var _buttons_by_id: Dictionary[StringName, Button] = {}


func _ready() -> void:
    # ... existing setup ...
    EventBus.tick.connect(_refresh_abilities)
    EventBus.event_started.connect(func(_id, _p): _refresh_abilities(0.0))
    EventBus.event_resolved.connect(func(_id, _o): _refresh_abilities(0.0))
    EventBus.evolution_node_unlocked.connect(func(_id): _refresh_abilities(0.0))
    _refresh_abilities(0.0)


func _refresh_abilities(_delta: float) -> void:
    var usable: Array[AbilityData] = _ability_system.get_usable_abilities()
    var seen_ids: Dictionary = {}
    for ability in usable:
        seen_ids[ability.id] = true
        if not _buttons_by_id.has(ability.id):
            var b := Button.new()
            b.text = ability.display_name
            b.pressed.connect(func() -> void: _ability_system.request_ability(ability.id))
            _abilities_bar.add_child(b)
            _buttons_by_id[ability.id] = b
        # Cost-affordability is handled inside is_ability_usable; just toggle disabled state.
        _buttons_by_id[ability.id].disabled = false
    # Remove buttons for abilities no longer usable.
    for id in _buttons_by_id.keys():
        if not seen_ids.has(id):
            _buttons_by_id[id].queue_free()
            _buttons_by_id.erase(id)
```

The `_refresh_abilities(0.0)` on every tick is heavy; debounce to once per second if needed (cache `last_refresh_unix`).

## Acceptance criteria
- [ ] Cold load: only Toxin Bloom shows in the ability bar during plantae runs (others gated by event + unlock).
- [ ] Buy `deep_roots`. Plantae run. Trigger drought. Irrigate button appears in the bar. Drought resolves → button disappears.
- [ ] Tap Irrigate → tap a tile. 30 biomass spent; nutrient ticker visibly jumps by `(owned_tiles_in_radius) × 5`.
- [ ] Buy `cold_tolerance`. Fungi run. Trigger cool spell. Bundle button appears. Tap it → tap tile. 20 decay spent. Targeted tile + 4 neighbors are "warmed" for 10 sec; their yields are not reduced.
- [ ] Buy `quarantine`. Fungi run. Trigger spore infection. Cull button appears. Tap → tile. 15 spores spent. That tile and 1-radius do not spread further during this event.
- [ ] Bumping `toxin_potency` still increases Toxin Bloom damage (regression).
- [ ] Buttons honor cost-can-afford: button is disabled (greyed) when the player can't pay.
- [ ] Performance: HUD refresh runs every tick without measurable frame drop.

## Out of scope
- Cooldowns (not in scope; cost-gating is enough).
- Per-ability potency upgrades (only `toxin_potency` exists; new ones can land in Phase 12+).
- Ability-target-mode previews (showing the AOE radius on hover before tap). Defer to polish.
- Per-niche signature mechanic abilities (Phase 10 lands those — e.g., parasite plantae's "Drain" tap).
