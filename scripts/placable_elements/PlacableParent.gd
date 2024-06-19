extends Node3D
class_name PlacableParent

var childrens = []

@export var base_id = 0
@export var group_name = ""

func _ready():
	MidiInput.placable_parents.push_back(self)
