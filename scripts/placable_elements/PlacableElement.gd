extends RigidBody3D
class_name PlacableElement

var editable_properties: Array[EditableProperty] = []

class EditableProperty:
	var name: String
	var property: String
	
	func _init(p_property: String, p_name: String = property):
		property = p_property
		name = p_name

func select():
	print(self, " selected")
	
func add_editable_property(property: String, name: String = property):
	editable_properties.push_back(EditableProperty.new(property, name))
	
func open_window(container: VBoxContainer):
	for child in container.get_children():
		child.queue_free()
	
	for property in editable_properties:
		var box = HBoxContainer.new()
		
		var label = Label.new()
		label.text = property.name
		box.add_child(label)
		
		match typeof(self[property.property]):
			TYPE_STRING:
				var textbox = LineEdit.new()
				textbox.text = self[property.property]
				
				box.push(textbox)
			TYPE_INT:
				var textbox = LineEdit.new()
				textbox.text = self[property.property]
				
				box.push(textbox)
				
		
		print(self[property.property])
		
		container.add_child(box)
		
