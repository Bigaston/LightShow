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

var tween: Tween

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
	tween = MidiInput.get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# time -> timelines[]
	var parts_time: Dictionary = {}
	
	# Parcours toute les timelines pour récupérer tous les moments où il y a des changements
	for key in timelines.keys():
		var timeline = timelines[key] as Timeline
		
		for time in timeline.get_parts_time():
			if parts_time.has(time):
				parts_time[time].push_back(timeline)				
			else:
				parts_time[time] = [timeline]
	
	# Trie des parties
	var part_keys = parts_time.keys()
	part_keys.sort_custom(func(a, b): return float(a) < float(b))
	
	# Pour chaque instant
	var prev_time = 0	
	
	for keyframe in part_keys:
		var first = true
		
		var timelines_to_adress = parts_time[keyframe]
		
		# Toutes les timelines où il y a besoin d'ajouter un truc
		for timeline in timelines_to_adress:
			var light = MidiInput.lights[timeline.light_index]
			var part = timeline.parts[keyframe]
			
			for prop in part.properties.keys():
				if first:
					first = false
					tween.tween_property(light, prop, part.properties[prop], part.time - prev_time)
				else:
					tween.parallel().tween_property(light, prop, part.properties[prop], part.time - prev_time)

		prev_time = float(keyframe)
	
	match loop_mode:
		LoopMode.NoLoop:
			pass
		LoopMode.Loop:
			tween.set_loops()
		LoopMode.LoopWithSetup:
			tween.set_loops()
			
			if parts_time.has("0.00"):
				var first = true
				var has_rope = timelines.keys().map(func(key):
					return MidiInput.lights[key]).bsearch_custom("", func(l, _type): 
						return l is Rope)
				
				var interval_time = 2 if has_rope else 0.2
				
				for timeline in parts_time["0.00"]:
					var light = MidiInput.lights[timeline.light_index]
					var part = timeline.parts["0.00"]
					
					for prop in part.properties.keys():
						if first:
							first = false
							tween.tween_property(light, prop, part.properties[prop], interval_time)
						else:
							tween.parallel().tween_property(light, prop, part.properties[prop], interval_time)
		LoopMode.PingPong:
			tween.set_loops()
			
			part_keys = parts_time.keys()
			part_keys.sort_custom(func(a, b): return float(a) > float(b))
			
			# Pour chaque instant
			prev_time = float(part_keys[0])
			
			for keyframe in part_keys:
				var first = true
				
				var timelines_to_adress = parts_time[keyframe]
				
				# Toutes les timelines où il y a besoin d'ajouter un truc
				for timeline in timelines_to_adress:
					var light = MidiInput.lights[timeline.light_index]
					var part = timeline.parts[keyframe]
					
					for prop in part.properties.keys():
						if first:
							first = false
							tween.tween_property(light, prop, part.properties[prop], prev_time - part.time)
						else:
							tween.parallel().tween_property(light, prop, part.properties[prop], prev_time - part.time)

				prev_time = float(keyframe)
	
	tween.play()

func pause():
	#tween.pause()
	pass
	
func stop():
	tween.kill()
	
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
