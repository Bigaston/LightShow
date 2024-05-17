@tool

extends Node3D

var struct_2 = preload("res://resources/meshs/Struct_2.glb")
var struct_3 = preload("res://resources/meshs/Struct_3.glb")
var struct_4 = preload("res://resources/meshs/Struct_4.glb")
const SIZE = 0.6

@export_range(2, 4, 1) var number_of_border = 2:
	set(value):
		number_of_border = value
		update_display()
		
@export var lenght: int = 1:
	set(value):
		if value < 1:
			value = 1
			
		lenght = value
		update_display()

func _ready():
	update_display()

func update_display():
	if $Container == null:
		return
		
	var obj: PackedScene
	
	match number_of_border:
		2:
			obj = struct_2
		3:
			obj = struct_3
		4:
			obj = struct_4

	for n in $Container.get_children():
		$Container.remove_child(n)
		n.queue_free()

	var last_elem: Node3D

	for i in range(lenght):
		var elem = obj.instantiate()
		
		if last_elem:
			elem.position = last_elem.position + Vector3(0, SIZE, 0)
		
		print(elem)
		
		$Container.add_child(elem)
		
		last_elem = elem
