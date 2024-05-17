@tool

extends Node3D

@export var color: Color = Color.WHITE: 
	set(value):
		color = value
		
		for light in lights:
			if light:
				light.light_color = color

			light_render.albedo_color = color
			light_render.emission = color
			
@export_range(0, 20) var power: float = 0:
	set(value):
		power = value
		
		for light in lights:
			if light:
				light.light_energy = value
			
@export_range(10, 70) var angle: float = 20:
	set(value):
		angle = value
		
		for light in lights:
			if light:
				light.spot_angle = angle

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

@export_subgroup("PrivateSettings")
@export var lights: Array[SpotLight3D]
@export var pan_pivot: Node3D
@export var tilt_pivot: Node3D
@export var light_render: StandardMaterial3D
