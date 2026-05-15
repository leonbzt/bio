extends Node2D
class_name Herbivore

@export var organism_id: int = 0
@export var species_id: StringName = &"herbivore"
@export var hp: float = 2.0
@export var coord: Vector2i = Vector2i.ZERO


func set_coord(new_coord: Vector2i, world_pos: Vector2) -> void:
	coord = new_coord
	position = world_pos


func take_damage(amount: float) -> float:
	hp = maxf(0.0, hp - amount)
	return hp


func is_dead() -> bool:
	return hp <= 0.0
