extends ColorRect
signal decharger_settings

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		decharger_settings.emit()
