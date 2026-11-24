extends Node

## Render the production rail route without desktop control or player-save writes.
const BASEMENT := preload("res://scenes/basement.tscn")
const Hunter := preload("res://scripts/echo_hunter.gd")
const OUT := "res://tools/shots/rail/"
var game
var camera: Camera3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = BASEMENT.instantiate()
	add_child(game)
	await _frames(8)
	game.new_shift(false)
	game.menu.close_menu()
	game.finish_opening_sequence_for_test()
	game.opening_state = "complete"
	game.farm.story.stage = game.farm.story.STAGE_HANDOFF
	game.farm.rail.data.unlocked = true
	game.farm.rail.data.repair_stage = 1
	game.farm.rail.data.cart_durability = 100
	game.player.set_cinematic_locked(true)
	game.rail.controls_enabled = false
	game.rail.encounters_enabled = false
	camera = Camera3D.new()
	camera.fov = 72
	add_child(camera)
	camera.make_current()
	await _stage(Vector3(24, 1.75, -4.7), Vector3(28.6, .9, -7))
	await _shot("01_corridor_platform")
	await _stage(Vector3(27.8, 1.65, -6.9), Vector3(31.4, 1.0, -4.3))
	await _shot("02_safety_panel")
	game.rail.cart.distance = 22
	game.rail.cart.place()
	game.rail.cart.toggle_headlight()
	await _stage(Vector3(47, 1.65, -7), Vector3(61, 1.5, -7))
	await _shot("03_flooded_outbound")
	game.farm.rail.data.first_ride_completed = true
	game.rail.world.refresh(game.farm.rail.data)
	await _stage(Vector3(66.1, 1.7, -6.7), Vector3(66, .95, -4.4))
	await _shot("04_pocket_exchange")
	game.menu.open_rail("rail_terminal")
	await _frames(3)
	await _shot("05_terminal_menu")
	game.menu.close_menu()
	game.farm.rail.data.station_restored = true
	game.farm.rail.data.safety_switches = [true, true, true]
	game.farm.rail.data.safety_restored = true
	game.farm.rail.data.motor_upgraded = true
	game.rail.world.refresh(game.farm.rail.data)
	await _stage(Vector3(70, 1.65, -6.7), Vector3(74, 1.0, -4.3))
	await _shot("06_restored_workshop")
	var hunter := Hunter.new()
	game.rail.add_child(hunter)
	hunter.position = Vector3(56, 0, -18.6)
	hunter.look_at(Vector3(61, 1, -19))
	game.rail.cart.distance = 94
	game.rail.cart.place()
	await _stage(Vector3(60, 1.6, -19), Vector3(56, 1.25, -18.6))
	await _shot("07_return_hunter")
	await _stage(Vector3(21.9, 1.65, -2.2), Vector3(22, 1.2, -4.8))
	await _shot("09_cave_rail_entrance")
	await _stage(Vector3(70, 1.65, -.1), Vector3(70, 1.1, -5.5))
	await _shot("10_pocket_platform_access")
	game.rail.cart.distance = 20
	game.rail.cart.place()
	game.player.global_position = game.rail.cart.position
	game.rail.cart.speed = 0
	game.rail.board()
	game.player.camera.make_current()
	await _frames(6)
	await _shot("08_cart_first_person")
	print("RAIL SCREENSHOTS: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _stage(point: Vector3, target: Vector3) -> void:
	game.player.global_position = point - Vector3(0, 1.5, 0)
	camera.global_position = point
	camera.look_at(target)
	game.message_label.text = ""
	game.rail.warning_label.text = ""
	await _frames(10)

func _frames(count: int) -> void:
	for i in count: await get_tree().process_frame

func _shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + filename + ".png"))
	print(filename, ": ", result)
	assert(result == OK)
