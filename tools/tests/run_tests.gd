extends Node

## Front end for the modular Basement Farm suites.
##
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --list
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=unit
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=workflow
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --module=workflow_weapons,workflow_creatures
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --changed=scripts/burrower.gd
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --all
##   Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=workflow --order=reverse
##
## Selection is driven by tools/tests/dependencies.json, not by file names: a
## suite lists the game files it exercises and the suites it builds on, so a
## change reports the suites it reaches. Everything runs in one process, unit
## suites first, and stops early only when a whole level is already broken.

const DEPENDENCY_MAP := "res://tools/tests/dependencies.json"
const LEVEL_ORDER := ["unit", "workflow", "e2e"]

var suites := {}
var selected: Array[String] = []
var results: Array[Dictionary] = []
var started_ms := 0
var total_checks := 0
var total_fails := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	started_ms = Time.get_ticks_msec()
	var args := OS.get_cmdline_user_args()
	var map: Dictionary = _load_map()
	suites = map.get("suites", {})
	if suites.is_empty():
		push_error("No suites found in %s" % DEPENDENCY_MAP)
		get_tree().quit(2)
		return

	if _has_flag(args, "--list"):
		_list()
		get_tree().quit(0)
		return

	selected = _select(args)
	if selected.is_empty():
		print("No suites selected. Matching rule: %s" % _selection_rule(args))
		get_tree().quit(0)
		return

	print("TEST RUN // %d suites: %s" % [selected.size(), ", ".join(selected)])
	print("selection: %s\n" % _selection_rule(args))

	for index in selected.size():
		var name: String = selected[index]
		var script_path: String = str(suites[name].get("script", ""))
		var suite = load(script_path).new()
		suite.auto_run = false
		add_child(suite)
		var data: Dictionary = await suite.run_in_batch()
		results.append(data)
		total_checks += int(data.get("checks", 0))
		total_fails += int(data.get("failures", 0))
		remove_child(suite)
		suite.queue_free()
		await get_tree().process_frame

	var elapsed := float(Time.get_ticks_msec() - started_ms) / 1000.0
	print("\n----------------------------------------------------------")
	for data in results:
		print("  %-20s %4d checks  %2d failures  %6.1fs" % [
			str(data.get("suite", "?")), int(data.get("checks", 0)),
			int(data.get("failures", 0)), float(data.get("seconds", 0.0))])
	print("----------------------------------------------------------")
	print("TEST RUN RESULT: %d suites, %d checks, %d failures (%.1fs)" % [
		results.size(), total_checks, total_fails, elapsed])
	get_tree().quit(1 if total_fails > 0 else 0)


func _load_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(DEPENDENCY_MAP, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _has_flag(args: PackedStringArray, flag: String) -> bool:
	for argument in args:
		if argument == flag:
			return true
	return false


func _value(args: PackedStringArray, key: String) -> String:
	for argument in args:
		if argument.begins_with(key + "="):
			return argument.substr(key.length() + 1)
	return ""


func _list() -> void:
	print("SUITES (%d)" % suites.size())
	for level in LEVEL_ORDER:
		for name in suites.keys():
			if str(suites[name].get("level", "")) != level:
				continue
			print("  %-10s %-22s %s" % [level, name, str(suites[name].get("title", ""))])
		print("")


func _select(args: PackedStringArray) -> Array[String]:
	var chosen: Array[String] = []
	var module_arg := _value(args, "--module")
	var level_arg := _value(args, "--level")
	var changed_arg := _value(args, "--changed")

	if module_arg != "":
		for name in module_arg.split(",", false):
			var clean := name.strip_edges()
			if not suites.has(clean):
				print("Unknown suite: %s" % clean)
				continue
			chosen.append(clean)
	elif level_arg != "":
		for name in suites.keys():
			if level_arg == "all" or str(suites[name].get("level", "")) == level_arg:
				chosen.append(name)
	elif changed_arg != "":
		chosen = _select_for_paths(changed_arg.split(",", false))
	else:
		for name in suites.keys():
			chosen.append(name)

	return _order(chosen, _value(args, "--order"))


## Map changed game files to the suites that exercise them, then to the suites
## that build on those. Reverse dependency walks the whole map, so a change in a
## shared model reaches everything above it instead of quietly passing.
func _select_for_paths(paths: PackedStringArray) -> Array[String]:
	var direct: Array[String] = []
	for path in paths:
		var clean := path.strip_edges().replace("\\", "/")
		if clean == "":
			continue
		for name in suites.keys():
			for owned in suites[name].get("files", []):
				if clean.contains(str(owned)) or str(owned).contains(clean):
					if not direct.has(name):
						direct.append(name)
	var reached: Array[String] = direct.duplicate()
	var changed := true
	while changed:
		changed = false
		for name in suites.keys():
			if reached.has(name):
				continue
			for dependency in suites[name].get("depends_on", []):
				if reached.has(str(dependency)):
					reached.append(name)
					changed = true
					break
	return reached


func _order(names: Array[String], order: String) -> Array[String]:
	var ordered: Array[String] = []
	var pool: Array[String] = names.duplicate()
	for level in LEVEL_ORDER:
		for name in pool:
			if ordered.has(name):
				continue
			if str(suites[name].get("level", "")) == level:
				ordered.append(name)
	if order == "reverse":
		ordered.reverse()
	return ordered


func _selection_rule(args: PackedStringArray) -> String:
	if _value(args, "--module") != "":
		return "named suites: %s" % _value(args, "--module")
	if _value(args, "--level") != "":
		return "every suite at level '%s'" % _value(args, "--level")
	if _value(args, "--changed") != "":
		return "suites whose files or dependencies reach: %s" % _value(args, "--changed")
	return "everything (unit, then workflow, then the full run)"
