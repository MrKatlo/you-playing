class_name BasementMenu
extends CanvasLayer

# Minimal, self-contained menu for the basement. It deliberately does not reuse
# GameMenu, which is wired to the station's rpg/inventory/objective API.

const SurvivalGlyph := preload("res://scripts/survival_glyph.gd")
const HUD_SURFACE := preload("res://assets/ui/hud/survival_hud_surface.png")
const RESOURCE_GLYPHS := {
	"parts": "gear",
	"chitin": "chitin",
	"water": "water",
	"hides": "hide",
	"bolts": "bolt",
	"broadhead_bolts": "bolt",
	"tether_bolts": "hook",
	"snares": "snare",
	"patches": "patch",
	"thermal_regulators": "furnace",
	"ember_chitin": "chitin",
	"heat_glands": "furnace",
	"ember_snares": "snare",
}
const WORKBENCH_RESOURCE_ORDER := ["parts", "chitin", "hides", "water", "thermal_regulators"]

var game: Node
var overlay: ColorRect
var panel: PanelContainer
var current_screen := "title"
var return_screen := "title"
var workbench_note := ""
var kitchen_note := ""
# The prep board remembers how many batches the stepper is set to, so a player
# queueing six portions does not have to press the same button six times.
var kitchen_batches := 1
var food_note := ""
var rail_screen := ""
var rail_note := ""

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.008, 0.011, 0.013, 0.91)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var surface := TextureRect.new()
	surface.texture = HUD_SURFACE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	surface.stretch_mode = TextureRect.STRETCH_SCALE
	surface.modulate = Color(0.62, 0.78, 0.82, 0.22)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(surface)
	var upper_rule := ColorRect.new()
	upper_rule.position = Vector2(28, 26)
	upper_rule.size = Vector2(1224, 2)
	upper_rule.color = Color(0.86, 0.39, 0.12, 0.76)
	upper_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(upper_rule)
	var brand := Label.new()
	brand.text = "BASEMENT FARM  //  FIELD SURVIVAL"
	brand.position = Vector2(30, 34)
	brand.size = Vector2(620, 28)
	brand.add_theme_font_size_override("font_size", 13)
	brand.add_theme_color_override("font_color", Color(0.75, 0.58, 0.38))
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(brand)

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

func open_upgrades() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = "upgrades"
	return_screen = "pause"
	_show_upgrades()

func open_workbench() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = "workbench"
	return_screen = "playing"
	workbench_note = "The lamp throws a small warm circle over the vise."
	_show_workbench()

func open_kitchen() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = "kitchen"
	return_screen = "playing"
	kitchen_note = "The pot ticks as the furnace line heats."
	_show_kitchen()

func open_food() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	current_screen = "food"
	return_screen = "playing"
	food_note = ""
	_show_food()

func close_menu() -> void:
	# All menu states use the same clean handoff back to first-person play.
	# Keeping this explicit prevents an instruction or workbench screen from
	# leaving the simulation paused behind an apparently closed overlay.
	current_screen = "playing"
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_checklist() -> void:
	if current_screen == "title":
		return
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_checklist()

func _input(event: InputEvent) -> void:
	if game.player != null:
		game.player.observe_input(event)
	if visible and event.is_action_pressed("ui_cancel"):
		if current_screen in ["workbench", "kitchen", "food", "pause", "checklist"]:
			close_menu()
		elif current_screen != "title":
			_back()
		get_viewport().set_input_as_handled()
		return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("checklist") and current_screen != "title":
		if visible and current_screen == "checklist":
			close_menu()
		elif not visible or current_screen == "pause":
			open_checklist()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("pause"):
		if current_screen == "pause":
			close_menu()
		elif current_screen != "title":
			_show_pause()
		get_viewport().set_input_as_handled()

func _clear_panel(scrollable: bool = false) -> VBoxContainer:
	if panel != null:
		panel.queue_free()
	panel = PanelContainer.new()
	panel.position = Vector2(326, 76)
	panel.size = Vector2(628, 570)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.036, 0.985)
	style.border_color = Color(0.80, 0.35, 0.10, 0.88)
	style.set_border_width_all(1)
	style.border_width_top = 4
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.shadow_color = Color(0, 0, 0, 0.72)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 6)
	style.content_margin_left = 38
	style.content_margin_right = 38
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if scrollable:
		# The fabrication list grows as expeditions bring back real components.
		# Keep it inside a deliberate scroll view instead of letting the last recipe
		# and Leave button disappear below the screen.
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(box)
		panel.add_child(scroll)
	else:
		panel.add_child(box)
	_focus_first_button.call_deferred()
	return box


