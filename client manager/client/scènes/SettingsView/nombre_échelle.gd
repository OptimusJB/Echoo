extends SpinBox

func _on_value_changed(valeur: float) -> void:
	if valeur < 0.25:
		value = 0.25
	get_window().content_scale_factor = value
	Settings.set_setting("echelle", get_window().content_scale_factor)
