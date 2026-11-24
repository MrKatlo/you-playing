extends Node3D

const Hunter := preload("res://scripts/echo_hunter.gd")
var rail
var rng := RandomNumberGenerator.new()
var opportunities: Array[Dictionary] = []
var scares := 0
var collapse_active := false
var collapse_warned := false
var collapse_done := false
var collapse_warning_time := 0.0
var flood_warned := false
var figure_done := false
var flood_scare_done := false

func begin_ride() -> void:
	scares = 0
	figure_done = false
	flood_scare_done = false
	new_pass()

func new_pass() -> void:
	for item in opportunities:
		if is_instance_valid(item.actor): item.actor.queue_free()
	opportunities.clear()
	collapse_active = rng.randf() < .65
	collapse_warned = false
	collapse_done = false
	collapse_warning_time = 0.0
	flood_warned = false
	var positions: Array[float] = [rng.randf_range(16, 19)]
	if rng.randf() < .65: positions.append(rng.randf_range(31, 34))
	positions.append(rng.randf_range(82, 87))
	positions.append(rng.randf_range(108, 113))
	if rng.randf() < .65: positions.append(rng.randf_range(135, 138))
	for d in positions:
		var actor := Hunter.new()
		add_child(actor)
		var point: Vector3 = rail.world.curve.sample_baked(d)
		actor.position = point + Vector3(0, 0, -1.55)
		actor.look_at(point + Vector3(0, .1, 0))
		opportunities.append({"at": d, "actor": actor, "warned": false, "done": false, "exposure": 0.0, "warning_time": 0.0})

func tick(delta: float, progress: float) -> void:
	var data: Dictionary = rail.game.farm.rail.data
	for item in opportunities:
		var remaining: float = float(item.at) - progress
		if item.done: continue
		if remaining < -5:
			item.done = true
			continue
		if remaining < (23 if data.safety_switches[1] else 18) and remaining > -3:
			if not item.warned:
				item.warned = true
				rail.warn("[METAL SCRAPING] Release W — coast past the listening creature.", "scrape")
				rail.world.flicker_warning()
			item.warning_time += delta
			var close: float = rail.cart.position.distance_to(item.actor.position)
			if Hunter.hears_motor(close, rail.cart.accelerating, data.motor_upgraded): item.exposure += delta
			else: item.exposure = maxf(0.0, float(item.exposure) - delta * 2)
			if item.exposure > .9 and item.warning_time > 2.0:
				item.done = true
				item.actor.ambush(rail.cart.position + Vector3(0, .1, 0))
				rail.damage_cart(25, "ECHO HUNTER — the motor gave you away. Coast near scraping sounds.")
				if not rail.riding: return
	if collapse_active and not collapse_done:
		if progress > (2 if data.safety_switches[1] else 4) and progress < 14 and not collapse_warned:
			collapse_warned = true
			rail.warn("[SUPPORTS CREAKING] Brake before the broken roof. Pass below 2 m/s.", "creak")
			rail.world.flicker_warning()
		if collapse_warned: collapse_warning_time += delta
		if progress >= 14:
			collapse_done = true
			if collapse_warned:
				rail.world.falling_concrete(rail.world.curve.sample_baked(14))
				if collapse_warning_time >= 1.4 and rail.cart.speed > 2.0: rail.damage_cart(18, "FALLING CONCRETE — slow down under unstable supports.")
				if not rail.riding: return
	if progress > 19 and progress < 33 and not flood_warned:
		flood_warned = true
		rail.warn("[WATER AHEAD] Flooded track — reduced acceleration.", "water")
	if not figure_done and progress > 37 and progress < 41 and rail.cart.headlight_on and scares < 2:
		figure_done = true
		scares += 1
		var figure := Hunter.new()
		add_child(figure)
		figure.position = rail.world.curve.sample_baked(progress + 10)
		figure.look_at(rail.cart.position + Vector3(0, .1, 0))
		rail.warn("[A SHAPE IN THE HEADLIGHT]", "stinger")
		var tween := create_tween()
		tween.tween_interval(.5)
		tween.tween_callback(figure.queue_free)
	if not flood_scare_done and progress > 27 and progress < 30 and scares < 2:
		flood_scare_done = true
		if rng.randf() < .5:
			scares += 1
			rail.warn("[SPLASH BESIDE THE CART]", "water")
			rail.world.flicker_warning()
			rail.world.water_splash(rail.cart.position)

func clear() -> void:
	for item in opportunities:
		if is_instance_valid(item.actor): item.actor.queue_free()
	opportunities.clear()
