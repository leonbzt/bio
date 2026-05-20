extends PanelContainer

var _species: SpeciesData = null

@onready var _title: Label = $Margin/VBox/Title
@onready var _desc: Label = $Margin/VBox/Description
@onready var _cost: Label = $Margin/VBox/Cost
@onready var _confirm: Button = $Margin/VBox/Actions/ConfirmButton
@onready var _cancel: Button = $Margin/VBox/Actions/CancelButton


func _ready() -> void:
	_cancel.pressed.connect(queue_free)
	_confirm.pressed.connect(_on_confirm)
	_refresh()


func setup(species: SpeciesData) -> void:
	_species = species
	_refresh()


func _refresh() -> void:
	if _species == null:
		_title.text = "Evolve"
		_desc.text = ""
		_cost.text = ""
		_confirm.disabled = true
		return
	var level: int = AdaptationSystem.get_level(_species.id)
	var cost: float = AdaptationSystem.get_next_level_cost(_species.id)
	_title.text = "%s - Lvl %d/3" % [_species.display_name, level]
	_desc.text = _species.description
	if cost < 0.0:
		_cost.text = "Max level reached"
		_confirm.disabled = true
		_confirm.text = "Max"
		return
	_cost.text = "Next level cost: %.0f Adaptation" % cost
	_confirm.disabled = not AdaptationSystem.can_level_up(_species.id)
	_confirm.text = "Evolve"


func _on_confirm() -> void:
	if _species == null:
		return
	if AdaptationSystem.level_up(_species.id):
		queue_free()
		return
	_refresh()
