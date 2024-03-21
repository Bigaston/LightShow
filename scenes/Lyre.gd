@tool
extends Node3D

@export var light_color: Color: 
	get:
		return light_color
		
	set(value):
		if $SpotLight3D:
			($SpotLight3D as SpotLight3D).light_color = value
		light_color = value
