extends Node3D

@export var lights: Dictionary = {}
@export var lights_group: Array[Array] = [[], [], [], [], [], [], []]
@export var timeline_step: float = 0.2

var selected_light: Lyre
var select_id = 0

const save_path = "res://configs/light_config.tres"

var snapshot: Dictionary = {}

var timelines: TimelineManager
var current_timelines: TimelineContainer
var current_time: float = 0.0

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
		
		if event.controller_number	== 32:
			if event.controller_value == 127:	
				for key in lights.keys():
					lights[key].power = 20
			else:
				for key in lights.keys():
					lights[key].power = 0
	
		if event.controller_number >= 33 && event.controller_number <= 39:
			if event.controller_value == 127:
				for light in lights_group[event.controller_number - 33]:
					light.power = 20
			else:
				for light in lights_group[event.controller_number - 33]:
					light.power = 0
					
		if event.controller_number == 41 && event.controller_value == 0:
			for key in current_timelines.timelines.keys():
				var timeline = current_timelines.timelines[key] as Timeline
				var light = lights[key]
				var prev_time = 0
				
				var tween = get_tree().create_tween()
				tween.set_trans(Tween.TRANS_CUBIC)
				
				var part_keys = timeline.parts.keys()
				part_keys.sort()
				
				for part_key in part_keys:
					var part = timeline.parts[part_key] as TimelinePart
					
					var first = true
					for prop in part.properties.keys():
						if first:
							first = false
							
							tween.tween_property(light, prop, part.properties[prop], part.time - prev_time)
						else:
							tween.parallel().tween_property(light, prop, part.properties[prop], part.time - prev_time)

					prev_time = part.time
			
				tween.play()
	else:
		if event.controller_number >= 33 && event.controller_number <= 39:
			if lights_group[event.controller_number - 33].find(selected_light) == -1:
				lights_group[event.controller_number - 33].push_back(selected_light)
		
		if event.controller_number >= 49 && event.controller_number <= 55:
			lights_group[event.controller_number - 49].remove_at(lights_group[event.controller_number - 49].find(selected_light))
		
		# Prev Light
		if event.controller_number == 58 && event.controller_value == 0:
			var ordered_key = lights.keys()
			ordered_key.sort()
			
			var next_id_pos = ordered_key.find(select_id) - 1

			if next_id_pos < 0:
				next_id_pos = lights.keys().size() - 1
				
			select_id = ordered_key[next_id_pos]
			
			unselect_light()
			select_lyre(select_id)
		
		# Next Light	
		if event.controller_number == 59 && event.controller_value == 0:
			var ordered_key = lights.keys()
			ordered_key.sort()
			
			var next_id_pos = ordered_key.find(select_id) + 1
			
			if next_id_pos >= lights.keys().size():
				next_id_pos = 0
			
			select_id = ordered_key[next_id_pos]

			unselect_light()
			select_lyre(select_id)
			
		# Timeline Register
		if event.controller_number == 60 && event.controller_value == 0:
			if !current_timelines.timelines.has(select_id):
				current_timelines.timelines[select_id] = Timeline.new()
				
			var timeline = current_timelines.timelines[select_id] as Timeline
			
			if !timeline.parts.has(current_time):
				timeline.parts[current_time] = TimelinePart.new()
				
			var part = timeline.parts[current_time] as TimelinePart
			part.time = current_time
			part.properties = {}
			
			for prop in selected_light.editable_properties:
				part.properties[prop.property] = selected_light[prop.property]
				
			update_part_display()
		
		# Timeline prev
		if event.controller_number == 61 && event.controller_value == 0:
			current_time -= timeline_step
			
			if current_time < 0:
				current_time = 0
				
			%CurrentTime.text = "%.02f" % current_time
			
		# Timeline next
		if event.controller_number == 62 && event.controller_value == 0:
			current_time += timeline_step
				
			%CurrentTime.text = "%.02f" % current_time
			
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
		
func save():
	var save_dict: SaveData = SaveData.new()
	
	save_dict.timeline_manager = timelines
	
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
			
	timelines = data.timeline_manager if data.timeline_manager != null else TimelineManager.new()
	update_current_timeline(0)
	
func select_lyre(index):
	selected_light = lights[index]
	selected_light.power = snapshot[index]
	
	update_part_display()

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

func update_part_display():
	if current_timelines.timelines.has(select_id):
		var string = ""
		
		var timeline = current_timelines.timelines[select_id] as Timeline
		var ordered_keys = timeline.parts.keys()
		ordered_keys.sort()
		
		for k in ordered_keys:
			string += ("%.02f" % k) + ","
			
		%Parts.text = string
	
	else:
		%Parts.text = "No parts..."
		
func update_current_timeline(index):
	if index < 0 or index >= timelines.containers.size():
		return
		
	current_timelines = timelines.containers[index]
	%CurrentTimeline.text = current_timelines.name
