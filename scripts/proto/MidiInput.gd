extends Node3D

@export var lights: Dictionary = {}
@export var lights_group: Array[Array] = [[], [], [], [], [], [], []]

var selected_light: Lyre
var select_id = 0

const save_path = "res://configs/light_config.tres"

var snapshot: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.open_midi_inputs()
	print(OS.get_connected_midi_inputs())

func _process(delta):
	if Input.is_action_just_pressed("save_data"):
		save()
		
	if Input.is_action_just_pressed("load_data"):
		load_data()

func _input(input_event):
	if input_event is InputEventMIDI:
		_print_midi_info(input_event)
		handle_midi(input_event)

func _print_midi_info(midi_event):
	print(midi_event)
	print("Channel ", midi_event.channel)
	print("Message ", midi_event.message)
	print("Pitch ", midi_event.pitch)
	print("Velocity ", midi_event.velocity)
	print("Instrument ", midi_event.instrument)
	print("Pressure ", midi_event.pressure)
	print("Controller number: ", midi_event.controller_number)
	print("Controller value: ", midi_event.controller_value)
	
func save():
	var save_dict: SaveData = SaveData.new()
	
	for key in lights.keys():
		save_dict.lights[key] = get_path_to(lights[key])
	
	for key in lights.keys():
		save_dict.lights_param[key] = {}
		
		for prop in lights[key].editable_properties:
			save_dict.lights_param[key][prop.property] = lights[key][prop.property]
			
		if snapshot.has(key):
			save_dict.lights_param[key].power = snapshot[key]
	
	for group in lights_group:
		var arr = []
		for light in group:
			arr.push_back(light.index)
			
		save_dict.lights_group.push_back(arr)
	
	ResourceSaver.save(save_dict, save_path)

func load_data():
	var data = ResourceLoader.load(save_path)
		
	for key in data.lights_param.keys():
		var light = lights[int(key)]
		
		for prop in light.editable_properties:
			light[prop.property] = data.lights_param[key][prop.property]
	
	lights_group.resize(data.lights_group.size())
	
	for index in data.lights_group.size():
		for light_index in data.lights_group[index]:
			var light = get_saved_light(data.lights, light_index)
			lights_group[index].push_back(light)
	
	print(lights_group)
	
	#lights_group = data.lights_group as Array[Array]

func handle_midi(event: InputEventMIDI):	
	if event.controller_number == 46 && event.controller_value == 0:
		if selected_light == null:
			take_snapshot()
			select_lyre(select_id)
		else:
			unselect_light()
			restore_snapshot()
		
	if selected_light == null:
		if event.controller_number == 0:
			for key in lights.keys():
				lights[key].power = event.controller_value / 127.0 * 20.0
				
		if event.controller_number >= 1 && event.controller_number <= 7:
			for light in lights_group[event.controller_number - 1]:
				light.power = event.controller_value / 127.0 * 20.0	
			
	else:
		if event.controller_number >= 33 && event.controller_number <= 39:
			if lights_group[event.controller_number - 33].find(selected_light) == -1:
				lights_group[event.controller_number - 33].push_back(selected_light)
		
		if event.controller_number >= 49 && event.controller_number <= 55:
			lights_group[event.controller_number - 49].remove_at(lights_group[event.controller_number - 49].find(selected_light))
		
		if event.controller_number == 58 && event.controller_value == 0:
			var ordered_key = lights.keys()
			ordered_key.sort()
			
			var next_id_pos = ordered_key.find(select_id) - 1

			if next_id_pos < 0:
				next_id_pos = lights.keys().size() - 1
				
			select_id = ordered_key[next_id_pos]
			
			unselect_light()
			select_lyre(select_id)
			
		if event.controller_number == 59 && event.controller_value == 0:
			var ordered_key = lights.keys()
			ordered_key.sort()
			
			var next_id_pos = ordered_key.find(select_id) + 1
			
			if next_id_pos >= lights.keys().size():
				next_id_pos = 0
			
			select_id = ordered_key[next_id_pos]

			unselect_light()
			select_lyre(select_id)
			
		if event.controller_number == 16:
			selected_light.pan = event.controller_value / 127.0 * 360 - 180
			
		if event.controller_number == 17:
			selected_light.tilt = event.controller_value / 127.0 * 240 - 120
			
		if event.controller_number == 18:
			selected_light.angle = event.controller_value / 127.0 * 65 + 5
			
		if event.controller_number == 0:
			selected_light.power = event.controller_value / 127.0 * 20
			
		if event.controller_number == 1:
			var color = selected_light.color
			color.r = event.controller_value / 127.0
			selected_light.color = color
		
		if event.controller_number == 2:
			var color = selected_light.color
			color.g = event.controller_value / 127.0
			selected_light.color = color
			
		if event.controller_number == 3:
			var color = selected_light.color
			color.b = event.controller_value / 127.0
			selected_light.color = color
		
func select_lyre(index):
	selected_light = lights[index]
	selected_light.power = snapshot[index]

func unselect_light():
	snapshot[select_id] = selected_light.power
	selected_light.power = 0
	
	selected_light = null

func take_snapshot():
	for key in lights.keys():
		var light = lights[key]
		snapshot[key] = light.power
		
		light.power = 0
		
func restore_snapshot():
	for i in lights.keys():
		var light = lights[i]
		light.power = snapshot[i]

func get_saved_light(p_lights, index: int):
	return get_node(p_lights[index])
