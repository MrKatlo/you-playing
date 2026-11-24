class_name PocketAudio
extends Node

# The pocket's own sound, synthesised at load the way BasementAudio does it: no
# sample assets, and every bed is tied to a place on the route.
#
#   draft  cold air drawn down the approach corridor. Positional at the bend, so
#          it is present in the corridor, thinner in the gallery and gone in the
#          chamber — the walk out has a sound that fades behind you.
#   drip   water off the ceiling, one-shots from four scattered sources. The gaps
#          are long and irregular, so the room has a clock of its own.
#   note   the drop's tone: two pairs of low partials a hair apart, beating
#          against each other. It is the only pitched thing out there, so the
#          chamber says "you have arrived" before the clamp is visible.

const RATE := 22050
const DRAFT_DB := -30.0
const NOTE_DB := -24.0
const DRIP_DB := -18.0
const DUCK_DB := -24.0

var draft_stream: AudioStreamWAV
var drip_stream: AudioStreamWAV
var note_stream: AudioStreamWAV

var draft_player: AudioStreamPlayer3D
var note_player: AudioStreamPlayer3D
var drip_players: Array[AudioStreamPlayer3D] = []

var drip_wait := 2.4
var drip_serial := 0
var muted := false

func _ready() -> void:
	# Ducking has to keep working while the pause menu holds the tree.
	process_mode = Node.PROCESS_MODE_ALWAYS
	draft_stream = _build_draft_loop()
	drip_stream = _build_drip()
	note_stream = _build_note_loop()

## Called once the pocket is built. `drip_points` are ceiling positions; the
## sources are positional so a drip tells the player which room it fell in.
func place(draft_at: Vector3, note_at: Vector3, drip_points: Array) -> void:
	draft_player = _make_player(draft_stream, DRAFT_DB, 9.0, 34.0)
	draft_player.name = "PocketDraft"
	draft_player.position = draft_at
	draft_player.play()
	note_player = _make_player(note_stream, NOTE_DB, 5.0, 36.0)
	note_player.name = "PocketDropNote"
	note_player.position = note_at
	note_player.play()
	for index in drip_points.size():
		var player := _make_player(drip_stream, DRIP_DB, 3.5, 28.0)
		player.name = "PocketDrip%d" % index
		player.position = drip_points[index]
		drip_players.append(player)

func set_muted(value: bool) -> void:
	muted = value

func play_drip(index: int = -1) -> void:
	if drip_players.is_empty():
		return
	var slot := index
	if slot < 0:
		slot = randi() % drip_players.size()
	slot = clampi(slot, 0, drip_players.size() - 1)
	var player := drip_players[slot]
	if player == null:
		return
	player.volume_db = DRIP_DB + _duck()
	player.pitch_scale = randf_range(0.86, 1.14)
	player.play()
	drip_serial += 1

func _process(delta: float) -> void:
	if draft_player != null:
		draft_player.volume_db = DRAFT_DB + _duck()
	if note_player != null:
		note_player.volume_db = NOTE_DB + _duck()
	if drip_players.is_empty():
		return
	drip_wait -= delta
	if drip_wait <= 0.0:
		# Long, uneven gaps. Two drips close together read as a leak; the spacing
		# is what makes the gallery feel big.
		drip_wait = randf_range(3.4, 9.6)
		play_drip()

func _duck() -> float:
	return DUCK_DB if (muted or get_tree().paused) else 0.0

