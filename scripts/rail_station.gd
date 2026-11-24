extends RefCounted

var id := "corridor"
var distance := 2.0
var half_length := 4.0
var exit_position := Vector3(28, 0.05, -4.8)

func contains(progress: float, loop_length: float) -> bool:
	var gap := absf(progress - distance)
	return minf(gap, loop_length - gap) <= half_length

func can_exit(cart) -> bool:
	return cart.speed == 0.0 and contains(cart.distance, cart.curve.get_baked_length())