func _focus_first_button() -> void:
	if not visible or not is_instance_valid(panel):
		return
	for child in panel.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and not button.disabled:
			button.grab_focus()
			return

func _add_title(box: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.40))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	box.add_child(label)
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(0.72, 0.30, 0.08, 0.78)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(rule)


func _add_eyebrow(box: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value.to_upper()
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.55, 0.66, 0.67))
	box.add_child(label)

func _add_copy(box: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size = Vector2(0, 38)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.76, 0.79, 0.76))
	box.add_child(label)

func _add_button(box: VBoxContainer, text_value: String, action: Callable, glyph_name: String = "arrow") -> void:
	var button := Button.new()
	button.text = "       " + text_value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.77))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.82, 0.50))
	button.add_theme_color_override("font_disabled_color", Color(0.34, 0.38, 0.37))
	button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.055, 0.068, 0.071, 0.92), Color(0.22, 0.30, 0.31, 0.88)))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.17, 0.095, 0.040, 0.98), Color(0.95, 0.48, 0.14, 0.96)))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.28, 0.12, 0.045, 1.0), Color(1.0, 0.70, 0.26, 1.0)))
	button.add_theme_stylebox_override("disabled", _menu_button_style(Color(0.030, 0.038, 0.040, 0.86), Color(0.12, 0.16, 0.16, 0.86)))
	var glyph := SurvivalGlyph.new()
	# The compass fills its box with a ring and rim ticks, so it needs more clearance
	# from the label than the open glyphs do; a slightly smaller box keeps every row
	# on the same rhythm without the icon touching the first letter.
	glyph.position = Vector2(13, 10)
	glyph.size = Vector2(23, 23)
	glyph.glyph = glyph_name
	glyph.tint = Color(0.76, 0.89, 0.88)
	glyph.accent = Color(1.0, 0.60, 0.22)
	button.add_child(glyph)
	var arrow := SurvivalGlyph.new()
	arrow.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	arrow.offset_left = -35
	arrow.offset_top = 10
	arrow.offset_right = -8
	arrow.offset_bottom = 34
	arrow.glyph = "arrow"
	arrow.direction = PI * 0.5
	arrow.tint = Color(1.0, 0.66, 0.27)
	button.add_child(arrow)
	button.pressed.connect(action)
	box.add_child(button)


func _menu_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


func _add_instruction_card(box: VBoxContainer, key_text: String, heading: String, copy: String, glyph_name: String) -> void:
	# An icon carries the verb; the keycap and one short line only confirm it.
	# This keeps instruction cards scannable in the same visual language as play.
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 67)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.058, 0.061, 0.96)
	style.border_color = Color(0.20, 0.31, 0.31, 0.92)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	card.add_theme_stylebox_override("panel", style)
	box.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var glyph := SurvivalGlyph.new()
	glyph.custom_minimum_size = Vector2(38, 0)
	glyph.glyph = glyph_name
	glyph.tint = Color(0.66, 0.88, 0.87)
	glyph.accent = Color(1.0, 0.61, 0.24)
	row.add_child(glyph)
	var keycap := Label.new()
	keycap.text = key_text
	keycap.custom_minimum_size = Vector2(56, 0)
	keycap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap.add_theme_font_size_override("font_size", 15)
	keycap.add_theme_color_override("font_color", Color(1.0, 0.72, 0.35))
	keycap.add_theme_stylebox_override("normal", _menu_button_style(Color(0.13, 0.075, 0.032, 1.0), Color(0.90, 0.42, 0.10, 0.85)))
	row.add_child(keycap)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 1)
	row.add_child(words)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.88, 0.92, 0.85))
	words.add_child(title)
	var body := Label.new()
	body.text = copy
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.63, 0.70, 0.70))
	words.add_child(body)


func _resource_glyph(resource_name: String) -> String:
	return str(RESOURCE_GLYPHS.get(resource_name, "gear"))


