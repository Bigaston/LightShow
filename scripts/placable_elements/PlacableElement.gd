extends RigidBody3D
class_name PlacableElement

@export var index: int = 0

var editable_properties: Array[EditableProperty] = []

class EditableProperty:
	var name: String
	var property: String
	
	func _init(p_property: String, p_name: String = property):
		property = p_property
		name = p_name

func _ready():
	check_parent(self)
	
	MidiInput.lights[index] = self

func check_parent(node):
	var parent = node.get_parent()
	
	if parent is PlacableParent:
		index += parent.base_id
		return
	
	if parent != null:
		check_parent(parent)

func add_editable_property(property: String, name: String = property):
	editable_properties.push_back(EditableProperty.new(property, name))
	
func handle_midi(event: InputEventMIDI):
	pass
	
func select():
	MidiInput.selected_light = self
	MidiInput.update_part_display()
	
func unselect():
	MidiInput.selected_light = null
