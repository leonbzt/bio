# Brief 03 — Herbivore organism scene + script

**Suggested agent**: ChatGPT 5.2 via Copilot.

Read first:
1. `docs/ARCHITECTURE.md` § 6 (scene composition — Organisms node already exists in world.tscn).
2. `scripts/entities/tile_grid.gd` — for tile-to-world coordinate conversion (`map_to_local`, `to_global`).

## Goal
A herbivore organism: a Node2D scene with sprite, position, hp, and id. Stateless about *what to do* — that's HerbivoreManager (brief 04). This brief just produces the scene + a thin script for it.

## Outputs (create)
- `scenes/organisms/herbivore.tscn`
- `scripts/entities/herbivore.gd`
- `assets/art/organisms/placeholder_herbivore.png` — 12×12 PNG, a solid contrasting color (e.g. amber `#d99a3a`) with a 1px darker border. Generate with whatever you've got; quality doesn't matter for Phase 3.

## Scene structure
```
Herbivore (Node2D, script attached)
└── Sprite (Sprite2D, texture = placeholder_herbivore.png, centered)
```

## Script: `scripts/entities/herbivore.gd`
```gdscript
extends Node2D
class_name Herbivore

@export var organism_id: int = 0
@export var species_id: StringName = &"herbivore"
@export var hp: float = 2.0
@export var coord: Vector2i = Vector2i.ZERO

# Per-tick lifecycle is driven by HerbivoreManager via these public methods:
func set_coord(new_coord: Vector2i, world_pos: Vector2) -> void:
    coord = new_coord
    position = world_pos

func take_damage(amount: float) -> float:
    hp = maxf(0.0, hp - amount)
    return hp

func is_dead() -> bool:
    return hp <= 0.0
```

No `_process`, no `_ready` connections to EventBus. This script holds state; the manager drives behavior.

## Acceptance criteria
- [ ] `scenes/organisms/herbivore.tscn` instantiates without errors.
- [ ] Setting `coord = Vector2i(5, 7)` and `position` from `tile_grid.map_to_local(Vector2i(5,7))` places the sprite over that tile.
- [ ] `take_damage(1.0)` reduces hp; `is_dead()` returns true at hp = 0.
- [ ] No EventBus subscriptions in `herbivore.gd`.

## Out of scope
- Movement, targeting, eating — all in HerbivoreManager (brief 04).
- Death animation. Phase 7 polish.
- Multiple herbivore types. Just one for Phase 3.
