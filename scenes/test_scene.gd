extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var down = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle_sunlight"):
		$DirectionalLight3D.visible = !$DirectionalLight3D.visible
		
	var tween: Tween
	
	if Input.is_action_just_pressed("start_anim"):
		if down:
			if tween && tween.is_running():
				tween.kill()
				
			tween = get_tree().create_tween()
			
			tween.set_parallel()
			tween.tween_property($Stuff/Ceilling/StructureTop/Rope, "length", 0.8, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop/Rope2, "length", 0.8, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop2/Rope3, "length", 0.8, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop2/Rope4, "length", 0.8, 5)
			
		else:
			if tween && tween.is_running():
				tween.kill()
				
			tween = get_tree().create_tween()
			
			tween.set_parallel()
			tween.tween_property($Stuff/Ceilling/StructureTop/Rope, "length", 6, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop/Rope2, "length", 6, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop2/Rope3, "length", 5, 5)
			tween.tween_property($Stuff/Ceilling/StructureTop2/Rope4, "length", 5, 5)
		
		down = !down
