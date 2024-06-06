extends Node3D

@export var lights: Array[Lyre] = []

var selected_light: Lyre
var select_index = 0

var snapshot: Array[float] = [lights.size()]

# Called when the node enters the scene tree for the first time.
func _ready():
	OS.open_midi_inputs()
	print(OS.get_connected_midi_inputs())
	snapshot.resize(lights.size())

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
			select_lyre(select_index)
		else:
			unselect_light()
			restore_snapshot()
		
	if selected_light == null:
		if event.controller_number == 0:
			for light in lights:
				print(light)
				light.power = event.controller_value / 127.0 * 20.0
				
		if event.controller_number >= 1 && event.controller_number <= 4:
			lights[event.controller_number - 1].power = event.controller_value / 127.0 * 20.0	
			
	else:
		if event.controller_number == 58 && event.controller_value == 0:
			select_index -= 1
			if select_index < 0:
				select_index = lights.size() - 1
				
			unselect_light()
			select_lyre(select_index)
			
		if event.controller_number == 59 && event.controller_value == 0:
			select_index += 1
			if select_index >= lights.size():
				select_index = 0
				
			unselect_light()
			select_lyre(select_index)
			
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
	snapshot[select_index] = selected_light.power
	selected_light.power = 0
	
	selected_light = null

func take_snapshot():
	for i in range(lights.size()):
		var light = lights[i]
		snapshot[i] = light.power
		
		light.power = 0
		
func restore_snapshot():
	for i in range(lights.size()):
		var light = lights[i]
		light.power = snapshot[i]
