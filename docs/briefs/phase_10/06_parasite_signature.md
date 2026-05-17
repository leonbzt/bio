# Brief 06 — Parasite plantae signature mechanic (biomass-steal)

**Suggested agent**: ChatGPT 5.2 via Copilot. Route diff to Claude — balance + GrowthSystem touch.

Read first:
1. `docs/briefs/phase_10/02_schema_extensions.md` (`NicheData.parasitic_targets` is the contract).
2. `scripts/systems/growth_system.gd:190` — current parasite multiplier (`_get_niche_yield_multiplier` returning 2.0).
3. `scripts/systems/parasite_decay_system.gd` — the existing parasite-tile decay system (already wired).
4. `data/niches/parasitic_plantae.tres` — niche data file to update.
5. Phase 9 mechanics-vs-vision review (gap 1) — the rationale for replacing the flat 2× with a steal mechanic.

## Goal

Replace parasite plantae's flat 2× yield multiplier with a **biomass-steal tick effect** that makes the niche *feel* parasitic. Per-tick:
- For each parasite-owned tile, count adjacent tiles whose owner kingdom is in the niche's `parasitic_targets` list (plantae + fungi for v1).
- Each such neighbor *loses* a small amount of biomass that the parasite cluster *gains*.
- Net: parasite runs that grow adjacent to other-niche owned tiles compound rapidly; isolated parasite runs (no neighbors to steal from) suffer.

Combined with the existing `parasite_decay_system` (parasite tiles wither if they have < 2 neighbors for 30 ticks), the niche identity becomes: **build dense clusters next to other living tiles, or wither**.

## Mechanic numbers

