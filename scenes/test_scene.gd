extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("toggle_sunlight"):
		$DirectionalLight3D.visible = !$DirectionalLight3D.visible


func _on_animation_player_2_animation_finished(anim_name):
	match anim_name:
		"Boot":
			$AnimationPlayer2.play("Hello")