func _add_icon_stat_row(box: VBoxContainer, entries: Array) -> void:
	# Counts stay numeric, but their meaning lives in the icon rather than a
	# paragraph of inventory names. Hover still exposes an accessible tooltip.
	var row := HBoxContainer.new()
	row.name = "WorkbenchResourceStrip"
	row.custom_minimum_size = Vector2(0, 40)
	row.add_theme_constant_override("separation", 5)
	box.add_child(row)
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(0, 38)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.tooltip_text = str(entry.get("tooltip", ""))
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = Color(0.048, 0.064, 0.067, 0.96)
		chip_style.border_color = Color(0.18, 0.31, 0.32, 0.92)
		chip_style.set_border_width_all(1)
		chip_style.corner_radius_top_left = 3
		chip_style.corner_radius_top_right = 3
		chip_style.corner_radius_bottom_left = 3
		chip_style.corner_radius_bottom_right = 3
		chip_style.content_margin_left = 6
		chip_style.content_margin_right = 6
		chip.add_theme_stylebox_override("panel", chip_style)
		row.add_child(chip)
		var inside := HBoxContainer.new()
		inside.add_theme_constant_override("separation", 4)
		chip.add_child(inside)
		var glyph := SurvivalGlyph.new()
		glyph.custom_minimum_size = Vector2(25, 25)
		glyph.glyph = str(entry.get("glyph", "gear"))
		glyph.tint = Color(0.70, 0.89, 0.88)
		glyph.accent = Color(1.0, 0.58, 0.20)
		glyph.active = bool(entry.get("active", true))
		inside.add_child(glyph)
		var amount := Label.new()
		amount.text = str(entry.get("value", "0"))
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.add_theme_font_size_override("font_size", 15)
		amount.add_theme_color_override("font_color", Color(0.96, 0.89, 0.74) if glyph.active else Color(0.42, 0.47, 0.46))
		inside.add_child(amount)


func _add_resource_token(row: HBoxContainer, resource_name: String, amount: int, active: bool) -> void:
	var token := HBoxContainer.new()
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_theme_constant_override("separation", 2)
	row.add_child(token)
	var glyph := SurvivalGlyph.new()
	glyph.custom_minimum_size = Vector2(15, 15)
	glyph.glyph = _resource_glyph(resource_name)
	glyph.tint = Color(0.66, 0.87, 0.86)
	glyph.accent = Color(1.0, 0.56, 0.18)
	glyph.active = active
	token.add_child(glyph)
	var count := Label.new()
	count.text = "×%d" % amount
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 12)
	count.add_theme_color_override("font_color", Color(0.78, 0.83, 0.81) if active else Color(0.36, 0.40, 0.39))
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(count)


func _recipe_glyph(recipe_id: String) -> String:
	match recipe_id:
		"basic_bolts", "broadhead_bolts":
			return "bolt"
		"tether_bolt":
			return "hook"
		"snare_kit":
			return "snare"
		"driver_repair":
			return "driver"
		"antidote":
			return "antidote"
		"insulation_patch":
			return "patch"
		"warm_storage_rack":
			return "storage"
		"furnace_heat_reclaimer":
			return "furnace"
		"cricket_net":
			return "cricket"
		_:
			return "gear"


