extends PanelContainer

var id_playlist:int
var image_playlist:String

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# on affiche les options
		get_tree().get_first_node_in_group("playlist settings").charger_settings(id_playlist, image_playlist, $"éléments/marges/textes/nom".text, $"éléments/marges/textes/description".text, $"éléments/masque/image".texture.duplicate())
