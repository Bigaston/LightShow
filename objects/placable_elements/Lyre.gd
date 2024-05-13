@tool

extends PlacableElement

@export var color: Color: 
	set(value):
		color = value
		
		if light:
			light.light_color = color
			
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

@export_range(0, 20) var power: float = 0:
	set(value):
		power = value
		
		if light:
			light.light_energy = value

@export_subgroup("PrivateSettings")
@export var light: SpotLight3D
@export var pan_pivot: Node3D
@export var tilt_pivot: Node3D