func _add_workbench_recipe(box: VBoxContainer, recipe_id: String) -> void:
	var craftable: bool = game.farm.can_craft_at_workbench(recipe_id)
	var recipe: Dictionary = game.farm.workbench_recipe(recipe_id)
	var cost: Dictionary = recipe.get("cost", {})
	var button := Button.new()
	button.name = "WorkbenchRecipe_%s" % recipe_id
	button.custom_minimum_size = Vector2(0, 58)
	button.tooltip_text = "%s\n\n%s\n\nNEEDS %s" % [game.farm.workbench_recipe_label(recipe_id), game.farm.workbench_recipe_description(recipe_id), game.farm.workbench_recipe_cost_text(recipe_id)]
	button.disabled = not craftable
	button.add_theme_stylebox_override("normal", _menu_button_style(Color(0.050, 0.063, 0.065, 0.96), Color(0.19, 0.31, 0.32, 0.90)))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.17, 0.095, 0.040, 0.98), Color(0.95, 0.48, 0.14, 0.96)))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.28, 0.12, 0.045, 1.0), Color(1.0, 0.70, 0.26, 1.0)))
	button.add_theme_stylebox_override("disabled", _menu_button_style(Color(0.032, 0.044, 0.046, 0.96), Color(0.18, 0.26, 0.27, 0.92)))
	button.pressed.connect(_on_workbench_recipe.bind(recipe_id))
	box.add_child(button)
	var glyph := SurvivalGlyph.new()
	glyph.position = Vector2(11, 11)
	glyph.size = Vector2(34, 34)
	glyph.glyph = _recipe_glyph(recipe_id)
	glyph.tint = Color(0.72, 0.91, 0.89) if craftable else Color(0.40, 0.58, 0.57)
	glyph.accent = Color(1.0, 0.58, 0.20) if craftable else Color(0.54, 0.37, 0.20)
	button.add_child(glyph)
	var title := Label.new()
	title.position = Vector2(58, 7)
	title.size = Vector2(390, 20)
	title.text = game.farm.workbench_recipe_label(recipe_id)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.71) if craftable else Color(0.62, 0.67, 0.65))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(title)
	var cost_row := HBoxContainer.new()
	cost_row.position = Vector2(58, 31)
	cost_row.size = Vector2(390, 18)
	cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_row.add_theme_constant_override("separation", 9)
	button.add_child(cost_row)
	for resource_name in WORKBENCH_RESOURCE_ORDER:
		if cost.has(resource_name):
			_add_resource_token(cost_row, resource_name, int(cost[resource_name]), true)
	# Costs outside the common list (ember chitin, heat glands, snares) are shown too,
	# so no required ingredient is ever invisible.
	for resource_name in cost.keys():
		if not WORKBENCH_RESOURCE_ORDER.has(str(resource_name)):
			_add_resource_token(cost_row, str(resource_name), int(cost[resource_name]), true)
	var arrow := SurvivalGlyph.new()
	arrow.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	arrow.offset_left = -35
	arrow.offset_top = 17
	arrow.offset_right = -8
	arrow.offset_bottom = 41
	arrow.glyph = "arrow"
	arrow.direction = PI * 0.5
	arrow.tint = Color(1.0, 0.66, 0.27) if craftable else Color(0.50, 0.36, 0.20)
	button.add_child(arrow)

func _show_title() -> void:
	var box := _clear_panel()
	_add_eyebrow(box, "COLD-FALLOUT SURVIVAL // FIND HEAT. MAKE HOME.")
	_add_title(box, "THE BASEMENT")
	_add_copy(box, "HEAT  •  HUNT  •  RETURN")
	_add_button(box, "NEW SHIFT", _on_new_game, "play")
	_add_button(box, "CONTINUE SHIFT", _on_continue, "load")
	_add_button(box, "SURVIVAL GUIDE", _on_instructions, "compass")
	_add_button(box, "SETTINGS", _on_settings, "gear")
	_add_button(box, "RETURN TO ASTER STATION", _on_station, "exit")
	_add_button(box, "EXIT GAME", _on_quit, "exit")

func _show_pause() -> void:
	current_screen = "pause"
	var box := _clear_panel()
	_add_eyebrow(box, "SHIFT PAUSED // THE CLOCK IS STOPPED")
	_add_title(box, "PAUSED")
	_add_copy(box, "THE CLOCK STOPS. THE COLD DOES NOT.")
	_add_button(box, "RESUME", close_menu, "play")
	_add_button(box, "SAVE", _on_save, "save")
	if game.rail != null and not game.rail.can_save():
		var save_button := box.get_child(box.get_child_count() - 1) as Button
		save_button.disabled = true
		save_button.text = "       SAVE — STOP AT A RAIL PLATFORM"
	_add_button(box, "LOAD", _on_load, "load")
	_add_button(box, "UPGRADES", _show_upgrades, "gear")
	_add_button(box, "SURVIVAL GUIDE", _on_instructions, "compass")
	_add_button(box, "SETTINGS", _on_settings, "gear")
	_add_button(box, "QUIT TO TITLE", _on_title, "exit")

func _on_new_game() -> void:
	get_tree().paused = false
	game.new_shift()
	close_menu()

func _on_continue() -> void:
	if game.load_game():
		close_menu()
	else:
		_show_notice("NO SAVE", "No shift on file. Start a new one.", "title")

func _on_save() -> void:
	game.save_game()
	_show_pause()

func _on_load() -> void:
	if game.load_game():
		close_menu()
	else:
		_show_notice("NO SAVE", "No shift on file.", current_screen)

