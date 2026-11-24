class_name GameMenu
extends CanvasLayer

var game: Node
var overlay: ColorRect
var panel: PanelContainer
var current_screen := "title"
var return_screen := "title"
var dialogue_feedback := ""

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.008, 0.014, 0.022, 0.90)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

func open_title() -> void:
	current_screen = "title"
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_title()

func open_pause() -> void:
	if current_screen == "title":
		return
	current_screen = "pause"
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_pause()

func close_menu() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_screen == "pause":
			close_menu()
		elif current_screen != "title":
			_back()

func _clear_panel() -> VBoxContainer:
	if panel != null:
		panel.queue_free()
	panel = PanelContainer.new()
	panel.position = Vector2(425, 130)
	panel.size = Vector2(430, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.085, 0.98)
	style.border_color = Color(0.12, 0.78, 0.68, 0.90)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	return box

func _add_title(box: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.50, 1.0, 0.88))
	box.add_child(label)

func _add_copy(box: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 54)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.73, 0.82, 0.86))
	box.add_child(label)

func _add_button(box: VBoxContainer, label_text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(action)
	box.add_child(button)

func _on_basement() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/basement.tscn")

func _show_title() -> void:
	var box := _clear_panel()
	panel.position = Vector2(425, 100)
	panel.size = Vector2(430, 528)
	_add_title(box, "THE LAST SIGNAL")
	_add_copy(box, "YOU BUILT ASTER'S ECHO LOCK.\nNOW ITS LAST SIGNAL HAS CALLED YOU HOME.")
	_add_button(box, "NEW GAME", _on_new_game)
	_add_button(box, "THE BASEMENT", _on_basement)
	_add_button(box, "MARA'S FIELD KIT", _on_character.bind("title"))
	_add_button(box, "LOAD LAST SIGNAL", _on_load)
	_add_button(box, "INSTRUCTIONS", _on_instructions.bind("title"))
	_add_button(box, "SETTINGS", _on_settings.bind("title"))
	_add_button(box, "EXIT GAME", _on_quit)

func _show_pause() -> void:
	var box := _clear_panel()
	panel.position = Vector2(425, 92)
	panel.size = Vector2(430, 536)
	_add_title(box, "PAUSED")
	_add_copy(box, "The station waits in the dark.")
	_add_button(box, "RESUME", close_menu)
	_add_button(box, "SAVE GAME", _on_save)
	_add_button(box, "LOAD LAST SIGNAL", _on_load)
	_add_button(box, "CHARACTER", _on_character.bind("pause"))
	_add_button(box, "INSTRUCTIONS", _on_instructions.bind("pause"))
	_add_button(box, "SETTINGS", _on_settings.bind("pause"))
	_add_button(box, "QUIT TO TITLE", _on_title)

func _on_new_game() -> void:
	get_tree().paused = false
	game.new_game()

func _on_save() -> void:
	game.save_game()
	_show_pause()

func _on_load() -> void:
	if game.load_game():
		close_menu()
	else:
		_show_notice("NO SAVE FOUND", "Start a new game, reach a checkpoint, then save from the pause menu.", current_screen)

func _on_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()

func _on_instructions(back_to: String) -> void:
	return_screen = back_to
	var box := _clear_panel()
	current_screen = "instructions"
	_add_title(box, "INSTRUCTIONS")
	_add_copy(box, "WASD — move\nSHIFT — run (louder)\nSPACE — vault low threats (noisy)\nE — interact / hide in lockers\nC — craft a noise lure\nQ — arc pulse (stuns scavengers; noisy)\nLEFT CLICK — fire the riveter (very loud; stuns scavengers)\nF — flashlight\nESC — pause / character\n\nRead logs and complete objectives to gain XP. Spend skill points in PAUSE > CHARACTER. The Resonant is nearly blind: it follows fresh vibration. Running and machinery create a trail; stopping still lets that trail die. Watch its throat rings before an echo pulse.")
	_add_button(box, "BACK", _back)

func _on_character(back_to: String) -> void:
	return_screen = back_to
	current_screen = "character"
	var box := _clear_panel()
	panel.position = Vector2(350, 58)
	panel.size = Vector2(580, 604)
	_add_title(box, "MARA VENN // CHARACTER")
	_add_copy(box, "LEVEL %d    XP %d / %d    SKILL POINTS %d\nNIX TRUST %d / 3" % [game.rpg.level, game.rpg.experience, game.rpg.experience_to_next(), game.rpg.skill_points, game.rpg.companion_trust])
	_add_copy(box, "PRIMARY // " + game._objective_text())
	var side_quest := "Feed Nix a sealed snack to earn its trust and an arc charge."
	if game.nix != null and game.nix.traded:
		side_quest = "Nix trusts Mara. It has already returned a field pack."
	_add_copy(box, "SIDE QUEST // " + side_quest)
	for skill_id in ["quiet_step", "charged_pulse", "insulated_pack"]:
		_add_skill_button(box, skill_id)
	_add_button(box, "BACK", _back)

func _add_skill_button(box: VBoxContainer, skill_id: String) -> void:
	var data: Dictionary = game.rpg.SKILLS.get(skill_id, {})
	var unlocked: bool = game.rpg.has_skill(skill_id)
	var button := Button.new()
	button.text = ("✓ " if unlocked else "") + str(data.get("name", skill_id)) + "\n" + str(data.get("description", ""))
	button.custom_minimum_size = Vector2(0, 62)
	button.add_theme_font_size_override("font_size", 14)
	button.disabled = unlocked or not game.rpg.can_unlock(skill_id)
	button.pressed.connect(_on_unlock_skill.bind(skill_id))
	box.add_child(button)

func _on_unlock_skill(skill_id: String) -> void:
	game.unlock_skill(skill_id)
	_on_character(return_screen)

func open_nix_dialog() -> void:
	current_screen = "nix"
	dialogue_feedback = ""
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_nix_dialog()

func _show_nix_dialog() -> void:
	var box := _clear_panel()
	panel.position = Vector2(390, 105)
	panel.size = Vector2(500, 510)
	_add_title(box, "NIX // TUNNEL RAT")
	var opening := "The small scavenger watches Mara from the vent mouth. Its ears flatten whenever the station hum changes."
	if game.nix != null and game.nix.traded:
		opening = "Nix circles Mara's boots, then points its nose toward the deep station. It remembers the way you helped it."
	_add_copy(box, opening)
	if not dialogue_feedback.is_empty():
		_add_copy(box, dialogue_feedback)
	if game.inventory.snack > 0 and game.nix != null and not game.nix.traded:
		_add_button(box, "OFFER A SEALED SNACK", _on_nix_choice.bind("feed"))
	else:
		_add_copy(box, "Nix wants a sealed snack. Feed it for trust and a field-pack reward.")
	_add_button(box, "ASK ABOUT THE RESONANT", _on_nix_choice.bind("ask"))
	_add_button(box, "LEAVE", close_menu)

func _on_nix_choice(choice: String) -> void:
	dialogue_feedback = game.resolve_nix_choice(choice)
	_show_nix_dialog()

func open_beacon_choice() -> void:
	current_screen = "beacon_choice"
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var box := _clear_panel()
	panel.position = Vector2(365, 118)
	panel.size = Vector2(550, 484)
	_add_title(box, "RIDGE BEACON // FINAL CALL")
	_add_copy(box, "Mara's voiceprint can do one of two things. Neither erases what happened at Aster.")
	_add_button(box, "RE-ENGAGE ECHO LOCK\nContain the Resonant and send a rescue signal.", _on_beacon_choice.bind("contain"))
	_add_button(box, "BROADCAST PROJECT ECHO\nExpose Aster's records to every rescue channel.", _on_beacon_choice.bind("expose"))
	_add_button(box, "STEP AWAY", close_menu)

func _on_beacon_choice(choice: String) -> void:
	game.resolve_beacon_choice(choice)

func _on_settings(back_to: String) -> void:
	return_screen = back_to
	current_screen = "settings"
	var box := _clear_panel()
	_add_title(box, "SETTINGS")
	_add_copy(box, "MASTER VOLUME")
	var volume := HSlider.new()
	volume.min_value = -30.0
	volume.max_value = 0.0
	volume.step = 1.0
	volume.value = game.master_volume_db
	volume.value_changed.connect(game.set_master_volume)
	box.add_child(volume)
	_add_copy(box, "BRIGHTNESS")
	var brightness := HSlider.new()
	brightness.min_value = 0.55
	brightness.max_value = 1.55
	brightness.step = 0.05
	brightness.value = game.brightness
	brightness.value_changed.connect(game.set_brightness)
	box.add_child(brightness)
	_add_copy(box, "Brightness affects station ambient light.\nSettings are stored with the next save.")
	_add_button(box, "BACK", _back)

func _show_notice(title_text: String, copy: String, back_to: String) -> void:
	return_screen = back_to
	var box := _clear_panel()
	_add_title(box, title_text)
	_add_copy(box, copy)
	_add_button(box, "BACK", _back)

func _back() -> void:
	if return_screen == "pause":
		current_screen = "pause"
		_show_pause()
	else:
		current_screen = "title"
		_show_title()
