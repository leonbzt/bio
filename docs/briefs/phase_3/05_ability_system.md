# Brief 05 — AbilitySystem + ToxinBloom + input mode

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` § 3 (signals: `tile_tapped`, `input_mode_changed`, `ability_used`), § 5 (AbilitySystem row), § 7 (input model).
2. `scripts/autoloads/game_state.gd` — `input_mode` field and `INPUT_MODE_COLONIZE` constant.
3. `scripts/systems/territory_system.gd` — needs a one-line patch to skip when input_mode != colonize.

## Goal
Introduce a generic ability-targeting system. Phase 3 wires only ToxinBloom, but the structure should support more abilities later.

Player flow:
1. Tap **Toxin Bloom** button on HUD.
2. AbilitySystem sets `GameState.input_mode = &"target_toxin_bloom"`, emits `input_mode_changed`.
3. HUD changes the world cursor / dims tiles outside the bloom radius hint (visual hint optional this phase).
4. Player taps a tile. `tile_tapped` fires.
5. AbilitySystem consumes the tap (because it's in targeting mode), validates the tile, spends biomass (50), emits `ability_used(&"toxin_bloom", {coord, radius_tiles, damage})`, returns mode to `&"colonize"`.
6. HerbivoreManager (brief 04) handles the actual damage.
7. If player taps the button again while already in targeting mode, OR taps it twice rapidly: cancel.

TerritorySystem must NOT colonize on `tile_tapped` when mode != colonize.

## Outputs (create)
- `scripts/systems/ability_system.gd`
- Modification to `scripts/systems/territory_system.gd` — gate `_on_tile_tapped` on input mode (see patch below).
- Modification to `scenes/world/world.tscn` — add `AbilitySystem` node under `Systems`, after `HerbivoreManager`.

## TerritorySystem patch
At the top of `_on_tile_tapped`:
```gdscript
func _on_tile_tapped(coord: Vector2i) -> void:
    if GameState.input_mode != GameState.INPUT_MODE_COLONIZE:
        return
    # ... rest unchanged
```

## AbilitySystem implementation

### Constants
```gdscript
const TOXIN_BLOOM_ID: StringName = &"toxin_bloom"
const TOXIN_BLOOM_TARGET_MODE: StringName = &"target_toxin_bloom"
const TOXIN_BLOOM_COST: Dictionary = {ResourceLedger.BIOMASS: 50.0}
const TOXIN_BLOOM_RADIUS: int = 3            # Manhattan tiles
const TOXIN_BLOOM_DAMAGE: float = 3.0
# TODO Phase 4+: move into AbilityData resource files
```

### State
```gdscript
var _pending_ability: StringName = &""
```

### `_ready()`
- Connect `EventBus.tile_tapped.connect(_on_tile_tapped)`.

### Public methods
```gdscript
func request_toxin_bloom() -> bool:
    # Called from HUD when the button is tapped.
    if _pending_ability == TOXIN_BLOOM_ID:
        cancel_pending()  # toggle off
        return false
    if not ResourceLedger.can_afford(TOXIN_BLOOM_COST):
        return false  # HUD should grey out the button when this returns false repeatedly
    _set_mode(TOXIN_BLOOM_TARGET_MODE, TOXIN_BLOOM_ID)
    return true


func cancel_pending() -> void:
    _set_mode(GameState.INPUT_MODE_COLONIZE, &"")
```

### `_on_tile_tapped(coord)`
- If `_pending_ability != TOXIN_BLOOM_ID`: return.
- Validate tile is in grid bounds (TileInputRouter already does this, but defensive).
- `if not ResourceLedger.spend_bundle(TOXIN_BLOOM_COST): cancel_pending(); return`.
- Build payload:
  ```gdscript
  var payload := {
      "coord": coord,
      "radius_tiles": TOXIN_BLOOM_RADIUS,
      "damage": TOXIN_BLOOM_DAMAGE
  }
  ```
- Emit `EventBus.ability_used.emit(TOXIN_BLOOM_ID, payload)`.
- `cancel_pending()` to return mode to colonize.

### `_set_mode(mode, ability_id)`
Internal helper:
```gdscript
func _set_mode(mode: StringName, ability_id: StringName) -> void:
    if GameState.input_mode == mode and _pending_ability == ability_id:
        return
    GameState.input_mode = mode
    _pending_ability = ability_id
    EventBus.input_mode_changed.emit(mode)
```

### Public read for HUD
```gdscript
func get_toxin_bloom_cost() -> Dictionary:
    return TOXIN_BLOOM_COST
```
HUD uses this to display "Toxin Bloom (50 Biomass)" without hardcoding the number.

## Acceptance criteria
- [ ] Tapping the Toxin Bloom button (added in brief 06) sets `GameState.input_mode == &"target_toxin_bloom"`; tile taps no longer colonize.
- [ ] Tapping a valid tile while in targeting mode spends 50 biomass and emits `ability_used` with the right payload.
- [ ] Insufficient biomass: button does nothing (or HUD greys it out — depends on brief 06 wiring).
- [ ] Tapping the button twice cancels targeting mode.
- [ ] After ability use, mode returns to `&"colonize"` automatically.
- [ ] No direct system imports beyond autoloads.

## Out of scope
- Visual targeting hints (radius preview overlay). Nice-to-have, defer.
- Other abilities. Brief structure already supports adding them; do them in later phases.
- AbilityData resources. Inline constants are fine until Phase 4's KingdomData refactor.