## Tab checklist: the first-night steps, marked done / current / next. It only
## reads story.stage, so it never blocks or advances anything.
func _show_checklist() -> void:
	if current_screen != "checklist":
		return_screen = current_screen
	current_screen = "checklist"
	var box := _clear_panel()
	var stage: int = game.farm.story.stage
	_add_eyebrow(box, "FIRST NIGHT // TAB TO CLOSE")
	_add_title(box, "CHECKLIST")
	for reached in range(1, StoryState.STAGE_COUNT):
		var mark := "DONE" if stage > reached else ("NOW" if stage == reached else "LATER")
		_add_copy(box, "%s  —  %s" % [mark, str(StoryState.STAGE_LINES.get(reached, ""))])
	if stage >= StoryState.STAGE_HANDOFF:
		_add_copy(box, "DONE  —  the first night is over. The rail is open to inspect.")
	_add_button(box, "BACK", close_menu, "arrow")

func _show_upgrades() -> void:
	if current_screen != "upgrades":
		return_screen = current_screen
	current_screen = "upgrades"
	var box := _clear_panel()
	_add_eyebrow(box, "HOME IMPROVEMENTS // PARTS %d" % game.farm.parts)
	_add_title(box, "UPGRADES")
	_add_copy(box, "Every improvement becomes a visible part of the home. Choose the thing that makes the next night easier.")
	for axis in FarmState.AXES:
		var tier := int(game.farm.upgrades[axis])
		var cost: int = game.farm.upgrade_cost(axis)
		var label := "%s  —  TIER %d" % [str(FarmState.AXIS_NAMES[axis]), tier]
		if tier >= FarmState.UPGRADE_COSTS.size():
			label += "\nMAXED"
		else:
			label += "\nCost: %d parts" % cost
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(0, 50)
		button.add_theme_font_size_override("font_size", 14)
		button.disabled = not game.farm.can_upgrade(axis)
		button.pressed.connect(_on_upgrade.bind(axis))
		box.add_child(button)
	_add_button(box, "BACK", _back, "exit")

func _show_workbench() -> void:
	current_screen = "workbench"
	var box := _clear_panel(true)
	# The workbench now carries a proper hunt loadout as well as base repairs.
	# Give its recipe sheet the height it needs instead of silently clipping the
	# lower entries below the original pause-menu panel.
	panel.position = Vector2(322, 12)
	panel.size = Vector2(636, 696)
	box.add_theme_constant_override("separation", 4)
	_add_eyebrow(box, "FIELD FABRICATION // SURVIVAL GEAR")
	_add_title(box, "SALVAGE WORKBENCH")
	_add_icon_stat_row(box, [
		{"glyph": "gear", "value": game.farm.parts, "tooltip": "Parts"},
		{"glyph": "chitin", "value": game.farm.chitin, "tooltip": "Chitin"},
		{"glyph": "water", "value": game.farm.water, "tooltip": "Water"},
		{"glyph": "hide", "value": game.farm.hides, "tooltip": "Hides"},
		{"glyph": "furnace", "value": game.farm.thermal_regulators, "tooltip": "C-4 regulators"},
	])
	_add_icon_stat_row(box, [
		{"glyph": "bolt", "value": game.farm.bolts, "tooltip": "Standard bolts"},
		{"glyph": "bolt", "value": game.farm.broadhead_bolts, "tooltip": "Broadhead bolts"},
		{"glyph": "hook", "value": game.farm.tether_bolts, "tooltip": "Tether bolts"},
		{"glyph": "snare", "value": game.farm.snares, "tooltip": "Floor snares"},
		{"glyph": "driver", "value": "%d" % game.farm.driver_durability, "tooltip": "Bolt driver pressure", "active": game.farm.driver_durability > 0},
	])
	for recipe_value in game.farm.workbench_recipe_ids():
		var recipe_id: String = str(recipe_value)
		_add_workbench_recipe(box, recipe_id)
	if not workbench_note.is_empty():
		_add_copy(box, workbench_note)
	_add_button(box, "LEAVE WORKBENCH", close_menu, "exit")

func _on_workbench_recipe(recipe_id: String) -> void:
	workbench_note = str(game.craft_workbench_recipe(recipe_id))
	_show_workbench()

