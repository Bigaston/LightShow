extends Resource
class_name Timeline

@export var light_index: int
@export var parts: Dictionary
@export var await_duration: float = 0

func save_part(light_index: int, time: String):
	if !parts.has(time):
		parts[time] = TimelinePart.new()
		
	var part = parts[time] as TimelinePart
	part.time = time
	part.properties = {}
	
	for prop in MidiInput.lights[light_index].editable_properties:
		if prop.should_timeline:
			part.properties[prop.property] = MidiInput.lights[light_index][prop.property]

func goto_part(light_index: int, time: String):
	if !parts.has(time):
		return
		
	var part = parts[time] as TimelinePart
		
	for prop in MidiInput.lights[light_index].editable_properties:
		prop.should_timeline = part.properties.keys().has(prop.property)
		
	for prop in part.properties.keys():
		MidiInput.lights[light_index][prop] = part.properties[prop]
		

func delete_part(_light_index: int, time: String):
	if !parts.has(time):
		return
		
	parts.erase(time)

func get_parts_time():
	return parts.keys()
