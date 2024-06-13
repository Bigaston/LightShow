extends PlacableElement
class_name Lyre

enum Shape {None, Star, TreeLeaves}

@export var color: Color = Color.WHITE: 
	set(value):
		color = value
		
		if light:
			light.light_color = color
			light_render.albedo_color = color
			light_render.emission = color
			
@export_range(-180,180) var pan: float = 0:
	set(value):
		pan = value
		
		if pan_pivot:
			pan_pivot.rotation_degrees.y = value
			
@export_range(-120, 120) var tilt: float = 0:
	set(value):
		tilt = value
		
		if tilt_pivot:
			tilt_pivot.rotation_degrees.z = value

@export_range(0, 20) var power: float = 10:
	set(value):
		power = value
		
		if light:
			light.light_energy = value
			
@export_range(5, 70) var angle: float = 20:
	set(value):
		angle = value
		
		if light:
			light.spot_angle = angle
	
@export_category("Projector")
@export var shape: Shape = Shape.None:
	set(value):
		shape = value
		
		if light:
			match shape:
				Shape.None:
					light.light_projector = null
				Shape.Star:
					light.light_projector = preload("res://resources/textures/projector/star.svg")
				Shape.TreeLeaves:
					light.light_projector = preload("res://resources/textures/projector/tree.png")

@export_range(-180, 180) var projector_angle: float = 0:
	set(value):
		projector_angle = value
		
		if light:
			light.rotation_degrees.y = projector_angle

@export_subgroup("PrivateSettings")
@onready var light: SpotLight3D = $Node/Pan2/Tilt2/SpotLight
@onready var pan_pivot: Node3D = $Node/Pan2
@onready var tilt_pivot: Node3D = $Node/Pan2/Tilt2

var light_render: StandardMaterial3D = StandardMaterial3D.new()
var select_snapshot = power

func _ready():
	super._ready()
	
	add_editable_property("color")
	add_editable_property("pan")
	add_editable_property("tilt")
	add_editable_property("power")
	add_editable_property("angle")
	add_editable_property("shape")
	
	light_render.emission_enabled = true
	light_render.emission = Color.WHITE
	
	$Node/Pan2/Tilt2/Light.set_surface_override_material(0, light_render)
	
	match shape:
		Shape.None:
			light.light_projector = null
		Shape.Star:
			light.light_projector = preload("res://resources/textures/projector/star.svg")
		Shape.TreeLeaves:
			light.light_projector = preload("res://resources/textures/projector/tree.png")

func select():
	super.select()
	
	power = select_snapshot
	
func unselect():
	super.unselect()
	
	select_snapshot = power
	power = 0

func handle_midi(event: InputEventMIDI):
	if event.controller_number == 16:
		pan = event.controller_value / 127.0 * 360 - 180
		
	if event.controller_number == 17:
		tilt = event.controller_value / 127.0 * 240 - 120
		
	if event.controller_number == 18:
		angle = event.controller_value / 127.0 * 65 + 5
		
	if event.controller_number == 0:
		power = event.controller_value / 127.0 * 20
		
	if event.controller_number == 1:
		var new_color = color
		new_color.r = event.controller_value / 127.0
		color = new_color
	
	if event.controller_number == 2:
		var new_color = color
		new_color.g = event.controller_value / 127.0
		color = new_color
		
	if event.controller_number == 3:
		var new_color = color
		new_color.b = event.controller_value / 127.0
		color = new_color
