extends RigidBody3D
class_name PlacableElement

@export var index: int = 0

var editable_properties: Array[EditableProperty] = []

var p_name = "PlacableElement"
var selected = false

class EditableProperty:
	var name: String
	var property: String
	var imgui_func: Callable
	
	func _init(p_property: String, p_name: String = property, p_imgui_func = null):
		property = p_property
		name = p_name

		if p_imgui_func == null:
			imgui_func = func(value):
				ImGui.Text(name + " " + str(value))
		else:
			imgui_func = p_imgui_func

func _ready():
	check_parent(self)
	
	MidiInput.lights[index] = self
	
func _process(delta):
	if selected:
		ImGui.Begin("Selected Element")
		ImGui.Text("Name: " + p_name + " " + str(index))
		
		for prop in editable_properties:
			prop.imgui_func.call(self[prop.property])
			
		if ImGui.Button("Copy"):
			var str = JSON.stringify({
				app = "LightShow.PlacableElement.Properties",
				name = p_name,
				props = editable_properties.map(func (prop): 
					var val
					
					match typeof(self[prop.property]):
						TYPE_COLOR:
							val = self[prop.property].to_html()
						_:
							val = self[prop.property]
					
					return {
						name = prop.property,
						type = typeof(self[prop.property]),
						value = val
					})
			})
			
			DisplayServer.clipboard_set(str)
		ImGui.SameLine()
		
		if ImGui.Button("Past"):
			var str = DisplayServer.clipboard_get()
			var obj = JSON.parse_string(str)
			
			print(obj)
			
			if obj.app == null || obj.app != "LightShow.PlacableElement.Properties":
				printerr("Bad Copy Paste!")
			else:
				for prop in obj.props:
					if prop.name in self:
						match prop.type:
							TYPE_COLOR:
								self[prop.name] = Color.html(prop.value)
							_:
								self[prop.name] = prop.value
			
		ImGui.End()

func check_parent(node):
	var parent = node.get_parent()
	
	if parent is PlacableParent:
		index += parent.base_id
		parent.childrens.push_back(self)
		return
	
	if parent != null:
		check_parent(parent)

func add_editable_property(property: String, name: String = property, imgui_func = null):
	editable_properties.push_back(EditableProperty.new(property, name, imgui_func))
	
func handle_midi(event: InputEventMIDI):
	pass
	
func select():
	selected = true
	MidiInput.selected_light = self
	
func unselect():
	selected = false
	MidiInput.selected_light = null
