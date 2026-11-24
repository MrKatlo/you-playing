class_name FarmPickup
extends StaticBody3D

const CHAIN_MODEL := preload("res://assets/models/basement/generated/props/replacement_chain_link.glb")

func configure(record: Dictionary) -> void:
	var item_id := int(record["id"])
	name = "DroppedChainLink_%d" % item_id
	set_meta("world_item_id", item_id)
	set_meta("kind", "chain_drop")
	set_meta("label", "CHAIN LINK")
	set_meta("requires_look", true)
	set_meta("aim_3d", true)
	set_meta("aim_dot", 0.87)
	set_meta("reach", 2.4)
	var coords: Array = record["position"]
	position = Vector3(float(coords[0]), float(coords[1]), float(coords[2]))
	# The small pickup can be targeted, but cannot obstruct walking or a doorway.
	collision_layer = 2
	collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.18, 0.06, 0.18)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)
	var visual := CHAIN_MODEL.instantiate() as Node3D
	visual.name = "ChainLinkModel"
	visual.rotation = Vector3(PI * 0.5, 0.25, 0.0)
	add_child(visual)
