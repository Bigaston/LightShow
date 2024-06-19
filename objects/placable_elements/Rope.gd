extends PlacableElement
class_name Rope

const ROPE_LENGHT = 0.28

const MAX_SPEED = 1

var direction = 0

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
	super._ready()
	
	p_name = "Rope"
	
	update_length()
	
	add_editable_property("length", "Length", func(value):
		var array = [value]
		if ImGui.InputFloat("Light Angle", array):
			if array[0] > 0:
				length = array[0]
	)
	
	$Joint.node_b = other_body.get_path()

func _process(delta):
	super._process(delta)
	
	if selected:
		length += direction * delta
		
		if length < 0.5:
			length = 0.5

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

func select():
	super.select()
	
	$Light.visible = true
	
func unselect():
	super.unselect()
	
	$Light.visible = false

func handle_midi(event: InputEventMIDI):
	if event.controller_number == 16:
		var value = event.controller_value - 63
		
		if abs(value) < 5:
			direction = 0
		else:
			direction = value / 64.0 * MAX_SPEED
