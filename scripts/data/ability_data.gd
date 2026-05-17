class_name AbilityData
extends Resource
##
## A tap-targeted ability. Instances live in data/abilities/<id>.tres.
##

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

# StringName -> float. Spent on use via ResourceLedger.
@export var cost: Dictionary = {}

# Evolution-node id that unlocks this ability. Empty = always available.
@export var unlock_node_id: StringName = &""

# If non-empty, ability is only usable while this event is currently active.
@export var requires_event_active: StringName = &""

# Target mode for the input router.
@export var target_mode: StringName = &"target_tile"

# Effect radius in tiles.
@export var radius: int = 0

# Effect magnitude (ability-specific semantics).
@export var magnitude: float = 0.0

# Free-form extra payload merged into the EventBus.ability_used emission.
@export var extra_payload: Dictionary = {}
