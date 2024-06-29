extends Resource
class_name TimelineContainer

@export var name: String
@export var timelines: Dictionary = {}

var tween: Tween

func setup():
	for key in timelines.keys():
		var timeline = timelines[key] as Timeline
		var light = MidiInput.lights[key]
		var tween_time = 0.2
		
		if light is Rope:
			tween_time = 2
			
		tween = MidiInput.get_tree().create_tween()
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
	for key in timelines.keys():
		var timeline = timelines[key] as Timeline
		var light = MidiInput.lights[key]
		var prev_time = 0
		
		tween = MidiInput.get_tree().create_tween()
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

func pause():
	tween.pause()
	
func stop():
	tween.stop()
	
func save_part(light_index: int, time: String):
	if !timelines.has(light_index):
		timelines[light_index] = Timeline.new()
		
	var timeline = timelines[light_index] as Timeline
	
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