func _make_player(stream: AudioStream, volume_db: float, unit_size: float, max_distance: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.unit_size = unit_size
	player.max_distance = max_distance
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(player)
	return player

# ---------------------------------------------------------------- beds

func _build_draft_loop() -> AudioStreamWAV:
	# Six seconds of draft. The gust partials complete whole cycles in the window
	# and the tail is folded over the head, so the loop has no seam.
	var frames := int(RATE * 6.0)
	var fade := int(RATE * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(frames + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 44711
	var low := 0.0
	var mid := 0.0
	for index in samples.size():
		var time := float(index) / float(RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		low += (noise - low) * 0.012
		mid += (noise - mid) * 0.085
		var gust := 0.50 + 0.30 * sin(TAU * (1.0 / 6.0) * time) + 0.20 * sin(TAU * 0.5 * time + 1.3)
		gust = clampf(gust, 0.0, 1.0)
		var body := low * 1.7 + mid * 0.62
		# A thin edge tone where the air crosses the corridor mouth.
		var whistle := sin(TAU * 468.0 * time + sin(TAU * (5.0 / 6.0) * time) * 1.4) * pow(gust, 4.0) * 0.055
		samples[index] = body * gust * 0.46 + whistle
	return _seal(samples, frames, fade, true)

func _build_note_loop() -> AudioStreamWAV:
	# Five seconds of the drop's tone. Both partial pairs are detuned by 0.2 Hz,
	# which completes exactly one beat per loop: it swells and settles rather than
	# sitting still. Every partial ends on a whole cycle.
	var frames := int(RATE * 5.0)
	var fade := int(RATE * 0.40)
	var samples := PackedFloat32Array()
	samples.resize(frames + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61307
	for index in samples.size():
		var time := float(index) / float(RATE)
		var root := sin(TAU * 92.6 * time) * 0.30 + sin(TAU * 92.8 * time) * 0.30
		var fifth := sin(TAU * 138.8 * time) * 0.20 + sin(TAU * 139.0 * time) * 0.20
		var shimmer := sin(TAU * 277.4 * time) * (0.60 + 0.40 * sin(TAU * 0.4 * time)) * 0.045
		var air := rng.randf_range(-1.0, 1.0) * 0.006
		samples[index] = root + fifth + shimmer + air
	return _seal(samples, frames, fade, true)

# ---------------------------------------------------------------- one-shots

func _build_drip() -> AudioStreamWAV:
	# A water plink: a rising bloop, the ceiling grit that let go with it, and two
	# room reflections so it reads as distance rather than a click near the ear.
	var frames := int(RATE * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 22093
	var phase := 0.0
	for index in frames:
		var time := float(index) / float(RATE)
		# Pitch climbs as the droplet necks and snaps, then falls away.
		var freq := 680.0 + 900.0 * (1.0 - exp(-time * 42.0))
		if time > 0.16:
			freq = maxf(430.0, freq - (time - 0.16) * 2600.0)
		phase += TAU * freq / float(RATE)
		var plink := sin(phase) * exp(-time * 15.0) * 0.52
		var grit := rng.randf_range(-1.0, 1.0) * exp(-time * 140.0) * 0.28
		var body := sin(TAU * 236.0 * time) * exp(-time * 24.0) * 0.16
		var early := 0.0
		if time > 0.11:
			early = sin(TAU * 705.0 * (time - 0.11)) * exp(-(time - 0.11) * 26.0) * 0.12
		var late := 0.0
		if time > 0.23:
			late = sin(TAU * 640.0 * (time - 0.23)) * exp(-(time - 0.23) * 19.0) * 0.07
		samples[index] = plink + grit + body + early + late
	return _to_wav(samples, false)

# ---------------------------------------------------------------- encoding

func _seal(samples: PackedFloat32Array, frames: int, fade: int, loop: bool) -> AudioStreamWAV:
	# Fold the tail generated past `frames` back over the head, so the loop point
	# is continuous instead of a click once per cycle.
	var sealed := PackedFloat32Array()
	sealed.resize(frames)
	for index in frames:
		var value := samples[index]
		if index < fade and frames + index < samples.size():
			var weight := float(index) / float(fade)
			value = value * weight + samples[frames + index] * (1.0 - weight)
		sealed[index] = value
	return _to_wav(sealed, loop)

func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var peak := 0.0001
	for index in samples.size():
		peak = maxf(peak, absf(samples[index]))
	var gain := 0.9 / peak if peak > 0.9 else 1.0
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	var tail := int(RATE * 0.03)
	for index in samples.size():
		var value := samples[index]
		if not loop and tail > 0:
			# Never let a one-shot end on a non-zero sample and click.
			var remaining := samples.size() - 1 - index
			if remaining < tail:
				value *= float(remaining) / float(tail)
		data.encode_s16(index * 2, int(clampf(value * gain, -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
