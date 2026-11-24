extends "res://tools/tests/test_base.gd"

## Chain link held item (slot 5)
##
## The fifth slot holds a crafted chain link. It is unavailable with no link,
## selectable once one is in the farm, dropped as a world node with the
## interact key when nothing is in reach, and returned to the farm when picked up.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_chain_link.tscn


func _init() -> void:
	suite_name = "workflow_chain_link"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_chain_link_slot()
	await _test_hotbar_cells()


func _test_hotbar_cells() -> void:
	var player = game.player
	var farm = game.farm
	var cells: Array[Panel] = game.hotbar_slots
	var glyphs: Array = game.hotbar_glyphs
	_ok(cells.size() == 5, "the hotbar has five cells", "cells = %d" % cells.size())
	_ok(glyphs.size() == 5, "the hotbar has one icon per cell", "icons = %d" % glyphs.size())
	if cells.size() < 5 or glyphs.size() < 5:
		return

	# Slot 5 is the chain link: its icon is only active while a link is carried.
	farm.chain_links = 0
	player.set_link_carried(false)
	game._update_hotbar()
	_ok(not glyphs[4].active, "the chain cell is inactive with no link")

	farm.chain_links = 1
	player.set_link_carried(true)
	player.select_slot(player.SLOT_LINK)
	game._update_hotbar()
	_ok(glyphs[4].active, "the chain cell is active once a link is carried")
	var style := cells[4].get_theme_stylebox("panel") as StyleBoxFlat
	_ok(style != null and style.border_width_left == 2 and style.border_color.r > 0.9,
		"the chain cell is highlighted while slot 5 is held")
	_ok(str(game.hotbar_name_label.text) == "CHAIN LINK", "the hotbar label names the chain link")

	player.set_machete_equipped(true)
	_ok(player.select_slot(player.SLOT_MACHETE), "the machete is selectable so the highlight can move off the chain")
	game._update_hotbar()
	var style_off := cells[4].get_theme_stylebox("panel") as StyleBoxFlat
	_ok(style_off != null and style_off.border_width_left == 1,
		"the chain cell is not highlighted when another slot is held")


func _test_chain_link_slot() -> void:
	var player = game.player
	var farm = game.farm
	player.global_position = Vector3(7.5, 0.9, -2.6)
	player.velocity = Vector3.ZERO
	farm.chain_links = 0
	player.set_link_carried(false)
	await _frames(2)

	_ok(InputMap.has_action("slot_5"), "key 5 is bound to slot_5")
	_ok(not player.owns_slot(player.SLOT_LINK), "slot 5 is empty with no chain link")
	_ok(not player.select_slot(player.SLOT_LINK), "slot 5 cannot be selected with no chain link")

	# A crafted link puts one in the farm; the held state follows it.
	farm.chain_links = 1
	player.set_link_carried(farm.chain_links > 0)
	_ok(player.select_slot(player.SLOT_LINK), "slot 5 selects the chain link once one is in the farm")
	await _frames(4)
	_ok(player.active_slot == player.SLOT_LINK and player.active_tool_label() == "CHAIN LINK",
		"the held label reads CHAIN LINK")
	_ok(player.link_view != null and player.link_view.visible,
		"the procedural held link is visible in slot 5")

	# Interact with nothing in reach drops the link: the farm empties and a world node appears.
	var before_drops := _world_chain_drops()
	game.opening_state = ""
	player.global_position = Vector3(0.0, 0.1, 0.0)
	await _frames(2)
	var near = game._nearest_interactable()
	var near_kind := str(near.get_meta("kind", "")) if near != null else "none"
	_ok(near == null, "nothing is in reach at the drop spot", "reach=" + near_kind)
	game.player_interact()
	await _frames(2)
	_ok(farm.chain_links == 0, "dropping the held link takes it out of the farm")
	_ok(_world_chain_drops() == before_drops + 1, "dropping the held link spawns one world chain drop")

	# Picking the world drop up returns the link to the farm and removes the node.
	var dropped := _find_world_chain_drop()
	_ok(dropped != null, "the world chain drop can be found")
	if dropped != null:
		game._pick_up_chain_link(dropped)
	await _frames(2)
	_ok(farm.chain_links == 1, "picking up the world drop returns the link to the farm")
	_ok(_world_chain_drops() == before_drops, "the picked-up world chain drop is removed")


func _world_chain_drops() -> int:
	return game.find_children("DroppedChainLink*", "", true, false).size()


func _find_world_chain_drop() -> Node:
	var found: Array[Node] = game.find_children("DroppedChainLink*", "", true, false)
	return found[0] if not found.is_empty() else null
