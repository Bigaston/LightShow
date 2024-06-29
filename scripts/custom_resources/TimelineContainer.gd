extends Resource
class_name TimelineContainer

enum LoopMode {
	NoLoop, 
	Loop, 
	LoopWithSetup, 
	PingPong
}

@export var name: String
@export var timelines: Dictionary = {}
@export var loop_mode: LoopMode = LoopMode.NoLoop

var tweens: Dictionary = {}

func setup():
	for key in timelines.keys():
		var timeline = timelines[key] as Timeline
		var light = MidiInput.lights[key]
		var tween_time = 0.2
		
		if light is Rope:
			tween_time = 2
			
		var tween = MidiInput.get_tree().create_tween()
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

func play():
	# time -> timelines[]
	var parts_time: Dictionary = {}
	
	# Parcours toute les timelines pour récupérer tous les moments où il y a des changements
	for key in timelines.keys():
		var timeline = timelines[key] as Timeline
		
		var tween = MidiInput.get_tree().create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.pause()
		tweens[key] = tween
		
		for time in timeline.get_parts_time():
			if parts_time.has(time):
				parts_time[time].push_back(timeline)
			else:
				parts_time[time] = [timeline]
	
	# Trie des parties
	var part_keys = parts_time.keys()
	part_keys.sort_custom(func(a, b): return float(a) < float(b))
	
	# Pour chaque instant
	var dict_prev_time = {}
	for dict in timelines.values():
		dict_prev_time[dict] = 0
	
	for keyframe in part_keys:
		var timelines_to_adress = parts_time[keyframe]
		
		# Toutes les timelines où il y a besoin d'ajouter un truc
		for timeline in timelines_to_adress:
			var first = true
			
			var light = MidiInput.lights[timeline.light_index]
			var part = timeline.parts[keyframe]
			var tween = tweens[timeline.light_index]
			
			for prop in part.properties.keys():
				if first:
					first = false
					tween.tween_property(light, prop, part.properties[prop], part.time - dict_prev_time[timeline])
				else:
					tween.parallel().tween_property(light, prop, part.properties[prop], part.time - dict_prev_time[timeline])
			
			dict_prev_time[timeline] = float(keyframe)
			
	for timeline in timelines.values():
		if !timeline.parts.has(part_keys[part_keys.size() - 1]):
			tweens[timeline.light_index].tween_interval(float(part_keys[part_keys.size() - 1]) - dict_prev_time[timeline])
	
	match loop_mode:
		LoopMode.NoLoop:
			pass
		LoopMode.Loop:
			for key in timelines.keys():
				tweens[key].set_loops()
		LoopMode.LoopWithSetup:
			for key in timelines.keys():
				tweens[key].set_loops()
			
			if parts_time.has("0.00"):
				var has_rope = timelines.keys().map(func(key):
					return MidiInput.lights[key]).bsearch_custom("", func(l, _type): 
						return l is Rope)
				
				var interval_time = 2 if has_rope else 0.2
				
				for timeline in parts_time["0.00"]:
					var first = true
					
					var light = MidiInput.lights[timeline.light_index]
					var part = timeline.parts["0.00"]
					
					for prop in part.properties.keys():
						if first:
							first = false
							tweens[timeline.light_index].tween_property(light, prop, part.properties[prop], interval_time)
						else:
							tweens[timeline.light_index].parallel().tween_property(light, prop, part.properties[prop], interval_time)
		LoopMode.PingPong:
			for key in timelines.keys():
				tweens[key].set_loops()
			
			part_keys = parts_time.keys()
			part_keys.sort_custom(func(a, b): return float(a) > float(b))
			
			# Pour chaque instant
			dict_prev_time = {}
			for dict in timelines.values():
				dict_prev_time[dict] = float(part_keys[0])
			
			for keyframe in part_keys:
				var timelines_to_adress = parts_time[keyframe]
				
				# Toutes les timelines où il y a besoin d'ajouter un truc
				for timeline in timelines_to_adress:
					var first = true
					
					var light = MidiInput.lights[timeline.light_index]
					var part = timeline.parts[keyframe]
					
					for prop in part.properties.keys():
						if first:
							first = false
							tweens[timeline.light_index].tween_property(light, prop, part.properties[prop], dict_prev_time[timeline] - part.time)
						else:
							tweens[timeline.light_index].parallel().tween_property(light, prop, part.properties[prop], dict_prev_time[timeline] - part.time)

					dict_prev_time[timeline] = float(keyframe)
					
			for timeline in timelines.values():
				if !timeline.parts.has(part_keys[0]):
					tweens[timeline.light_index].tween_interval(dict_prev_time[timeline] - float(part_keys[0]))
	
	for key in timelines.keys():
		if timelines[key].await_duration != 0:
			var intermedial_tween = MidiInput.get_tree().create_tween()
			intermedial_tween.tween_interval(timelines[key].await_duration)
			intermedial_tween.tween_callback(tweens[key].play)
			
			intermedial_tween.play()
		else:
			tweens[key].play()

func pause():
	#tween.pause()
	pass
	
func stop():
	for key in timelines.keys():
		tweens[key].kill()
	
func is_playing() -> bool:
	if tweens.size() == 0:
		return false
		
	return tweens[timelines.keys()[0]].is_running()
	
func save_part(light_index: int, time: String):
	if !timelines.has(light_index):
		timelines[light_index] = Timeline.new()
		
	var timeline = timelines[light_index] as Timeline
	timeline.light_index = light_index
	
	timeline.save_part(light_index, time)
	
func goto_part(light_index: int, time: String):
	if !timelines.has(light_index):
		return
		
	var timeline = timelines[light_index] as Timeline
	
	timeline.goto_part(light_index, time)

func delete_part(light_index: int, time: String):
	if !timelines.has(light_index):
		return
				
	var timeline = timelines[light_index] as Timeline
			
	timeline.delete_part(light_index, time)
