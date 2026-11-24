extends Node

## Shared base for the modular Basement Farm test suites.
##
## Every suite in tools/tests/ extends this script, implements run_phases(), and
## can be launched on its own:
##
##   Godot --headless --path . res://tools/tests/workflow_crafting.tscn
##
## or driven in one batch by tools/tests/run_tests.tscn.
##
## The base owns the parts every suite needs: the real production scene, the
## assertion counter, per-step failure records (step, expected, actual), per-case
## timing, a hard timeout, and a machine-readable report. Gameplay procedure stays
## in the suites; nothing here fakes an action.

const BASEMENT_SCENE: PackedScene = preload("res://scenes/basement.tscn")
const REPORT_DIR := "res://tools/test_reports"
const DEFAULT_TIMEOUT_SECONDS := 360.0

## Set by the batch runner before the suite is added to the tree. A suite started
## from its own scene keeps this true and runs itself.
var auto_run := true

var suite_name := "suite"
var suite_level := "workflow"
## Level 1 suites test the models directly and never instantiate the game scene.
var needs_scene := true

var checks := 0
var fails := 0

## Real production nodes. Suites drive these; they are never stand-ins.
var game
var player
var farm

var timeout_seconds := DEFAULT_TIMEOUT_SECONDS

var _started_ms := 0
var _case_id := ""
var _case_name := ""
var _case_started_ms := 0
var _case_checks := 0
var _case_fails := 0
var _failures: Array[Dictionary] = []
var _case_timings: Array[Dictionary] = []
var _boot_ms := 0
var _watchdog: Timer
var _finished := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_started_ms = Time.get_ticks_msec()
	_watchdog = Timer.new()
	_watchdog.one_shot = true
	_watchdog.wait_time = maxf(1.0, timeout_seconds)
	_watchdog.timeout.connect(_on_timeout)
	add_child(_watchdog)
	if auto_run:
		_watchdog.start()
		_run_standalone.call_deferred()


## Overridden by every suite: the gameplay procedures it owns, in order.
func run_phases() -> void:
	push_error("%s does not implement run_phases()" % suite_name)


# ------------------------------------------------------------------ assertions

## Record one check. A suite is not "passed" because it reached the end: every
## behaviour a phase claims to prove goes through here.
func _ok(condition: bool, label: String, detail: String = "") -> void:
	checks += 1
	_case_checks += 1
	if condition:
		print("  PASS  ", label)
		return
	fails += 1
	_case_fails += 1
	print("  FAIL  ", label, "  ", detail)
	_failures.append({
		"suite": suite_name,
		"case": _case_id,
		"case_name": _case_name,
		"step": label,
		"expected": "condition true",
		"actual": detail if detail != "" else "false with no detail",
	})


## Equality check with both sides recorded, for the cases where "what came out"
## matters more than "the boolean was false".
func _eq(actual_value: Variant, expected_value: Variant, label: String) -> void:
	var passed: bool = typeof(actual_value) == typeof(expected_value) and actual_value == expected_value
	checks += 1
	_case_checks += 1
	if passed:
		print("  PASS  ", label)
		return
	fails += 1
	_case_fails += 1
	print("  FAIL  ", label, "  expected=%s actual=%s" % [str(expected_value), str(actual_value)])
	_failures.append({
		"suite": suite_name,
		"case": _case_id,
		"case_name": _case_name,
		"step": label,
		"expected": str(expected_value),
		"actual": str(actual_value),
	})


## Group checks into a named case so a failure report can point at the procedure
## step that broke rather than at a bare assertion.
func begin_case(case_id: String, case_name: String) -> void:
	_case_id = case_id
	_case_name = case_name
	_case_checks = 0
	_case_fails = 0
	_case_started_ms = Time.get_ticks_msec()


func end_case() -> void:
	if _case_id == "":
		return
	_case_timings.append({
		"case": _case_id,
		"name": _case_name,
		"seconds": float(Time.get_ticks_msec() - _case_started_ms) / 1000.0,
		"checks": _case_checks,
		"failures": _case_fails,
	})
	_case_id = ""
	_case_name = ""


# ---------------------------------------------------------------------- worlds

## Instantiate the production scene and put it in a known starting state. This is
## preparation only: the suite still performs the real interaction afterwards.
func boot() -> void:
	var boot_started := Time.get_ticks_msec()
	game = BASEMENT_SCENE.instantiate()
	add_child(game)
	player = game.player
	farm = game.farm
	game.new_shift(false)
	game.menu.close_menu()
	await _frames(3)
	_boot_ms = Time.get_ticks_msec() - boot_started


