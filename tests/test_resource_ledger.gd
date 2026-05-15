extends GutTest

var _signals: Array = []


func before_each() -> void:
	_signals.clear()
	ResourceLedger.reset_run()
	EventBus.resource_changed.connect(_on_resource_changed)
	_signals.clear()


func after_each() -> void:
	if EventBus.resource_changed.is_connected(_on_resource_changed):
		EventBus.resource_changed.disconnect(_on_resource_changed)
	_signals.clear()


func _on_resource_changed(resource_id: StringName, new_amount: float) -> void:
	_signals.append({"id": resource_id, "amount": new_amount})


func test_add_emits_signal() -> void:
	ResourceLedger.add(ResourceLedger.BIOMASS, 5.0)
	assert_eq(_signals.size(), 1)
	assert_eq(_signals[0]["id"], ResourceLedger.BIOMASS)
	assert_eq(_signals[0]["amount"], 5.0)


func test_spend_insufficient_returns_false_no_mutation() -> void:
	ResourceLedger.add(ResourceLedger.BIOMASS, 2.0)
	_signals.clear()

	var ok := ResourceLedger.spend(ResourceLedger.BIOMASS, 3.0)
	assert_false(ok)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.BIOMASS), 2.0)
	assert_eq(_signals.size(), 0)


func test_spend_bundle_atomic_failure() -> void:
	ResourceLedger.add(ResourceLedger.BIOMASS, 2.0)
	ResourceLedger.add(ResourceLedger.NUTRIENTS, 1.0)
	_signals.clear()

	var ok := ResourceLedger.spend_bundle({
		ResourceLedger.BIOMASS: 2.0,
		ResourceLedger.NUTRIENTS: 2.0
	})
	assert_false(ok)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.BIOMASS), 2.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.NUTRIENTS), 1.0)
	assert_eq(_signals.size(), 0)


func test_reset_run_zeroes_all_known_resources() -> void:
	ResourceLedger.add(ResourceLedger.BIOMASS, 3.0)
	ResourceLedger.add(ResourceLedger.NUTRIENTS, 4.0)
	_signals.clear()

	ResourceLedger.reset_run()

	assert_eq(ResourceLedger.get_amount(ResourceLedger.BIOMASS), 0.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.NUTRIENTS), 0.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.SUNLIGHT), 0.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.DECAY), 0.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.SPORES), 0.0)
	assert_eq(ResourceLedger.get_amount(ResourceLedger.PRESSURE), 0.0)

	var ids := {}
	for entry in _signals:
		ids[entry["id"]] = true
	assert_eq(ids.size(), 6)
	assert_true(ids.has(ResourceLedger.BIOMASS))
	assert_true(ids.has(ResourceLedger.NUTRIENTS))
	assert_true(ids.has(ResourceLedger.SUNLIGHT))
	assert_true(ids.has(ResourceLedger.DECAY))
	assert_true(ids.has(ResourceLedger.SPORES))
	assert_true(ids.has(ResourceLedger.PRESSURE))
