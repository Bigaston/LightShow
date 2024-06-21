extends Node3D

@export var lights: Dictionary = {}
@export var placable_parents: Array[PlacableParent] = []
@export var lights_group: Array[Array] = [[], [], [], [], [], [], []]
@export var timeline_step: float = 0.2

var selected_light: PlacableElement
var select_id = null

const save_path = "res://configs/light_config3.tres"

var timelines: TimelineManager = TimelineManager.new()
var current_timelines: TimelineContainer = TimelineContainer.new()
var current_timeline_index = 0
var current_time: float = 0.0

@export var debug_mini = false

func _ready():
	OS.open_midi_inputs()
	
	var ui = preload("res://objects/ui.tscn").instantiate()
	add_child(ui)

func _process(_delta):
	#ImGui.ShowDemoWindow()
	ImGui.Begin("Lights & More")
	
	if selected_light == null:
		if ImGui.Button("Edit mode"):
			if select_id == null:
				select_id = int(lights.keys()[0])
			
			lights[select_id].select()
	else:
		if ImGui.Button("Play mode"):
			selected_light.unselect()
	
	if ImGui.CollapsingHeader("Lights"):
		for parent in placable_parents:
			if ImGui.TreeNode(parent.group_name):
				for child in parent.childrens:
					if selected_light == null:
						ImGui.Text(child.p_name + " " + str(child.index))
					else:
						if ImGui.Button(child.p_name + " " + str(child.index)):
							selected_light.unselect()
							select_id = child.index
							child.select()
					
				ImGui.TreePop()

	ImGui.End()
	
	display_timeline_window()
	
	if Input.is_action_just_pressed("save_data"):
		save()
		
	if Input.is_action_just_pressed("load_data"):
		load_data()
		
	if Input.is_action_just_pressed("new_timeline"):
		var tl = TimelineContainer.new()
		tl.name = "Timeline %s" % timelines.containers.size()
		timelines.containers.push_back(tl)
		
		update_current_timeline(timelines.containers.size() - 1)
		
	if Input.is_action_just_pressed("debug_midi"):
		debug_mini = !debug_mini

func _input(input_event):
	if input_event is InputEventMIDI:
		if debug_mini:
			_print_midi_info(input_event)
		handle_midi(input_event)

func _print_midi_info(midi_event):
	print(midi_event)
	print("Controller number: ", midi_event.controller_number)
	print("Controller value: ", midi_event.controller_value)

func handle_midi(event: InputEventMIDI):	
	if event.controller_number == 46 && event.controller_value == 0:
		if selected_light == null:
			if select_id == null:
				select_id = int(lights.keys()[0])
			
			lights[select_id].select()
		else:
			selected_light.unselect()
		
	if event.controller_number == 43 && event.controller_value == 0:
		current_timeline_index -= 1
		
		if current_timeline_index < 0:
			current_timeline_index = timelines.containers.size() - 1
			
		update_current_timeline(current_timeline_index)
		
	if event.controller_number == 44 && event.controller_value == 0:
		current_timeline_index += 1
		
		if current_timeline_index >= timelines.containers.size():
			current_timeline_index = 0
			
		update_current_timeline(current_timeline_index)
		
	if selected_light == null:
		if event.controller_number == 0:
			#if Input.is_key_pressed(KEY_F):
				#%WorldEnvironment.environment.volumetric_fog_density = event.controller_value / 127.0 * 1
				#
			#elif Input.is_key_pressed(KEY_L):
				#%DirectionalLight.light_energy = event.controller_value / 127.0 * 2
				#
			#else:
			for key in lights.keys():
				if "power" in lights[key]:
					lights[key].power = event.controller_value / 127.0 * 20.0
				
		if event.controller_number >= 1 && event.controller_number <= 7:
			for light in lights_group[event.controller_number - 1]:
				light.power = event.controller_value / 127.0 * 20.0
		
		if event.controller_number	== 32:
			if event.controller_value == 127:	
				for key in lights.keys():
					if "power" in lights[key]:
						lights[key].power = 20
			else:
				for key in lights.keys():
					if "power" in lights[key]:
						lights[key].power = 0
	
		if event.controller_number >= 33 && event.controller_number <= 39:
			if event.controller_value == 127:
				for light in lights_group[event.controller_number - 33]:
					light.power = 20
			else:
				for light in lights_group[event.controller_number - 33]:
					light.power = 0
		
		if event.controller_number == 42 && event.controller_value == 0:
			launch_timeline()
					
		if event.controller_number == 41 && event.controller_value == 0:
			setup_timeline()
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
			
			selected_light.unselect()
			lights[select_id].select()
		
		# Next Light	
		if event.controller_number == 59 && event.controller_value == 0:
			var ordered_key = lights.keys()
			ordered_key.sort()
			
			var next_id_pos = ordered_key.find(select_id) + 1
			
			if next_id_pos >= lights.keys().size():
				next_id_pos = 0
			
			select_id = ordered_key[next_id_pos]

			selected_light.unselect()
			lights[select_id].select()
			
		# Timeline Register
		if event.controller_number == 60 && event.controller_value == 0:
			register_timeline_part(select_id, ctime())
				
		if event.controller_number == 42 && event.controller_value == 0:
			erease_timeline_at_pos(select_id, ctime())
			
		if event.controller_number == 45 && event.controller_value == 0:
			goto_timeline_part(select_id, ctime())
		
		# Timeline prev
		if event.controller_number == 61 && event.controller_value == 0:
			current_time -= timeline_step
			
			if current_time < 0:
				current_time = 0
			
		# Timeline next
		if event.controller_number == 62 && event.controller_value == 0:
			current_time += timeline_step
			
		selected_light.handle_midi(event)
		