func _show_kitchen() -> void:
	current_screen = "kitchen"
	var box := _clear_panel(true)
	panel.position = Vector2(340, 88)
	panel.size = Vector2(600, 544)
	box.add_theme_constant_override("separation", 6)
	_add_eyebrow(box, "CRICKET KITCHEN // DRESS  COOK  CURE")
	_add_title(box, "PREP BOARD")
	_add_icon_stat_row(box, [
		{"glyph": "cricket", "value": game.farm.live_crickets, "tooltip": "Live crickets in the net"},
		{"glyph": "cooking", "value": game.farm.dressed_crickets, "tooltip": "Dressed portions"},
		{"glyph": "furnace", "value": int(game.farm.meals) + int(game.farm.ready_meals), "tooltip": "Cricket meals"},
		{"glyph": "snare", "value": int(game.farm.jerky) + int(game.farm.ready_jerky), "tooltip": "Jerky strips"},
	])
	_add_copy(box, "%d live crickets dress into %d portions — shells, legs and gut come off. The pot takes one fuel per batch; the rack takes an hour and no fire at all." % [FarmState.CRICKETS_TO_DRESS, FarmState.DRESSED_PER_BATCH])
	# C2.10 // what the board can take right now, and what is already working.
	_add_copy(box, "CAN START NOW — %d cook / %d cure.  %s" % [
		game.farm.kitchen_max("cook"), game.farm.kitchen_max("cure"), _kitchen_queue_line()])
	_add_button(box, "BATCHES: %d   (CLICK TO CHANGE)" % kitchen_batches, _on_kitchen_batches, "storage")
	_add_button(box, "QUEUE %d COOK  (%d PORTIONS + %d FUEL)" % [kitchen_batches, kitchen_batches * FarmState.MEALS_PER_BATCH, kitchen_batches * int(FarmState.COOK_FUEL_COST)], _on_kitchen_queue.bind("cook"), "furnace")
	_add_button(box, "QUEUE %d CURE  (%d PORTIONS → %d JERKY)" % [kitchen_batches, kitchen_batches * FarmState.DRESSED_PER_BATCH, kitchen_batches * FarmState.JERKY_PER_BATCH], _on_kitchen_queue.bind("cure"), "snare")
	_add_button(box, "DRESS %d LIVE → %d PORTIONS" % [FarmState.CRICKETS_TO_DRESS, FarmState.DRESSED_PER_BATCH], _on_kitchen_action.bind("dress"), "cooking")
	_add_button(box, "COLLECT %d READY (%d MEAL / %d JERKY)" % [game.farm.kitchen_ready_total(), game.farm.ready_meals, game.farm.ready_jerky], _on_kitchen_action.bind("collect"), "ration")
	if not kitchen_note.is_empty():
		_add_copy(box, kitchen_note)
	_add_button(box, "LEAVE KITCHEN", close_menu, "exit")


## One readable line for the queue: what the board is working on and how far in.
func _kitchen_queue_line() -> String:
	if game.farm.kitchen_jobs.is_empty():
		return "THE BOARD IS CLEAR."
	var job: Dictionary = game.farm.kitchen_jobs[0]
	var total_hours: float = maxf(0.01, float(job.get("total_minutes", 1.0)) / 60.0)
	var left: float = maxf(0.0, float(job.get("hours_left", 0.0)))
	var done: float = clampf(1.0 - left / total_hours, 0.0, 1.0)
	var label := "POT" if str(job.get("kind", "")) == "cook" else "RACK"
	return "%s %d%% — %.1f H LEFT, %d MORE WAITING." % [label, int(done * 100.0), left, game.farm.kitchen_jobs.size() - 1]


func _on_kitchen_batches() -> void:
	# Cycle through the sizes a board realistically takes, ending on "all of it".
	var ceiling: int = maxi(1, maxi(game.farm.kitchen_max("cook"), game.farm.kitchen_max("cure")))
	var choices: Array[int] = [1, 2, 3, 6, ceiling]
	var next := 1
	for choice in choices:
		if choice > kitchen_batches and choice <= ceiling:
			next = choice
			break
	kitchen_batches = clampi(next, 1, ceiling)
	_show_kitchen()


func _on_kitchen_queue(kind: String) -> void:
	kitchen_note = str(game.kitchen_queue(kind, kitchen_batches))
	_show_kitchen()


func _on_kitchen_action(action_name: String) -> void:
	kitchen_note = str(game.kitchen_action(action_name))
	_show_kitchen()

