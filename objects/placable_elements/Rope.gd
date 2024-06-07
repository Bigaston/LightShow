extends Node3D

const ROPE_LENGHT = 0.28

@export var length: float = 0:
	set(value):
		if value < 0:
			value = 0
			
		length = value
		
		update_length()
		
@export var other_body: PhysicsBody3D:
	set(value):
		other_body = value
		
func _ready():
	update_length()
	
	$Joint.node_b = other_body.get_path()

func update_length():
	if $Container == null:
		return
	
	var number_of_rope = floor(length / ROPE_LENGHT)
	
	for n in $Container.get_children():
		$Container.remove_child(n)
		n.queue_free()
	
	$Final.position = Vector3(0, length, 0)
	$Joint.position = Vector3(0, length, 0)
	
	for i in range(number_of_rope):
		var elem = preload("res://resources/meshs/Rope.glb").instantiate()
		elem.position = Vector3(0, length - (ROPE_LENGHT * (i + 1)), 0)
		
		$Container.add_child(elem)
