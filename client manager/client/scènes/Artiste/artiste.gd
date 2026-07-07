extends PanelContainer
var focus = false
var id:int

signal charger_artiste

func _ready() -> void:
	# on connecte le signal charger_artiste à enumeration
	charger_artiste.connect(get_tree().get_first_node_in_group("enumeration")._artiste_clicked)

#func _on_gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		#charger_artiste.emit(id)

func _on_charger_artiste_pressed() -> void:
	charger_artiste.emit(id)
