extends Node3D

@export var camera: Camera3D

const RAY_LENGTH = 100

var selected_element: PlacableElement
var selected_element_preview: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT && !event.pressed && selected_element != null:
		var new_element = selected_element.placable_element.instantiate()
		new_element.position = selected_element_preview.position
		
		add_child(new_element)
		
		selected_element_preview.queue_free()
		selected_element_preview = null
		selected_element = null
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if selected_element != null:
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()

		var origin = camera.project_ray_origin(mousepos)
		var end = origin + camera.project_ray_normal(mousepos) * RAY_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end, 0b00000000_00000000_00000001_00000000)
		#query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		
		if !result.is_empty():
			var collider = result.collider
			selected_element_preview.position = result.position
			
func _on_placable_elements_placable_element_selected(element: PlacableElement) -> void:
	selected_element = element
	
	if selected_element_preview != null:
		selected_element_preview.queue_free()
		
	selected_element_preview = element.preview.instantiate()
	
	add_child(selected_element_preview)
