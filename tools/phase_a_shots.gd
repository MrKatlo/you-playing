extends Node

const OUT := "res://tools/shots/phase_a/"
var game

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _stage(foot: Vector3, target: Vector3) -> void:
	game.player.global_position = foot
	game.player.velocity = Vector3.ZERO
	game.player.head.rotation = Vector3.ZERO
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	game.player.camera.look_at(target)
	# Match the actual body/head axes; physics maintains these each frame.
	var direction: Vector3 = target - game.player.camera.global_position
	game.player.rotation.y = atan2(-direction.x, -direction.z)
	game.player.head.rotation.x = atan2(direction.y, Vector2(direction.x, direction.z).length())
	game.player.camera.rotation = Vector3.ZERO
	await _frames(8)


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	var result := frame.save_png(ProjectSettings.globalize_path(OUT + label + ".png"))
	print("PHASE A SHOT ", label, " result=", result)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = preload("res://scenes/basement.tscn").instantiate()
	add_child(game)
	game.new_shift(false)
	game.menu.close_menu()
	game.opening_state = ""
	game.farm.temperature = 20.0
	game.player.set_flashlight_acquired(true)
	game.player.set_flashlight_enabled(true)
	await _stage(Vector3(4.55, 0, -3.3), game.bulkhead_crank.global_position)
	await _shot("01_crank")
	Input.action_press("interact")
	await _frames(30)
	await _shot("02_crank_turning")
	Input.action_release("interact")
	await _frames(30)
	game.farm.story.stage = StoryState.STAGE_CHAIN_SNAPPED
	game.farm.story.chain_broken = true
	game.farm.chain_links = 1
	game.player.set_link_carried(true)
	game.player.select_slot(game.player.SLOT_LINK)
	await _stage(Vector3(4.75, 0, -0.62), game.shutter_lever.global_position)
	await _shot("03_broken_chain_held_link")
	game.player_interact()
	await _frames(22)
	await _shot("04_fitting_link")
	await get_tree().create_timer(1.0).timeout
	await _shot("05_repaired_chain")
	game.farm.chain_links = 1
	game.player.set_link_carried(true)
	game.player.select_slot(game.player.SLOT_LINK)
	await _stage(Vector3(0, 0, 0), Vector3(0, 0, -0.65))
	game._drop_held_chain_link()
	await _frames(5)
	await _shot("06_recoverable_link")
	get_tree().quit()