## Stop playback that would otherwise bleed into the next suite or leave the
## process waiting on an audio thread.
func release_world() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_back")
	Input.action_release("move_left")
	Input.action_release("move_right")
	Engine.time_scale = 1.0
	if game == null or not is_instance_valid(game):
		return
	if game.player != null and game.player.footstep_player != null:
		game.player.footstep_player.stop()
	if game.sfx_player != null:
		game.sfx_player.stop()
	if game.audio != null:
		for child in game.audio.get_children():
			if child is AudioStreamPlayer:
				(child as AudioStreamPlayer).stop()
	if game.pocket_audio != null:
		for child in game.pocket_audio.get_children():
			if child is AudioStreamPlayer3D:
				(child as AudioStreamPlayer3D).stop()
	game.queue_free()
	game = null


func _frames(count: int) -> void:
	for _index in count:
		await get_tree().physics_frame


# ------------------------------------------------------- shared scene helpers

func _active_trays() -> int:
	var live := 0
	for tray in game.farm.trays:
		if bool(tray.get("active", false)):
			live += 1
	return live


func _has_interactable(kind: String) -> bool:
	return _first_interactable(kind) != null


func _first_interactable(kind: String) -> Node3D:
	for item in game.interactables:
		if item is Node and is_instance_valid(item) and str((item as Node).get_meta("kind", "")) == kind:
			return item as Node3D
	return null


func _tree_text_contains(node: Node, needle: String) -> bool:
	if node is Label and (node as Label).text.contains(needle):
		return true
	if node is RichTextLabel and (node as RichTextLabel).text.contains(needle):
		return true
	for child in node.get_children():
		if _tree_text_contains(child, needle):
			return true
	return false


func _wait_for_machete_ready(who, max_frames: int = 120) -> bool:
	for _frame in max_frames:
		if not who.is_machete_busy():
			return true
		await _frames(1)
	return false


func _clear_burrowers() -> void:
	for creature in game.burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	game.burrowers.clear()


## Waits for a physical lever to finish its throw. A mounted control refuses a
## second throw while travelling, so scripted sequences must respect it too.
func _wait_lever(lever) -> void:
	var guard := 0
	while lever != null and is_instance_valid(lever) and lever.is_moving() and guard < 120:
		await _frames(1)
		guard += 1


func _aim_player_at(target: Vector3) -> void:
	var offset: Vector3 = target - game.player.head.global_position
	game.player.rotation.y = atan2(-offset.x, -offset.z)
	game.player.camera.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())


func _place_burrower_on_view_ray(creature) -> void:
	var forward: Vector3 = -game.player.head.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	creature.global_position = game.player.global_position + forward * 1.9


# -------------------------------------------------------------------- reporting

func summary() -> Dictionary:
	return {
		"suite": suite_name,
		"level": suite_level,
		"checks": checks,
		"failures": fails,
		"seconds": float(Time.get_ticks_msec() - _started_ms) / 1000.0,
		"boot_seconds": float(_boot_ms) / 1000.0,
		"cases": _case_timings,
		"failure_records": _failures,
	}


## Print the result line, write the JSON report when something failed, and return
## the summary so a batch runner can aggregate without parsing stdout.
func finish() -> Dictionary:
	if _finished:
		return summary()
	_finished = true
	end_case()
	if _watchdog != null:
		_watchdog.stop()
	var data: Dictionary = summary()
	if fails > 0:
		print("\nFAILURE DETAIL")
		for record in _failures:
			print("  [%s/%s] %s\n    expected: %s\n    actual:   %s" % [
				record["suite"], record["case"], record["step"],
				record["expected"], record["actual"]])
		_write_report(data)
	else:
		# A green run must not leave yesterday's failure report behind to be read
		# as if it were current.
		_clear_report()
	print("\n%s RESULT: %d checks, %d failures (%.1fs)" % [
		suite_name.to_upper(), checks, fails, float(data["seconds"])])
	return data


func _write_report(data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var path: String = "%s/%s.json" % [REPORT_DIR, suite_name]
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	print("  report: ", ProjectSettings.globalize_path(path))


func _clear_report() -> void:
	var path: String = "%s/%s.json" % [REPORT_DIR, suite_name]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _run_standalone() -> void:
	if needs_scene:
		await boot()
	await run_phases()
	await finish()
	_quit(1 if fails > 0 else 0)


## One suite inside a batch run: same phases, same assertions, but the world is
## released afterwards and the process stays alive for the next suite.
func run_in_batch() -> Dictionary:
	if needs_scene:
		await boot()
	await run_phases()
	var data: Dictionary = finish()
	release_world()
	await get_tree().process_frame
	return data


func _quit(code: int) -> void:
	release_world()
	await get_tree().process_frame
	get_tree().quit(code)


func _on_timeout() -> void:
	if _finished:
		return
	fails += 1
	checks += 1
	_case_fails += 1
	print("  FAIL  %s exceeded its %.0fs timeout inside case '%s'" % [suite_name, timeout_seconds, _case_id])
	_failures.append({
		"suite": suite_name,
		"case": _case_id,
		"case_name": _case_name,
		"step": "suite timeout",
		"expected": "suite completes within %.0fs" % timeout_seconds,
		"actual": "still running in case '%s'" % _case_id,
	})
	await finish()
	_quit(1)