| Parameter | Value | Notes |
|---|---|---|
| Steal per neighbor per tick | 0.15 biomass | Tunable; brief 12 smoke-test will validate feel |
| Steal cap per parasite tile per tick | 0.5 biomass | Prevents super-dense parasite clusters from instantly draining a single neighbor |
| Source-tile minimum-balance protection | Source can't be drained below 0 biomass | Self-evident |
| Yield from photosynthesis still applies | Yes | Parasite tiles still produce ambient biomass via biome rules (no double penalty if there's nothing to steal) |

## Required runtime state

The steal needs to know:
- Which tiles are parasite-owned (already known via `TerritorySystem.get_surface_owned_coords(&"plantae")` when `current_niche_id == &"parasitic_plantae"`).
- Which adjacent tiles are valid steal targets (plantae of other niches, fungi).

For v1: since the player can only run ONE niche at a time, "adjacent tiles owned by another niche" simplifies to "adjacent tiles owned by fungi from the SAME run (if Lichen) OR a previous-prestige's tile history (when tile history lands later)". Since neither is generally true in Phase 10 (Lichen is fungi-niche, not parasite-plantae), the steal-from-plantae case applies only when:
- A Lichen run is active and parasite plantae is *also* somehow active — but only one niche per run, so this doesn't happen.

**Resolution**: in Phase 10, parasitic_targets includes both plantae and fungi BUT effectively only fungi neighbors exist in a parasite plantae run (the player's own tiles are all parasite plantae; other niches' tiles don't exist alongside). The steal happens primarily against:
- Fungi tiles from previous runs that survived migration (not common but possible via Lichen runs leaving fungi tiles in tile_history when that lands)
- Future Phase 14+ multi-niche-per-run scenarios

For now, the mechanic is implemented and tested as a **passive system that will activate in richer scenarios**. The smoke test should confirm:
- A parasite plantae run alone yields about as much as photosynthesizer (slight nerf from removing the 2×, balanced against ambient passive yield)
- A scenario where a fungi tile is adjacent → biomass steal is observed
- The parasite_decay_system still withers isolated tiles

This is acceptable: the *mechanic* is in place and correct; the *content* that makes it shine (multi-niche-tile scenarios) lands later. Compared to the flat 2× (which felt fine but generic), the new mechanic is *honest* — parasite plantae is now mechanically parasitic, not just numerically boosted.

## Implementation

### Update `data/niches/parasitic_plantae.tres`

```
parasitic_targets = [&"plantae", &"fungi"]
```

### New system: `scripts/systems/parasite_steal_system.gd`

Lives under `World/Systems/`. Subscribes to tick. Active only when `current_niche_id == &"parasitic_plantae"`.

```gdscript
extends Node
##
## ParasiteStealSystem — drains biomass from neighboring non-parasite tiles
## each tick, granting it to the parasite cluster. Implements the parasite
## plantae signature mechanic (Phase 10).
##

const STEAL_PER_NEIGHBOR_PER_TICK: float = 0.15
const STEAL_CAP_PER_TILE_PER_TICK: float = 0.5

@onready var _territory: Node = get_node("../TerritorySystem")
var _is_replaying: bool = false


func _ready() -> void:
    EventBus.tick.connect(_on_tick)
    EventBus.replay_started.connect(func(_n): _is_replaying = true)
    EventBus.replay_finished.connect(func(): _is_replaying = false)


func _on_tick(_delta: float) -> void:
    if _is_replaying:
        return
    if GameState.current_niche_id != &"parasitic_plantae":
        return
    var targets: Array[StringName] = _get_parasitic_targets()
    if targets.is_empty():
        return

    var parasite_tiles: Array[Vector2i] = _territory.get_surface_owned_coords(&"plantae")
    var total_gained: float = 0.0
    for coord in parasite_tiles:
        var per_tile_gain: float = 0.0
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var neighbor: Vector2i = coord + offset
            var owner: StringName = _territory.get_surface_owner(neighbor)
            var sub_owner: StringName = _territory.get_subsurface_owner(neighbor)
            # Skip parasite neighbors (own kingdom + same niche).
            # In Phase 10, all of OUR plantae tiles ARE parasite, so any plantae
            # neighbor is one of ours. Skip them.
            if owner == &"plantae":
                continue
            # Check surface owner against parasitic_targets.
            if owner != &"" and targets.has(owner):
                per_tile_gain += STEAL_PER_NEIGHBOR_PER_TICK
            # Same for subsurface owner.
            if sub_owner != &"" and targets.has(sub_owner):
                per_tile_gain += STEAL_PER_NEIGHBOR_PER_TICK
            if per_tile_gain >= STEAL_CAP_PER_TILE_PER_TICK:
                per_tile_gain = STEAL_CAP_PER_TILE_PER_TICK
                break
        total_gained += per_tile_gain
    if total_gained > 0.0:
        ResourceLedger.add(ResourceLedger.BIOMASS, total_gained)


func _get_parasitic_targets() -> Array[StringName]:
    var index := load("res://data/niches/_index.tres")
    if index == null or not (index is NicheIndex):
        return []
    for niche in (index as NicheIndex).niches:
        if niche != null and niche.id == &"parasitic_plantae":
            return niche.parasitic_targets
    return []
```

Register in `world.tscn` Systems group, after `ParasiteDecaySystem`.

### Remove the flat 2× multiplier in `growth_system.gd`

Replace:
```gdscript
func _get_niche_yield_multiplier() -> float:
    if GameState.current_niche_id == &"parasitic_plantae":
        return 2.0
    return 1.0
```

With:
```gdscript
func _get_niche_yield_multiplier() -> float:
    # Parasitic plantae no longer gets a flat 2x — see ParasiteStealSystem
    # for the replacement signature mechanic (Phase 10).
    return 1.0
```

Or delete the function entirely if it has no other callers (verify with a grep).

### Note: source tile biomass is global, not per-tile

The "drain from source" wording above is aspirational — biomass is a single per-run pool, not a per-tile pool. The mechanic above adds to the parasite player's biomass without reducing anything (because the "neighbor" is a fungi tile, not the player's tile — its biomass is in the same pool).

If a Phase 14+ scenario introduces multiple kingdoms with *separate* biomass pools (e.g., cross-niche multi-player scenarios), this brief's `_get_parasitic_targets` filtering would naturally extend. For Phase 10, the mechanic is **additive** — parasite gains biomass without source loss because there's only one pool.

**This is a deliberate Phase 10 simplification.** The vision's "parasitic = adversarial" framing is partially deferred. What this brief delivers:
- The mechanic is wired and tested.
- The data field (`parasitic_targets`) is contract-ready.
- The numbers (0.15/neighbor/tick capped at 0.5/tile/tick) give parasite plantae *some* meaningful boost when adjacent to fungi (e.g., a Lichen leftover or a multi-niche scenario).
- Future phases can extend to actual biomass-drain when there's a meaningful source-pool to drain from.

## Acceptance criteria
- [ ] `parasitic_plantae` niche `parasitic_targets` set to `[&"plantae", &"fungi"]`.
- [ ] `ParasiteStealSystem` runs on tick when active niche is parasite plantae.
- [ ] No-op when active niche is anything else.
- [ ] Pure parasite-plantae run (no fungi neighbors): biomass ticks ~ same as photosynthesizer (no flat 2× anymore, no steal income).
- [ ] Manually create a save with a parasite plantae tile adjacent to a fungi tile (dev cheat): biomass ticks faster by 0.15/tick per such neighbor.
- [ ] Regression: parasite_decay_system still withers isolated tiles after 30 ticks (unchanged).
- [ ] No regression in plantae photosynthesizer yields.

## Out of scope
- Reducing source-pool biomass (deferred — there's only one pool).
- Per-species parasitic target overrides (Phase 14+).
- Cordyceps fungi parasite signature (Phase 14 — separate niche, separate signature).
- Visual feedback when a steal happens (a brief tile-edge pulse would sell the mechanic but is polish; defer).
