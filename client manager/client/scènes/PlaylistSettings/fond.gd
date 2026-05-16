extends ColorRect
var can_remove = true	# pour éviter les modifications pendant que ça envoi

signal decharger_settings

func _gui_input(event: InputEvent) -> void:
	if can_remove and event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		decharger_settings.emit()