func _show_food() -> void:
	current_screen = "food"
	var box := _clear_panel(false)
	panel.position = Vector2(340, 128)
	panel.size = Vector2(600, 464)
	box.add_theme_constant_override("separation", 6)
	_add_eyebrow(box, "FOOD CRATE // THREE KINDS OF FOOD")
	_add_title(box, "STORES")
	_add_icon_stat_row(box, [
		{"glyph": "ration", "value": game.farm.rations, "tooltip": "Packed rations"},
		{"glyph": "cooking", "value": game.farm.meals, "tooltip": "Cricket meals"},
		{"glyph": "snare", "value": game.farm.jerky, "tooltip": "Jerky strips"},
		{"glyph": "hunger", "value": int(game.farm.hunger_hours), "tooltip": "Hours of appetite left"},
	])
	_add_copy(box, "Eating above %d h of appetite is refused — the crate is the store you sell from. Rations are the baseline; a hot meal lasts longest; jerky travels best." % int(game.farm.EAT_HUNGER_LIMIT))
	_add_button(box, "EAT A RATION (%d H)" % int(FarmState.RATION_HUNGER_HOURS), _on_food_action.bind("ration"), "ration")
	_add_button(box, "EAT A CRICKET MEAL (%d H)" % int(FarmState.MEAL_HUNGER_HOURS), _on_food_action.bind("meal"), "cooking")
	_add_button(box, "EAT A STRIP OF JERKY (%d H)" % int(FarmState.JERKY_HUNGER_HOURS), _on_food_action.bind("jerky"), "snare")
	if not food_note.is_empty():
		_add_copy(box, food_note)
	_add_button(box, "CLOSE THE CRATE", close_menu, "exit")

func _on_food_action(kind: String) -> void:
	food_note = str(game.food_action(kind))
	_show_food()

func _on_upgrade(axis: String) -> void:
	game.farm.buy_upgrade(axis)
	_show_upgrades()

func open_rail(kind: String) -> void:
	rail_screen = kind
	rail_note = ""
	current_screen = "rail"
	return_screen = "playing"
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_rail()

func _show_rail() -> void:
	var box := _clear_panel(true)
	var state: Dictionary = game.farm.rail.data
	_add_eyebrow(box, "C-4 MINING NETWORK // AUTHORIZED CART")
	_add_title(box, {"rail_terminal": "EXCHANGE", "rail_workshop": "WORKSHOP", "rail_storage": "SHARED STORAGE", "rail_safety": "SAFETY RESTORATION"}.get(rail_screen, "RAIL"))
	_add_copy(box, "SCRAP %d  /  WIRE %d  /  BATTERIES %d\nMECHANICAL PARTS %d  /  CART %d%%" % [game.farm.scrap_metal, game.farm.wiring, game.farm.batteries, game.farm.parts, int(state.cart_durability)])
	match rail_screen:
		"rail_terminal":
			_add_copy(box, "PARTS STOCK %d / 10 · restocked by a full loop\nKits are protected cargo. Scavenge the platform salvage if supplies run short." % int(state.terminal_parts_stock))
			for id in game.rail.Trading.OFFERS:
				var label: String = str(game.rail.Trading.OFFERS[id].label)
				_add_button(box, label, _rail_action.bind(id), "gear")
				_add_copy(box, game.rail.Trading.cost_text(id))
		"rail_workshop":
			_add_button(box, "RESTORE WORKSHOP · USE KIT", _rail_action.bind("workshop"), "gear")
			_add_button(box, "FULL CART REPAIR · 1 PART", _rail_action.bind("repair"), "gear")
		"rail_storage":
			_add_copy(box, "SHARED %d / 25 · accessible at both platforms" % int(state.shared_parts))
			_add_button(box, "STORE 1 CARRIED PART", _rail_action.bind("deposit"), "gear")
			_add_button(box, "TAKE 1 STORED PART", _rail_action.bind("withdraw"), "gear")
		"rail_safety":
			_add_copy(box, "Fit the terminal kit, then operate the three physical switches beside this cabinet.\nLIGHTS %s   WARNINGS %s   MOTOR %s" % ["ON" if state.safety_switches[0] else "OFF", "ON" if state.safety_switches[1] else "OFF", "ON" if state.safety_switches[2] else "OFF"])
			_add_button(box, "FIT SAFETY KIT", _rail_action.bind("safety"), "gear")
	if not rail_note.is_empty(): _add_copy(box, rail_note)
	_add_button(box, "CLOSE", close_menu, "exit")