func save():
	var save_dict: SaveData = SaveData.new()
	
	save_dict.timeline_manager = timelines
	
	for key in lights.keys():
		save_dict.lights[key] = get_path_to(lights[key])
	
	for key in lights.keys():
		save_dict.lights_param[key] = {}
		
		for prop in lights[key].editable_properties:
			save_dict.lights_param[key][prop.property] = lights[key][prop.property]
	
	for group in lights_group:
		var arr = []
		for light in group:
			arr.push_back(light.index)
			
		save_dict.lights_group.push_back(arr)
		
	#save_dict.fog_power = %WorldEnvironment.environment.volumetric_fog_density
	#save_dict.dir_light_power = %DirectionalLight.light_energy
	
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
	
	#%WorldEnvironment.environment.volumetric_fog_density = data.fog_power
	#%DirectionalLight.light_energy = data.dir_light_power

func get_saved_light(p_lights, index: int):
	return get_node(p_lights[index])
		
func update_current_timeline(index):
	if index < 0 or index >= timelines.containers.size():
		return
		
	current_timelines = timelines.containers[index]
	
	current_timeline_index = index

func ctime():
	return "%.02f" % current_time

func setup_timeline():
	for key in current_timelines.timelines.keys():
		var timeline = current_timelines.timelines[key] as Timeline
		var light = lights[key]
		var tween_time = 0.2
		
		if light is Rope:
			tween_time = 2
		
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		
		var part_keys = timeline.parts.keys()
		part_keys.sort_custom(func(a, b): return float(a) < float(b))
		
		if timeline.parts.has("0.00"):
			var part = timeline.parts["0.00"] as TimelinePart
			var first = true
			
			for prop in part.properties.keys():
				if first:
					first = false
					
					tween.tween_property(light, prop, part.properties[prop], tween_time)
				else:
					tween.parallel().tween_property(light, prop, part.properties[prop], tween_time)
			
			tween.play()

func launch_timeline():
	for key in current_timelines.timelines.keys():
		var timeline = current_timelines.timelines[key] as Timeline
		var light = lights[key]
		var prev_time = 0
		
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		
		var part_keys = timeline.parts.keys()
		part_keys.sort_custom(func(a, b): return float(a) < float(b))
		
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
		
func erease_timeline_at_pos(id: int, time: String):
	if !current_timelines.timelines.has(id):
		return
				
	var timeline = current_timelines.timelines[id] as Timeline
			
	if !timeline.parts.has(time):
		return
		
	timeline.parts.erase(time)

func register_timeline_part(id: int, time: String):
	if !current_timelines.timelines.has(id):
		current_timelines.timelines[id] = Timeline.new()
		
	var timeline = current_timelines.timelines[id] as Timeline
	
	if !timeline.parts.has(time):
		timeline.parts[time] = TimelinePart.new()
		
	var part = timeline.parts[time] as TimelinePart
	part.time = time
	part.properties = {}
	
	for prop in lights[id].editable_properties:
		part.properties[prop.property] = lights[id][prop.property]

func goto_timeline_part(id: int, time: String):
	if !current_timelines.timelines.has(id):
		return
		
	var timeline = current_timelines.timelines[id] as Timeline
	
	if !timeline.parts.has(time):
		return
		
	var part = timeline.parts[time] as TimelinePart
		
	for prop in part.properties.keys():
		lights[id][prop] = part.properties[prop]

func display_timeline_window():
	ImGui.Begin("Timeline")
	
	var current_timeline = [current_timelines.name]
	if ImGui.Combo("Current Timeline", current_timeline, timelines.containers.map(func(timeline): return timeline.name)):
		current_timelines = timelines.containers[timelines.containers.bsearch_custom(current_timeline[0], func(a, b): return a == b)]
	
	if selected_light == null:
		if ImGui.Button("Setup"):
			setup_timeline()
		
		ImGui.SameLine()
		
		if ImGui.Button("Play"):
			launch_timeline()
	else:
		var arr = [current_time]
		if ImGui.InputFloat("Current Time", arr):
			if arr[0] > 0:
				current_time = arr[0]
				
		if current_timelines.timelines.has(select_id):
			var timeline = current_timelines.timelines[select_id] as Timeline
			var ordered_keys = timeline.parts.keys()
			ordered_keys.sort_custom(func(a, b): return float(a) < float(b))
			
			for k in ordered_keys:
				if ImGui.Button(k):
					goto_timeline_part(select_id, k)
				ImGui.SameLine()
			
			ImGui.NewLine()
		else:
			ImGui.Text("No part...")
		
		if ImGui.Button("Set part"):
			register_timeline_part(select_id, ctime())
		
		ImGui.SameLine()
		
		if ImGui.Button("Delete Part"):
			erease_timeline_at_pos(select_id, ctime())
		
	ImGui.End()
