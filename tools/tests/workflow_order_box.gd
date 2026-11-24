extends "res://tools/tests/test_base.gd"

## Physical order box
##
## A packed order shows as a box on the packing bench. Leaving it at the
## delivery hatch moves the box to the hatch. Both visuals follow FarmState,
## which stays the only source of truth.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_order_box.tscn


func _init() -> void:
	suite_name = "workflow_order_box"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_order_box_follows_farm_state()


func _test_order_box_follows_farm_state() -> void:
	var farm = game.farm
	_ok(game.order_box_bench != null and game.order_box_hatch != null,
		"the bench and hatch each have an order box node")
	if game.order_box_bench == null or game.order_box_hatch == null:
		return

	# Start from an empty bench and hatch.
	farm.packed_box.clear()
	farm.delivered_box.clear()
	game._refresh_order_boxes()
	_ok(not game.order_box_bench.visible, "no box on the bench when nothing is packed")
	_ok(not game.order_box_hatch.visible, "no box at the hatch when nothing is delivered")

	# Pack a shutter order: the box appears on the bench only.
	farm.orders = [{
		"id": "test_box_rations",
		"buyer": "TEST BUYER",
		"product": "ration",
		"qty": 2,
		"min_grade": "C",
		"due_hour": farm.abs_hour() + 20.0,
		"pay_parts": 5,
		"pay_water": 1,
		"pay_standing": 3,
		"delivered": false,
		"special": false,
	}]
	farm.rations = 2
	var packed: String = str(farm.pack_for_order())
	_ok(not farm.packed_box.is_empty(), "packing creates a packed box", packed)
	await _frames(2)
	_ok(game.order_box_bench.visible, "the packed box shows on the bench", packed)
	_ok(not game.order_box_hatch.visible, "the hatch is empty while the box is on the bench")

	# Leave it at the hatch: the box moves from the bench to the hatch.
	var left: String = str(farm.leave_box())
	_ok(not farm.delivered_box.is_empty(), "leaving the box moves it to the hatch", left)
	await _frames(2)
	_ok(not game.order_box_bench.visible, "the bench is clear after the box is delivered")
	_ok(game.order_box_hatch.visible, "the delivered box shows at the hatch")

	# Collecting the delivered box clears the hatch visual.
	farm.delivered_box.clear()
	await _frames(2)
	_ok(not game.order_box_hatch.visible, "the hatch box clears once the box is gone")


func _frames(count: int) -> void:
	for _i in count:
		await game.get_tree().process_frame