func _rail_action(action: String) -> void:
	rail_note = game.rail.menu_action(action)
	_show_rail()

func _on_settings() -> void:
	return_screen = current_screen
	current_screen = "settings"
	var box := _clear_panel()
	_add_eyebrow(box, "ACCESSIBILITY // AUDIO")
	_add_title(box, "SETTINGS")
	_add_copy(box, "MASTER VOLUME")
	var slider := HSlider.new()
	slider.min_value = -30.0
	slider.max_value = 0.0
	slider.step = 1.0
	slider.value = game.master_volume_db
	slider.value_changed.connect(game.set_master_volume)
	box.add_child(slider)
	_add_copy(box, "RAIL WARNING VOLUME")
	var warnings := HSlider.new()
	warnings.min_value = 0
	warnings.max_value = 1
	warnings.step = .05
	warnings.value = game.farm.rail.data.warning_volume
	warnings.value_changed.connect(func(value): game.farm.rail.data.warning_volume = value; game.rail.checkpoint())
	box.add_child(warnings)
	var captions := CheckButton.new()
	captions.text = "RAIL SOUND CAPTIONS"
	captions.button_pressed = game.farm.rail.data.subtitles
	captions.toggled.connect(func(value): game.farm.rail.data.subtitles = value; game.rail.checkpoint())
	box.add_child(captions)
	var shake := CheckButton.new()
	shake.text = "REDUCED RAIL CAMERA SHAKE"
	shake.button_pressed = game.farm.rail.data.reduced_shake
	shake.toggled.connect(func(value): game.farm.rail.data.reduced_shake = value; game.rail.checkpoint())
	box.add_child(shake)
	_add_button(box, "BACK", _back, "exit")

func _on_instructions() -> void:
	# This is normally reached through a menu button, but it is safe to call as
	# its own screen too (for title shortcuts, accessibility, and automated QA).
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_screen = current_screen
	current_screen = "instructions"
	var box := _clear_panel(true)
	panel.position = Vector2(266, 18)
	panel.size = Vector2(748, 686)
	box.add_theme_constant_override("separation", 6)
	_add_eyebrow(box, "SURVIVAL PROTOCOL // READ BEFORE LEAVING THE WARM ROOM")
	_add_title(box, "HOW TO SURVIVE")
	_add_instruction_card(box, "WASD", "MOVE / STEP", "Run and vault to stay off the noise line. CTRL steps clear of a leap.", "compass")
	_add_instruction_card(box, "E", "USE", "Follow the action icon; use the object in reach.", "use")
	_add_instruction_card(box, "XBOX", "MOVE / USE", "Left stick moves; right stick looks. X uses or holds a crank. A jumps, B dodges. Y cycles tools.", "compass")
	_add_instruction_card(box, "G / ↓", "PLACE LINK", "G or D-pad down places the held chain link on a safe surface. Look at it and use to recover it.", "chain")
	_add_instruction_card(box, "RT / LB", "TOOLS", "RT attacks with the drawn tool; LB uses the blade. RB changes bolts. D-pad left toggles the torch; up toggles the lantern.", "machete")
	_add_instruction_card(box, "R / LMB", "FIGHT", "Machete close. Bolt at range. H clears the right hand.", "machete")
	_add_instruction_card(box, "F / C", "LIGHT", "Light the dark. Dose venom before it owns your hands.", "light")
	_add_instruction_card(box, "HUNT", "CONTAIN", "Bait. Crank. Seal. Then enter the chamber.", "warning")
	_add_instruction_card(box, "CAVE", "RETURN", "Bring real salvage home; turn it into visible upgrades.", "cave")
	_add_instruction_card(box, "RAIL", "DRIVE / COAST", "W accelerates; S brakes. F headlight. R repairs while stopped. E exits at platforms. Coast near scraping sounds.", "gear")
	_add_button(box, "BACK", _back, "exit")

func _on_station() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_title() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().quit()

func _show_notice(title_text: String, copy: String, back_to: String) -> void:
	return_screen = back_to
	var box := _clear_panel()
	_add_title(box, title_text)
	_add_copy(box, copy)
	_add_button(box, "BACK", _back, "exit")

func _back() -> void:
	if return_screen == "pause":
		_show_pause()
	elif return_screen == "playing":
		close_menu()
	else:
		current_screen = "title"
		_show_title()
