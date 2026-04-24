extends PanelContainer
var focus = false
var id:int

signal charger_artiste

func _ready() -> void:
	# on connecte le signal charger_artiste à enumeration
	charger_artiste.connect(get_tree().get_first_node_in_group("enumeration")._artiste_clicked)

func _on_mouse_entered() -> void:
	focus = true
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.279, 0.279, 0.279)
	add_theme_stylebox_override("panel", stylebox)

func _on_mouse_exited() -> void:
	focus = false
	# on change la couleur du fond
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = Color(0.278, 0.278, 0.278, 0.0)
	add_theme_stylebox_override("panel", stylebox)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		charger_artiste.emit(id)
