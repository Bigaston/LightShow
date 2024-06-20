extends PlacableElement
class_name SmallSpot

@export var color: Color = Color.WHITE: 
	set(value):
		color = value
		
		if light:
			var new_color = Color(value.r * (power/20), value.g * (power/20), value.b * (power/20))
			
			light.light_color = new_color
			light_render.albedo_color = new_color
			light_render.emission = new_color
			
@export_range(-180,180) var pan: float = 0:
	set(value):
		pan = value
		
		if pan_pivot:
			pan_pivot.rotation_degrees.y = value
			
@export_range(-180, 180) var tilt: float = 0:
	set(value):
		tilt = value
		
		if tilt_pivot:
			tilt_pivot.rotation_degrees.z = value - 90

@export_range(0, 20) var power: float = 10:
	set(value):
		power = value
		
		if light:
			light.light_energy = value
			
			var new_color = Color(color.r * (value/20), color.g * (value/20), color.b * (value/20))
			
			light.light_color = new_color
			light_render.albedo_color = new_color
			light_render.emission = new_color
			
@export_range(5, 70) var angle: float = 20:
	set(value):
		angle = value
		
		if light:
			light.spot_angle = angle

@onready var light: SpotLight3D = $blockbench_export/Node/Pan2/Tilt/SpotLight3D
@onready var pan_pivot: Node3D = $blockbench_export/Node/Pan2
@onready var tilt_pivot: Node3D = $blockbench_export/Node/Pan2/Tilt

var light_render: StandardMaterial3D = StandardMaterial3D.new()
var select_snapshot = power

func _ready():
	super._ready()
	
	p_name = "SmallSpot"
	
	add_editable_property("color", "Color", func(value):
		var col_array = [value.r, value.g, value.b]
		
		if ImGui.ColorEdit3("Color", col_array):
			color.r = col_array[0]
			color.g = col_array[1]
			color.b = col_array[2]
	)
	
	add_editable_property("pan", "Pan", func(value):
		var array = [value]
		if ImGui.SliderInt("Pan", array, -180, 180):
			pan = array[0]
	)
	
	add_editable_property("tilt", "Tilt", func(value):
		var array = [value]
		if ImGui.SliderInt("Tilt", array, -180, 180):
			tilt = array[0]
	)
	
	add_editable_property("power", "Power", func(value):
		var array = [value]
		if ImGui.SliderInt("Power", array, 0, 20):
			power = array[0]
	)
	
	add_editable_property("angle", "Angle", func(value):
		var array = [value]
		if ImGui.SliderInt("Light Angle", array, 5, 70):
			angle = array[0]
	)
	
	light_render.emission_enabled = true
	light_render.emission = Color.WHITE
	
	$blockbench_export/Node/Pan2/Tilt/Light.set_surface_override_material(0, light_render)

func _process(delta):
	super._process(delta)

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
		tilt = event.controller_value / 127.0 * 360 - 180
		
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
