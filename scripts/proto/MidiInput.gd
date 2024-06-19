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

func _process(delta):
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
		
		if event.controller_number == 42 && event.controller_value == 0:
			for key in current_timelines.timelines.keys():
				var timeline = current_timelines.timelines[key] as Timeline
				var light = lights[key]
				var prev_time = 0
				
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
							
							tween.tween_property(light, prop, part.properties[prop], 0.2)
						else:
							tween.parallel().tween_property(light, prop, part.properties[prop], 0.2)
					
					tween.play()
					
		if event.controller_number == 41 && event.controller_value == 0:
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
			if !current_timelines.timelines.has(select_id):
				current_timelines.timelines[select_id] = Timeline.new()
				
			var timeline = current_timelines.timelines[select_id] as Timeline
			
			if !timeline.parts.has(ctime()):
				timeline.parts[ctime()] = TimelinePart.new()
				
			var part = timeline.parts[ctime()] as TimelinePart
			part.time = ctime()
			part.properties = {}
			
			for prop in selected_light.editable_properties:
				part.properties[prop.property] = selected_light[prop.property]
				
			update_part_display()
		
		if event.controller_number == 42 && event.controller_value == 0:
			if !current_timelines.timelines.has(select_id):
				return
				
			var timeline = current_timelines.timelines[select_id] as Timeline
			
			if !timeline.parts.has(ctime()):
				return
				
			timeline.parts.erase(ctime())
			update_part_display()
			
		if event.controller_number == 45 && event.controller_value == 0:
			if !current_timelines.timelines.has(select_id):
				return
				
			var timeline = current_timelines.timelines[select_id] as Timeline
			
			if !timeline.parts.has(ctime()):
				return
				
			var part = timeline.parts[ctime()] as TimelinePart			
				
			for prop in part.properties.keys():
				selected_light[prop] = part.properties[prop]
				
			update_part_display()
		
		# Timeline prev
		if event.controller_number == 61 && event.controller_value == 0:
			current_time -= timeline_step
			
			if current_time < 0:
				current_time = 0
				
			$UI/CurrentTime.text = "%.02f" % current_time
			
		# Timeline next
		if event.controller_number == 62 && event.controller_value == 0:
			current_time += timeline_step
				
			$UI/CurrentTime.text = "%.02f" % current_time
			
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

func update_part_display():
	if current_timelines.timelines.has(select_id):
		var string = ""
		
		var timeline = current_timelines.timelines[select_id] as Timeline
		var ordered_keys = timeline.parts.keys()
		ordered_keys.sort_custom(func(a, b): return float(a) < float(b))
		
		for k in ordered_keys:
			string += k + ","
			
		$UI/Parts.text = string
	
	else:
		pass
		$UI/Parts.text = "No parts..."
		
func update_current_timeline(index):
	if index < 0 or index >= timelines.containers.size():
		return
		
	current_timelines = timelines.containers[index]
	$UI/CurrentTimeline.text = current_timelines.name
	
	current_timeline_index = index

func ctime():
	return "%.02f" % current_time
