extends VBoxContainer

@export var elements: PlacableElementContainer

signal placable_element_selected(element: PlacableElementResource)

func _ready() -> void:
	for element in elements.elements:
		var btn = Button.new()
		btn.text = element.name
		
		btn.pressed.connect(on_btn_click.bind(element))
		
		add_child(btn)

func on_btn_click(element: PlacableElementResource):
	placable_element_selected.emit(element)
