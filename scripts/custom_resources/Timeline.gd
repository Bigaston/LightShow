extends Resource
class_name Timeline

@export var light_index: int
@export var parts: Dictionary

func save_part(light_index: int, time: String):
	if !parts.has(time):
		parts[time] = TimelinePart.new()
		
	var part = parts[time] as TimelinePart
	part.time = time
	part.properties = {}
	
	for prop in MidiInput.lights[light_index].editable_properties:
		part.properties[prop.property] = MidiInput.lights[light_index][prop.property]

func goto_part(light_index: int, time: String):
	if !parts.has(time):
		return
		
	var part = parts[time] as TimelinePart
		
	for prop in part.properties.keys():
		MidiInput.lights[light_index][prop] = part.properties[prop]

func delete_part(_light_index: int, time: String):
	if !parts.has(time):
		return
		
	parts.erase(time)
